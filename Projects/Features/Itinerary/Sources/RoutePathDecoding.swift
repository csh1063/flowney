import CoreLocation
import GoogleMaps
import Models

enum RoutePathDecoding {
    static func isTransitVehicleMode(_ mode: TransportMode) -> Bool {
        switch mode {
        case .tram, .metro, .train, .bus, .gondola, .funicular, .boat, .cograil: return true
        case .walk, .car, .start: return false
        }
    }

    static func usesSteppedRendering(leg: RouteLeg, hasRealRoute: Bool) -> Bool {
        hasRealRoute && isTransitVehicleMode(leg.mode) && !leg.steps.isEmpty
    }

    static func singlePolylinePoints(
        leg: RouteLeg?,
        hasRealRoute: Bool,
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        if let polylineString = leg?.polyline, hasRealRoute,
           let path = GMSPath(fromEncodedPath: polylineString), path.count() > 0 {
            return decode(path)
        }
        return [from, to]
    }

    static func decode(_ path: GMSPath) -> [CLLocationCoordinate2D] {
        var points: [CLLocationCoordinate2D] = []
        for i in 0 ..< path.count() {
            points.append(path.coordinate(at: i))
        }
        return points
    }
}
