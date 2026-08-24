import CoreLocation
import GoogleMaps
import Models
import UIKit

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
    private var onProgress: ((Double) -> Void)?
    private var generation = 0
    private var segmentBaseFraction: [Double] = []
    private var totalPathLength: Double = 1
    private var pendingCameraIdle: (() -> Void)?
    private var cameraIdleTimeoutWorkItem: DispatchWorkItem?

    init(mapView: GMSMapView) {
        self.mapView = mapView
        let marker = GMSMarker()
        marker.zIndex = 100
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
        let edgeInsets = UIEdgeInsets(top: 64, left: 64, bottom: 64, right: 64)

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

    func cameraDidBecomeIdle() {
        pendingCameraIdle?()
    }

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

    private static func pseudoDistance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let dLat = b.latitude - a.latitude
        let midLatRadians = (a.latitude + b.latitude) / 2 * .pi / 180
        let dLng = (b.longitude - a.longitude) * cos(midLatRadians)
        return (dLat * dLat + dLng * dLng).squareRoot()
    }

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
