import Foundation

public struct TripShare: Codable, Equatable, Sendable {
    public var tripId: Trip.ID
    public var token: String
    public var visibility: Visibility
    public var updatedAt: Date

    public enum Visibility: String, Codable, Sendable {
        case pub = "public"
        case password
    }

    enum CodingKeys: String, CodingKey {
        case tripId = "trip_id"
        case token
        case visibility
        case updatedAt = "updated_at"
    }

    public init(tripId: Trip.ID, token: String, visibility: Visibility, updatedAt: Date = .now) {
        self.tripId = tripId
        self.token = token
        self.visibility = visibility
        self.updatedAt = updatedAt
    }

    public var shareURL: URL {
        URL(string: "https://baciweb.vercel.app/share.html?t=\(token)")!
    }
}
