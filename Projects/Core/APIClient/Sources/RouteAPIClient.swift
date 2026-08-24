import ComposableArchitecture
import Foundation
import Models

public struct RouteLegRequestItem: Encodable, Sendable {
    public var id: UUID
    public var lat: Double?
    public var lng: Double?
    public var mode: String?
    public var noRoute: Bool

    public init(id: UUID, lat: Double?, lng: Double?, mode: TransportMode?, noRoute: Bool) {
        self.id = id
        self.lat = lat
        self.lng = lng
        self.mode = mode?.rawValue
        self.noRoute = noRoute
    }
}

public enum RouteAPIError: Error, Equatable {
    case invalidEndpoint
    case notSignedIn
    case requestFailed
}

public enum RouteRefreshScope: String, Encodable, Sendable {
    case all
    case today
}

public struct RefreshedDayLegs: Decodable, Sendable {
    public var dayId: TripDay.ID
    public var legs: [RouteLeg]
}

@DependencyClient
public struct RouteAPIClient: Sendable {
    public var fetchDayRoutes: @Sendable (_ items: [RouteLegRequestItem]) async throws -> [RouteLeg]
    public var refreshTripRoutes: @Sendable (_ tripId: Trip.ID, _ dayId: TripDay.ID?, _ scope: RouteRefreshScope) async throws -> [RefreshedDayLegs]
}

extension RouteAPIClient: DependencyKey {
    public static let liveValue: RouteAPIClient = {
        RouteAPIClient(
            fetchDayRoutes: { items in
                guard let endpoint = URL(string: "https://mock-serverless.vercel.app/api/travel/route/day") else {
                    throw RouteAPIError.invalidEndpoint
                }
                guard let session = try? await SupabaseClientProvider.shared.auth.session else {
                    throw RouteAPIError.notSignedIn
                }

                var request = URLRequest(url: endpoint)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.httpBody = try JSONEncoder().encode(["items": items])

                let (data, response) = try await URLSession.shared.data(for: request)
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200 ..< 300).contains(httpResponse.statusCode)
                else {
                    throw RouteAPIError.requestFailed
                }

                let decoded = try JSONDecoder().decode(RouteDayResponse.self, from: data)
                return decoded.legs
            },
            refreshTripRoutes: { tripId, dayId, scope in
                guard let endpoint = URL(string: "https://mock-serverless.vercel.app/api/travel/trip/route/refresh") else {
                    throw RouteAPIError.invalidEndpoint
                }
                guard let session = try? await SupabaseClientProvider.shared.auth.session else {
                    throw RouteAPIError.notSignedIn
                }

                struct Body: Encodable {
                    let tripId: Trip.ID
                    let dayId: TripDay.ID?
                    let scope: RouteRefreshScope
                }

                var request = URLRequest(url: endpoint)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.httpBody = try JSONEncoder().encode(Body(tripId: tripId, dayId: dayId, scope: scope))

                let (data, response) = try await URLSession.shared.data(for: request)
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200 ..< 300).contains(httpResponse.statusCode)
                else {
                    throw RouteAPIError.requestFailed
                }

                let decoded = try JSONDecoder().decode(RouteRefreshResponse.self, from: data)
                return decoded.days
            }
        )
    }()
}

private struct RouteDayResponse: Decodable {
    let legs: [RouteLeg]
}

private struct RouteRefreshResponse: Decodable {
    let days: [RefreshedDayLegs]
}

extension DependencyValues {
    public var routeAPIClient: RouteAPIClient {
        get { self[RouteAPIClient.self] }
        set { self[RouteAPIClient.self] = newValue }
    }
}
