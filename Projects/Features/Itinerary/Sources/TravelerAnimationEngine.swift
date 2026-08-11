import CoreLocation
import GoogleMaps
import Models
import UIKit

/// travel_map.html의 `animateLeg`/`animateSegment` 로직을 그대로 이식.
/// TCA 액션 디스패치로 매 프레임을 흘리면 불필요한 diffing이 생기므로,
/// 이 엔진은 Store 바깥에서 CADisplayLink로 직접 지도 마커를 갱신한다.
@MainActor
final class TravelerAnimationEngine {
    private struct Segment {
        let points: [CLLocationCoordinate2D]
        let cumulativeLengths: [Double]
        let totalLength: Double
        let durationMs: Double
        let mode: TransportMode
    }

    private weak var mapView: GMSMapView?
    private let travelerMarker: GMSMarker

    private var displayLink: CADisplayLink?
    private var startTimestamp: CFTimeInterval = 0
    private var activeSegment: Segment?
    private var segments: [Segment] = []
    private var segmentIndex = 0
    private var currentIconMode: TransportMode?
    private var onCompleted: (() -> Void)?
    /// leg 전체 기준 누적 진행률(0→1)을 프레임마다 알려준다 — RouteMapView가 이걸로 지나온
    /// 구간의 경로선을 채색한다. 세그먼트(step)별 progress가 아니라 leg 전체 길이 대비 진행률.
    private var onProgress: ((Double) -> Void)?
    private var generation = 0
    /// segments[i]가 시작되는 시점의 leg 전체 대비 누적 진행률 — step마다 나뉜 leg에서
    /// "지금 세그먼트 안에서의 fraction"을 "leg 전체 fraction"으로 환산하는 데 쓴다.
    private var segmentBaseFraction: [Double] = []
    private var totalPathLength: Double = 1

    init(mapView: GMSMapView) {
        self.mapView = mapView
        let marker = GMSMarker()
        marker.zIndex = 100
        // 기본 groundAnchor(0.5, 1.0)는 핀처럼 뾰족한 아이콘 기준이라, 이모지 라벨을 쓰면
        // 실제 좌표가 아이콘 아래쪽 끝이 아니라 위쪽에 붙어서 선에서 한참 떠 보인다 —
        // 이모지 정중앙이 좌표에 오도록 (0.5, 0.5)로 맞춘다.
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        self.travelerMarker = marker
    }

    func stop() {
        generation += 1
        displayLink?.invalidate()
        displayLink = nil
        onCompleted = nil
        onProgress = nil
    }

    func animate(
        leg: RouteLeg,
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        bottomInset: CGFloat,
        onProgress: ((Double) -> Void)? = nil,
        onCompleted: @escaping () -> Void
    ) {
        stop()
        let myGen = generation
        self.onCompleted = onCompleted
        self.onProgress = onProgress

        segments = Self.buildSegments(leg: leg, from: from, to: to)
        totalPathLength = max(segments.reduce(0) { $0 + $1.totalLength }, 1e-9)
        var cumulative = 0.0
        segmentBaseFraction = segments.map { segment in
            let base = cumulative / totalPathLength
            cumulative += segment.totalLength
            return base
        }
        segmentIndex = 0
        currentIconMode = nil

        let firstPoint = segments.first?.points.first ?? from
        travelerMarker.position = firstPoint
        travelerMarker.map = mapView

        if let mapView {
            var bounds = GMSCoordinateBounds(coordinate: from, coordinate: to)
            for segment in segments {
                for point in segment.points {
                    bounds = bounds.includingCoordinate(point)
                }
            }
            // 하단 리스트 패널에 가려지지 않도록, 그 높이만큼 아래쪽 inset을 더 준다 — 리스트가
            // 크게 펼쳐져 있을 때(3.5줄)와 작게 접혀 있을 때(1.5줄)에 따라 지도가 실제로 보이는
            // 영역의 중심이 달라진다.
            let edgeInsets = UIEdgeInsets(top: 64, left: 64, bottom: 64 + bottomInset, right: 64)
            mapView.animate(with: GMSCameraUpdate.fit(bounds, with: edgeInsets))
        }

        runNextSegment(generation: myGen)
    }

