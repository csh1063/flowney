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
    /// html의 `google.maps.event.addListenerOnce(map,'idle',...)`과 동일 — 카메라가 이번
    /// leg 범위로 fit하는 애니메이션이 끝날 때까지 마커 이동 시작을 미룬다. 카메라랑 마커가
    /// 동시에 움직이면 카메라가 자리잡는 동안 마커가 화면상 선을 벗어나 보이기 때문.
    private var pendingCameraIdle: (() -> Void)?
    private var cameraIdleTimeoutWorkItem: DispatchWorkItem?

    init(mapView: GMSMapView) {
        self.mapView = mapView
        let marker = GMSMarker()
        marker.zIndex = 100
        // html 원본(AdvancedMarkerElement)은 anchor를 따로 안 건드려서 기본값인 정중앙하단
        // (0.5, 1.0)을 그대로 쓴다 — 걷는 사람 아이콘은 "발이 선 위"에 있어야 자연스럽고,
        // 이게 실제로 html에서 자연스러워 보였던 이유였다. 예전에 "이모지는 핀처럼 안
        // 뾰족하니까"라며 중앙(0.5, 0.5)으로 바꿨던 건 오히려 html과 다른 선택이었고,
        // 방향이 꺾이는 구간에서 아이콘 몸통이 선을 벗어난 것처럼 보이는 원인이 됐다.
        marker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
        self.travelerMarker = marker
    }

    func stop() {
        generation += 1
        displayLink?.invalidate()
        displayLink = nil
        onCompleted = nil
        onProgress = nil
        cameraIdleTimeoutWorkItem?.cancel()
        cameraIdleTimeoutWorkItem = nil
        pendingCameraIdle = nil
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

        guard let mapView else {
            runNextSegment(generation: myGen)
            return
        }

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

        // 카메라 fit 애니메이션이 끝날 때까지 마커 이동을 미룬다(html과 동일). idle 콜백은
        // `RouteMapView.Coordinator.mapView(_:idleAt:)`가 `cameraDidBecomeIdle()`을 호출해서
        // 전달해준다 — 혹시 idle이 안 뜨는 경우(범위가 그대로라 카메라가 실제로 안 움직이는
        // 등)를 대비해 1초 타임아웃으로도 그냥 진행한다.
        pendingCameraIdle = { [weak self] in
            guard let self, myGen == self.generation else { return }
            self.cameraIdleTimeoutWorkItem?.cancel()
            self.cameraIdleTimeoutWorkItem = nil
            self.pendingCameraIdle = nil
            self.runNextSegment(generation: myGen)
        }
        let timeoutItem = DispatchWorkItem { [weak self] in
            guard let self, myGen == self.generation else { return }
            self.pendingCameraIdle?()
        }
        cameraIdleTimeoutWorkItem = timeoutItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: timeoutItem)

        mapView.animate(with: GMSCameraUpdate.fit(bounds, with: edgeInsets))
    }

    /// `RouteMapView.Coordinator`가 `GMSMapViewDelegate.mapView(_:idleAt:)`에서 호출한다 —
    /// 방금 요청한 카메라 fit이 끝나면 대기 중이던 마커 이동을 시작한다. 대기 중인 게 없으면
    /// (마커 이동과 무관한 일반 카메라 idle이면) 아무 일도 안 한다.
    func cameraDidBecomeIdle() {
        pendingCameraIdle?()
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
        // GMSMarker.position은 내부적으로 CALayer 기반이라 기본적으로 암묵적 애니메이션이
        // 걸린다 — 매 프레임(1/60초) 새 좌표를 줘도 SDK가 그 각각을 자기 나름대로 부드럽게
        // 보간해서 그리다 보니, 실제로 꺾이는 지점들이 뭉개져서 캐릭터가 진짜 경로와 다른
        // (더 뭉툭한) 모양으로 움직이는 것처럼 보였다. 웹 버전(AdvancedMarkerElement, 그냥
        // DOM 엘리먼트라 CSS transition 없인 즉시 이동)엔 없는 문제. CATransaction으로
        // 암묵적 애니메이션을 꺼서 매 프레임 계산한 좌표가 그 즉시 그대로 찍히게 한다.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        travelerMarker.position = Self.pointAtFraction(
            points: segment.points,
            cumulativeLengths: segment.cumulativeLengths,
            totalLength: segment.totalLength,
            fraction: fraction
        )
        CATransaction.commit()

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

    /// `RouteMapView.redraw()`가 실제로 그리는 것과 정확히 같은 조건/같은 좌표로 세그먼트를
    /// 만든다 — 대중교통 계열이고 steps가 있으면(환승 있는 대중교통) 각 스텝을 별도
    /// 세그먼트로 나눠서 전체 애니메이션 시간을 세그먼트의 실제 거리 비율만큼 나눠 갖고,
    /// 그 외(도보/자동차/직선 fallback 등)는 통째로 한 세그먼트. 예전엔 이 조건이
    /// `RoutePathDecoding`과 달라서(steps 유무만 봄) 도보/자동차 leg에서 그려지는 선과
    /// 캐릭터가 따라가는 좌표가 서로 어긋났었다.
    private static func buildSegments(leg: RouteLeg, from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> [Segment] {
        let totalDurationMs = leg.mode.baseAnimationDurationMs
        let hasRealRoute = leg.status == .ok

        if RoutePathDecoding.usesSteppedRendering(leg: leg, hasRealRoute: hasRealRoute) {
            let stepPoints: [[CLLocationCoordinate2D]] = leg.steps.map { step in
                guard let path = GMSPath(fromEncodedPath: step.polyline), path.count() > 0 else { return [] }
                return RoutePathDecoding.decode(path)
            }
            let stepLengths = stepPoints.map(pathLength)
            let totalLength = max(stepLengths.reduce(0, +), 1e-9)

            let segments = zip(leg.steps, zip(stepPoints, stepLengths)).compactMap { step, pointsAndLength -> Segment? in
                let (points, length) = pointsAndLength
                guard points.count > 1 else { return nil }
                let mode = mapVehicleToMode(travelMode: step.travelMode, vehicleType: step.vehicleType)
                let durationMs = max(150, totalDurationMs * (length / totalLength))
                return makeSegment(points: points, durationMs: durationMs, mode: mode)
            }
            if !segments.isEmpty { return segments }
        }

        let points = RoutePathDecoding.singlePolylinePoints(leg: leg, hasRealRoute: hasRealRoute, from: from, to: to)
        return [makeSegment(points: points, durationMs: totalDurationMs, mode: leg.mode)]
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

    // 경도 1도의 실제 거리는 위도에 따라 cos(위도)만큼 짧아진다(적도에서 멀어질수록 자오선이
    // 좁아짐) — 이 앱이 다루는 위도대(네덜란드~스위스, 북위 46~52도)에서는 대략 0.67~0.70배라
    // 무시할 수 없는 오차다. 이걸 안 보정하고 위경도 차이를 그냥 피타고라스로 더하면, 남북/동서
    // 방향이 섞인 굽은 길에서 구간별 "실제 비율"이 어긋나서 캐릭터가 커브를 실제보다 빨리
    // 통과하거나(지름길처럼 보임) 늦게 통과하는 것처럼 보인다 — 경도 차이에 cos(위도)를 곱해서
    // 실제 거리 비율에 훨씬 가깝게 보정한다(정밀한 haversine까지는 필요 없고, 세그먼트 간
    // 상대 비율만 맞으면 됨).
    private static func pseudoDistance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let dLat = b.latitude - a.latitude
        let midLatRadians = (a.latitude + b.latitude) / 2 * .pi / 180
        let dLng = (b.longitude - a.longitude) * cos(midLatRadians)
        return (dLat * dLat + dLng * dLng).squareRoot()
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
        case .cograil: return "🚞"
        }
    }
}
