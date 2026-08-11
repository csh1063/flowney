import ComposableArchitecture
import Foundation
import Models
import Supabase

@DependencyClient
public struct TripsRepository: Sendable {
    public var fetchTrips: @Sendable () async throws -> [Trip]
    public var createTrip: @Sendable (_ trip: Trip) async throws -> Trip
    public var updateTrip: @Sendable (_ trip: Trip) async throws -> Trip
    public var deleteTrip: @Sendable (_ id: Trip.ID) async throws -> Void

    public var fetchCountries: @Sendable (_ tripId: Trip.ID) async throws -> [TripCountry]
    public var upsertCountries: @Sendable (_ countries: [TripCountry]) async throws -> Void

    public var fetchDays: @Sendable (_ tripId: Trip.ID) async throws -> [TripDay]
    public var createDays: @Sendable (_ days: [TripDay]) async throws -> [TripDay]
}

extension TripsRepository: DependencyKey {
    public static let liveValue: TripsRepository = {
        let client = SupabaseClientProvider.shared

        return TripsRepository(
            fetchTrips: {
                try await client
                    .from("trips")
                    .select()
                    .order("start_date", ascending: true)
                    .execute()
                    .value
            },
            createTrip: { trip in
                try await client
                    .from("trips")
                    .insert(trip)
                    .select()
                    .single()
                    .execute()
                    .value
            },
            updateTrip: { trip in
                try await client
                    .from("trips")
                    .update(trip)
                    .eq("id", value: trip.id)
                    .select()
                    .single()
                    .execute()
                    .value
            },
            deleteTrip: { id in
                try await client
                    .from("trips")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            },
            fetchCountries: { tripId in
                try await client
                    .from("trip_countries")
                    .select()
                    .eq("trip_id", value: tripId)
                    .order("sort_order", ascending: true)
                    .execute()
                    .value
            },
            upsertCountries: { countries in
                try await client
                    .from("trip_countries")
                    .upsert(countries)
                    .execute()
            },
            fetchDays: { tripId in
                try await client
                    .from("trip_days")
                    .select()
                    .eq("trip_id", value: tripId)
                    .order("day_index", ascending: true)
                    .execute()
                    .value
            },
            createDays: { days in
                try await client
                    .from("trip_days")
                    .insert(days)
                    .select()
                    .execute()
                    .value
            }
        )
    }()
}

extension DependencyValues {
    public var tripsRepository: TripsRepository {
        get { self[TripsRepository.self] }
        set { self[TripsRepository.self] = newValue }
    }
}
