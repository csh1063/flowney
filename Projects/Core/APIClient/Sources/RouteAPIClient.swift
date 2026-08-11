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

/// mock-serverless의 `POST /api/travel/route/day`를 호출해서 하루치 일정의 구간별
/// 실제 경로(폴리라인)를 한 번에 받아온다.
@DependencyClient
public struct RouteAPIClient: Sendable {
    public var fetchDayRoutes: @Sendable (_ items: [RouteLegRequestItem]) async throws -> [RouteLeg]
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
            }
        )
    }()
}

private struct RouteDayResponse: Decodable {
    let legs: [RouteLeg]
}

extension DependencyValues {
    public var routeAPIClient: RouteAPIClient {
        get { self[RouteAPIClient.self] }
        set { self[RouteAPIClient.self] = newValue }
    }
}
