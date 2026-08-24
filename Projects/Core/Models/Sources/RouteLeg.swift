import Foundation

public struct RouteLeg: Codable, Identifiable, Equatable, Sendable {
    public var fromItemId: UUID
    public var toItemId: UUID
    public var mode: TransportMode
    public var status: RouteLegStatus
    public var polyline: String?
    public var steps: [RouteStep]
    public var distanceMeters: Int?
    public var durationSec: Int?
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