    // html의 `for(const seg of orderedSegs){ await animateSegment(...); if(hasTransfer) await pause(300); }`를
    // 콜백 기반으로 이식 — 환승 구간마다 0.3초씩 멈췄다가 다음 구간(다른 이동수단 아이콘)으로 이어간다.
    private func runNextSegment(generation myGen: Int) {
        guard myGen == generation else { return }
        guard segmentIndex < segments.count else {
            onProgress?(1.0)
            let completion = onCompleted
            onCompleted = nil
            completion?()
            return
        }

        let segment = segments[segmentIndex]
        if currentIconMode != segment.mode {
            currentIconMode = segment.mode
            travelerMarker.iconView = Self.makeTravelerIconView(mode: segment.mode)
        }

        activeSegment = segment
        startTimestamp = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(step))
        link.add(to: .main, forMode: .common)
        displayLink = link

        segmentCompletion = { [weak self] in
            guard let self, myGen == self.generation else { return }
            let finishedMode = self.segments[self.segmentIndex].mode
            self.segmentIndex += 1
            let hasMoreSegments = self.segmentIndex < self.segments.count
            // 도보 경로도 구글이 턴바이턴으로 step을 잘게 쪼개서 내려주기 때문에, "segment가
            // 여러 개"라는 것만으로 매번 0.3초씩 멈추면 순수 도보 구간에서도 골목 모퉁이마다
            // 끊겨 보이고 총 애니메이션 시간도 쓸데없이 늘어난다 — 실제로 이동수단이 바뀌는
            // 진짜 환승 지점(예: 도보→지하철)에서만 멈춘다.
            let isRealTransfer = hasMoreSegments && self.segments[self.segmentIndex].mode != finishedMode
            if isRealTransfer {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.runNextSegment(generation: myGen)
                }
            } else {
                self.runNextSegment(generation: myGen)
            }
        }
    }

    private var segmentCompletion: (() -> Void)?

    @objc private func step() {
        guard let segment = activeSegment else { return }
        let elapsed = CACurrentMediaTime() - startTimestamp
        let fraction = min(elapsed / (segment.durationMs / 1000.0), 1.0)
        travelerMarker.position = Self.pointAtFraction(
            points: segment.points,
            cumulativeLengths: segment.cumulativeLengths,
            totalLength: segment.totalLength,
            fraction: fraction
        )

        let segmentWeight = segment.totalLength / totalPathLength
        let overallFraction = segmentBaseFraction[segmentIndex] + segmentWeight * fraction
        onProgress?(min(overallFraction, 1.0))

        if fraction >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
            let completion = segmentCompletion
            segmentCompletion = nil
            completion?()
        }
    }

    // MARK: - 구간(세그먼트) 구성

    /// `leg.steps`가 있으면(환승 있는 대중교통) 각 스텝을 별도 세그먼트로 나눠서, 전체
    /// 애니메이션 시간(mode별 baseAnimationDurationMs)을 각 세그먼트의 실제 거리 비율만큼
    /// 나눠 갖는다. steps가 없으면(직선이거나 환승 없는 도보/차량) 통째로 한 세그먼트.
    private static func buildSegments(leg: RouteLeg, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> [Segment] {
        let totalDurationMs = leg.mode.baseAnimationDurationMs

        guard !leg.steps.isEmpty else {
            let points = decodePoints(leg: leg, from: from, to: to)
            return [makeSegment(points: points, durationMs: totalDurationMs, mode: leg.mode)]
        }

        let stepPoints: [[CLLocationCoordinate2D]] = leg.steps.map { step in
            guard let path = GMSPath(fromEncodedPath: step.polyline), path.count() > 0 else { return [] }
            var points: [CLLocationCoordinate2D] = []
            for i in 0 ..< path.count() {
                points.append(path.coordinate(at: i))
            }
            return points
        }
        let stepLengths = stepPoints.map(pathLength)
        let totalLength = max(stepLengths.reduce(0, +), 1e-9)

        return zip(leg.steps, zip(stepPoints, stepLengths)).compactMap { step, pointsAndLength in
            let (points, length) = pointsAndLength
            guard points.count > 1 else { return nil }
            let mode = mapVehicleToMode(travelMode: step.travelMode, vehicleType: step.vehicleType)
            let durationMs = max(150, totalDurationMs * (length / totalLength))
            return makeSegment(points: points, durationMs: durationMs, mode: mode)
        }
    }

    private static func makeSegment(points: [CLLocationCoordinate2D], durationMs: Double, mode: TransportMode) -> Segment {
        var cumulativeLengths = [0.0]
        for i in 1 ..< max(points.count, 1) where i < points.count {
            cumulativeLengths.append(cumulativeLengths[i - 1] + pseudoDistance(points[i - 1], points[i]))
        }
        return Segment(
            points: points,
            cumulativeLengths: cumulativeLengths,
            totalLength: max(cumulativeLengths.last ?? 0, 1e-9),
            durationMs: durationMs,
            mode: mode
        )
    }

    private static func pathLength(_ points: [CLLocationCoordinate2D]) -> Double {
        guard points.count > 1 else { return 0 }
        var total = 0.0
        for i in 1 ..< points.count {
            total += pseudoDistance(points[i - 1], points[i])
        }
        return total
    }

    private static func pointAtFraction(
        points: [CLLocationCoordinate2D],
        cumulativeLengths: [Double],
        totalLength: Double,
        fraction: Double
    ) -> CLLocationCoordinate2D {
        guard points.count > 1 else { return points.first ?? CLLocationCoordinate2D() }
        let target = totalLength * fraction
        var i = 1
        while i < cumulativeLengths.count, cumulativeLengths[i] < target {
            i += 1
        }
        i = min(i, points.count - 1)
        let segStart = cumulativeLengths[i - 1]
        let segEnd = cumulativeLengths[i]
        let segT = segEnd > segStart ? (target - segStart) / (segEnd - segStart) : 0
        let a = points[i - 1]
        let b = points[i]
        return CLLocationCoordinate2D(
            latitude: a.latitude + (b.latitude - a.latitude) * segT,
            longitude: a.longitude + (b.longitude - a.longitude) * segT
        )
    }

    private static func pseudoDistance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let dLat = b.latitude - a.latitude
        let dLng = b.longitude - a.longitude
        return (dLat * dLat + dLng * dLng).squareRoot()
    }

    private static func decodePoints(
        leg: RouteLeg,
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        if let polylineString = leg.polyline, let path = GMSPath(fromEncodedPath: polylineString), path.count() > 0 {
            var result: [CLLocationCoordinate2D] = []
            for i in 0 ..< path.count() {
                result.append(path.coordinate(at: i))
            }
            return result
        }
        return [from, to]
    }

    /// html의 `mapGoogleVehicleToIcon` 이식 — 구글 라우팅 API의 travelMode/vehicleType 문자열을
    /// 우리 TransportMode로 매핑한다.
    private static func mapVehicleToMode(travelMode: String, vehicleType: String?) -> TransportMode {
        if travelMode == "WALKING" { return .walk }
        switch vehicleType {
        case "SUBWAY", "METRO_RAIL": return .metro
        case "TRAM", "LIGHT_RAIL": return .tram
        case "BUS", "INTERCITY_BUS", "TROLLEYBUS", "SHARE_TAXI": return .bus
        case "HEAVY_RAIL", "RAIL", "COMMUTER_TRAIN", "HIGH_SPEED_TRAIN", "LONG_DISTANCE_TRAIN": return .train
        case "FUNICULAR": return .funicular
        case "GONDOLA_LIFT", "CABLE_CAR": return .gondola
        case "FERRY": return .boat
        default: return .train
        }
    }

    private static func makeTravelerIconView(mode: TransportMode) -> UIView {
        let label = UILabel()
        label.text = emoji(for: mode)
        label.font = .systemFont(ofSize: 24)
        label.sizeToFit()
        return label
    }

    private static func emoji(for mode: TransportMode) -> String {
        switch mode {
        case .start: return "🚩"
        case .walk: return "🚶"
        case .tram: return "🚊"
        case .metro: return "🚇"
        case .train: return "🚆"
        case .bus: return "🚌"
        case .gondola, .funicular: return "🚡"
        case .car: return "🚗"
        case .boat: return "⛴️"
        }
    }
}
