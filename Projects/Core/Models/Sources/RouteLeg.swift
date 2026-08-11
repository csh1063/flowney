import Foundation

/// `/api/travel/route/day` 응답의 leg 하나. `pointAtFraction` 애니메이션에 쓰이는 폴리라인 좌표.
public struct RouteLeg: Codable, Identifiable, Equatable, Sendable {
    public var fromItemId: UUID
    public var toItemId: UUID
    public var mode: TransportMode
    public var status: RouteLegStatus
    public var polyline: String?
    public var steps: [RouteStep]
    public var distanceMeters: Int?
    public var durationSec: Int?
    /// 걷기/대중교통을 비교했을 때 추천되지 못한 나머지 경로들 — 지도에 같이 그리기용이고
    /// 애니메이션 대상은 아니다(위 polyline/steps가 추천된 경로).
    public var alternatives: [RouteLegAlternative]

    public var id: String { "\(fromItemId)-\(toItemId)" }

    enum CodingKeys: String, CodingKey {
        case fromItemId = "fromItemId"
        case toItemId = "toItemId"
        case mode
        case status
        case polyline
        case steps
        case distanceMeters
        case durationSec
        case alternatives
    }

    // `/api/travel/route/day`는 SKIPPED/NO_ROUTE 상태인 구간에는 `steps`(그리고 polyline/
    // distanceMeters/durationSec)를 아예 응답에 안 넣는다. `steps`가 non-optional 배열이라
    // 자동 합성된 Decodable로는 그 키가 없을 때 "The data couldn't be read because it is
    // missing." 에러로 디코딩이 통째로 실패해서, 없으면 빈 배열로 채우는 커스텀 디코더를 쓴다.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        fromItemId = try container.decode(UUID.self, forKey: .fromItemId)
        toItemId = try container.decode(UUID.self, forKey: .toItemId)
        mode = try container.decode(TransportMode.self, forKey: .mode)
        status = try container.decode(RouteLegStatus.self, forKey: .status)
        polyline = try container.decodeIfPresent(String.self, forKey: .polyline)
        steps = try container.decodeIfPresent([RouteStep].self, forKey: .steps) ?? []
        distanceMeters = try container.decodeIfPresent(Int.self, forKey: .distanceMeters)
        durationSec = try container.decodeIfPresent(Int.self, forKey: .durationSec)
        alternatives = try container.decodeIfPresent([RouteLegAlternative].self, forKey: .alternatives) ?? []
    }

    public init(
        fromItemId: UUID,
        toItemId: UUID,
        mode: TransportMode,
        status: RouteLegStatus,
        polyline: String? = nil,
        steps: [RouteStep] = [],
        distanceMeters: Int? = nil,
        durationSec: Int? = nil,
        alternatives: [RouteLegAlternative] = []
    ) {
        self.fromItemId = fromItemId
        self.toItemId = toItemId
        self.mode = mode
        self.status = status
        self.polyline = polyline
        self.steps = steps
        self.distanceMeters = distanceMeters
        self.durationSec = durationSec
        self.alternatives = alternatives
    }
}

public enum RouteLegStatus: String, Codable, Sendable {
    case ok = "OK"
    case noRoute = "NO_ROUTE"
    case skipped = "SKIPPED"
}

/// 걷기/대중교통 비교에서 추천되지 못한 나머지 경로 — 지도에 얇게 같이 그리는 용도.
public struct RouteLegAlternative: Codable, Equatable, Sendable {
    public var mode: TransportMode
    public var polyline: String?
    public var distanceMeters: Int?
    public var durationSec: Int?

    public init(mode: TransportMode, polyline: String? = nil, distanceMeters: Int? = nil, durationSec: Int? = nil) {
        self.mode = mode
        self.polyline = polyline
        self.distanceMeters = distanceMeters
        self.durationSec = durationSec
    }
}

public struct RouteStep: Codable, Equatable, Sendable {
    public var travelMode: String
    public var polyline: String
    public var distanceMeters: Int
    public var durationSec: Int
    public var vehicleType: String?
    public var lineName: String?
    /// 그 노선의 실제 브랜드 색(hex, 예: "#f2b400") — GTFS 피드에 route_color가 있는
    /// 지역/노선만 내려온다. 없으면 지도에서 이동수단별 기본 색으로 대체한다.
    public var lineColor: String?

    public init(
        travelMode: String,
        polyline: String,
        distanceMeters: Int,
        durationSec: Int,
        vehicleType: String? = nil,
        lineName: String? = nil,
        lineColor: String? = nil
    ) {
        self.travelMode = travelMode
        self.polyline = polyline
        self.distanceMeters = distanceMeters
        self.durationSec = durationSec
        self.vehicleType = vehicleType
        self.lineName = lineName
        self.lineColor = lineColor
    }
}
