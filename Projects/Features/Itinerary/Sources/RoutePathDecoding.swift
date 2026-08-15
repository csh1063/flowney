import CoreLocation
import GoogleMaps
import Models

/// leg 하나가 실제로 지나는 좌표들 — 지도에 그리는 선(`RouteMapView`)과 이동 애니메이션
/// (`TravelerAnimationEngine`)이 반드시 이 함수들로만 좌표를 얻어야 한다.
///
/// 전에는 그리기와 애니메이션이 서로 다른 조건으로 좌표를 각자 디코드했다 — 그리기는
/// "대중교통 계열 + steps 있음"일 때만 step별 상세 폴리라인을 쓰고 그 외(도보/자동차 포함)엔
/// leg.polyline(overview)만 썼는데, 애니메이션은 모드와 무관하게 "steps가 있으면" 무조건
/// step별 폴리라인을 썼다. 구글은 도보/자동차 경로에도 steps를 내려주기 때문에, 도보/자동차
/// leg에서 그려지는 선(overview)과 캐릭터가 따라가는 경로(steps)가 서로 다른 좌표였다 —
/// 캐릭터가 선을 벗어나 지름길로 가는 것처럼 보이던 원인. 이제 둘 다 같은 조건/같은 좌표를
/// 쓰도록 통일한다.
enum RoutePathDecoding {
    static func isTransitVehicleMode(_ mode: TransportMode) -> Bool {
        switch mode {
        case .tram, .metro, .train, .bus, .gondola, .funicular, .boat, .cograil: return true
        case .walk, .car, .start: return false
        }
    }

    /// step별로 나눠서(색 구분 등) 그리고 애니메이션할 대상인지 — 대중교통 계열이고 실제
    /// steps가 있어야 한다.
    static func usesSteppedRendering(leg: RouteLeg, hasRealRoute: Bool) -> Bool {
        hasRealRoute && isTransitVehicleMode(leg.mode) && !leg.steps.isEmpty
    }

    /// stepped 렌더링 대상이 아닌 leg(도보/자동차/직선 fallback 등)의 단일 경로 좌표.
    /// leg.polyline(overview)이 있으면 그걸 디코드하고, 없거나 실패하면 두 점 직선.
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
