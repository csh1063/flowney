import ComposableArchitecture
import Foundation
import Models

/// "오프라인 저장" 메뉴에서 호출 — 그 트립의 days/items/countries/budget/memo를
/// 지금 이 자리에서 적극적으로 다 받아와 캐시에 저장한다. 날씨/경로는 각 화면을
/// 실제로 열어볼 때 `ItineraryFeature`가 증분으로 캐싱하므로 여기서는 다루지 않는다.
public struct OfflineTripSaver: Sendable {
    @Dependency(\.tripsRepository) private var tripsRepository
    @Dependency(\.itineraryRepository) private var itineraryRepository
    @Dependency(\.budgetEntryRepository) private var budgetEntryRepository
    @Dependency(\.memoItemRepository) private var memoItemRepository
    @Dependency(\.offlineCacheClient) private var offlineCacheClient

    public init() {}

    /// 하나라도 받아오지 못하면 throw — 데이터 없이 "저장됨" 목록에 올라가지 않게 한다.
    public func save(trip: Trip) async throws {
        async let days = tripsRepository.fetchDays(trip.id)
        async let countries = tripsRepository.fetchCountries(trip.id)
        async let items = itineraryRepository.fetchAllItems(trip.id)
        async let entries = budgetEntryRepository.fetchAllEntries(trip.id)
        async let memoItems = memoItemRepository.fetchAllItems(trip.id)

        let (fetchedDays, fetchedCountries, fetchedItems, fetchedEntries, fetchedMemoItems) =
            try await (days, countries, items, entries, memoItems)

        await offlineCacheClient.saveCodable(fetchedDays, key: OfflineCacheKey.days(trip.id))
        await offlineCacheClient.saveCodable(fetchedCountries, key: OfflineCacheKey.countries(trip.id))
        await offlineCacheClient.saveCodable(fetchedItems, key: OfflineCacheKey.items(trip.id))
        await offlineCacheClient.saveCodable(fetchedEntries, key: OfflineCacheKey.budgetEntries(trip.id))
        await offlineCacheClient.saveCodable(fetchedMemoItems, key: OfflineCacheKey.memoItems(trip.id))

        await offlineCacheClient.saveCodable(trip, key: OfflineCacheKey.trip(trip.id))

        var savedTrips = await offlineCacheClient.loadCodable([Trip].self, key: OfflineCacheKey.savedTrips) ?? []
        savedTrips.removeAll { $0.id == trip.id }
        savedTrips.append(trip)
        await offlineCacheClient.saveCodable(savedTrips, key: OfflineCacheKey.savedTrips)
    }

    public func removeSavedTrip(_ tripID: UUID) async {
        var savedTrips = await offlineCacheClient.loadCodable([Trip].self, key: OfflineCacheKey.savedTrips) ?? []
        savedTrips.removeAll { $0.id == tripID }
        await offlineCacheClient.saveCodable(savedTrips, key: OfflineCacheKey.savedTrips)

        for key in [
            OfflineCacheKey.trip(tripID), OfflineCacheKey.days(tripID), OfflineCacheKey.items(tripID),
            OfflineCacheKey.countries(tripID), OfflineCacheKey.budgetEntries(tripID),
            OfflineCacheKey.memoItems(tripID), OfflineCacheKey.weather(tripID), OfflineCacheKey.routeLegs(tripID)
        ] {
            await offlineCacheClient.delete(key)
        }
    }
}
