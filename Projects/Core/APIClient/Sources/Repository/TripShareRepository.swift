import ComposableArchitecture
import Foundation
import Models
import Supabase

@DependencyClient
public struct TripShareRepository: Sendable {
    public var fetchShare: @Sendable (_ tripId: Trip.ID) async throws -> TripShare?
    public var upsertShare: @Sendable (_ tripId: Trip.ID, _ visibility: TripShare.Visibility, _ password: String?) async throws -> TripShare
    public var revokeShare: @Sendable (_ tripId: Trip.ID) async throws -> Void
}

extension TripShareRepository: DependencyKey {
    public static let liveValue: TripShareRepository = {
        let client = SupabaseClientProvider.shared

        return TripShareRepository(
            fetchShare: { tripId in
                try await client
                    .from("trip_shares")
                    .select()
                    .eq("trip_id", value: tripId)
                    .maybeSingle()
                    .execute()
                    .value
            },
            upsertShare: { tripId, visibility, password in
                struct Params: Encodable {
                    let pTripId: Trip.ID
                    let pVisibility: String
                    let pPassword: String?
                    enum CodingKeys: String, CodingKey {
                        case pTripId = "p_trip_id"
                        case pVisibility = "p_visibility"
                        case pPassword = "p_password"
                    }
                }
                return try await client
                    .rpc("upsert_trip_share", params: Params(pTripId: tripId, pVisibility: visibility.rawValue, pPassword: password))
                    .single()
                    .execute()
                    .value
            },
            revokeShare: { tripId in
                struct Params: Encodable {
                    let pTripId: Trip.ID
                    enum CodingKeys: String, CodingKey {
                        case pTripId = "p_trip_id"
                    }
                }
                try await client
                    .rpc("revoke_trip_share", params: Params(pTripId: tripId))
                    .execute()
            }
        )
    }()
}

extension DependencyValues {
    public var tripShareRepository: TripShareRepository {
        get { self[TripShareRepository.self] }
        set { self[TripShareRepository.self] = newValue }
    }
}
