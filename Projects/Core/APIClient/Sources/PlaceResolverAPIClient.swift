import ComposableArchitecture
import Foundation

public struct ResolvedPlace: Codable, Equatable, Sendable {
    public var name: String
    public var lat: Double?
    public var lng: Double?
    public var address: String?
    public var placeId: String?

    public init(name: String, lat: Double? = nil, lng: Double? = nil, address: String? = nil, placeId: String? = nil) {
        self.name = name
        self.lat = lat
        self.lng = lng
        self.address = address
        self.placeId = placeId
    }
}

public enum PlaceResolverError: Error, Equatable {
    case invalidEndpoint
    case notSignedIn
    case requestFailed
    case unresolvableLink
}

@DependencyClient
public struct PlaceResolverAPIClient: Sendable {
    public var resolve: @Sendable (_ url: String) async throws -> ResolvedPlace
}

extension PlaceResolverAPIClient: DependencyKey {
    public static let liveValue: PlaceResolverAPIClient = {
        PlaceResolverAPIClient(
            resolve: { urlString in
                guard let endpoint = URL(string: "https://mock-serverless.vercel.app/api/travel/place/resolve") else {
                    throw PlaceResolverError.invalidEndpoint
                }
                guard let session = try? await SupabaseClientProvider.shared.auth.session else {
                    throw PlaceResolverError.notSignedIn
                }

                var request = URLRequest(url: endpoint)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
                request.httpBody = try JSONEncoder().encode(["url": urlString])

                let (data, response) = try await URLSession.shared.data(for: request)
                guard
                    let httpResponse = response as? HTTPURLResponse,
                    (200 ..< 300).contains(httpResponse.statusCode)
                else {
                    throw PlaceResolverError.requestFailed
                }

                let decoded = try JSONDecoder().decode(ResolveResponse.self, from: data)
                guard decoded.result, let place = decoded.place else {
                    throw PlaceResolverError.unresolvableLink
                }
                return place
            }
        )
    }()
}

private struct ResolveResponse: Decodable {
    let result: Bool
    let place: ResolvedPlace?
}

extension DependencyValues {
    public var placeResolverAPIClient: PlaceResolverAPIClient {
        get { self[PlaceResolverAPIClient.self] }
        set { self[PlaceResolverAPIClient.self] = newValue }
    }
}
