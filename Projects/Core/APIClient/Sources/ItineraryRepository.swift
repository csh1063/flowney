import ComposableArchitecture
import Foundation
import Models
import Supabase

@DependencyClient
public struct ItineraryRepository: Sendable {
    /// 여행 전체 일정(요금표 화면 등에서 사용) — 하루 단위가 아닌 trip 단위 조회.
    public var fetchAllItems: @Sendable (_ tripId: Trip.ID) async throws -> [ItineraryItem]
    public var fetchDayItems: @Sendable (_ dayId: TripDay.ID) async throws -> [ItineraryItem]
    public var createItem: @Sendable (_ item: ItineraryItem) async throws -> ItineraryItem
    public var updateItem: @Sendable (_ item: ItineraryItem) async throws -> ItineraryItem
    public var deleteItem: @Sendable (_ id: ItineraryItem.ID) async throws -> Void

    /// 드래그앤드롭 결과를 한 번의 RPC 호출로 반영.
    public var reorderItems: @Sendable (_ updates: [ItemReorderUpdate]) async throws -> Void
}

public struct ItemReorderUpdate: Encodable, Equatable, Sendable {
    public var id: UUID
    public var dayId: UUID
    public var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case dayId = "day_id"
        case sortOrder = "sort_order"
    }

    public init(id: UUID, dayId: UUID, sortOrder: Int) {
        self.id = id
        self.dayId = dayId
        self.sortOrder = sortOrder
    }
}

extension ItineraryRepository: DependencyKey {
    public static let liveValue: ItineraryRepository = {
        let client = SupabaseClientProvider.shared

        return ItineraryRepository(
            fetchAllItems: { tripId in
                try await client
                    .from("itinerary_items")
                    .select()
                    .eq("trip_id", value: tripId)
                    .order("sort_order", ascending: true)
                    .execute()
                    .value
            },
            fetchDayItems: { dayId in
                try await client
                    .from("itinerary_items")
                    .select()
                    .eq("day_id", value: dayId)
                    .order("sort_order", ascending: true)
                    .execute()
                    .value
            },
            createItem: { item in
                try await client
                    .from("itinerary_items")
                    .insert(item)
                    .select()
                    .single()
                    .execute()
                    .value
            },
            updateItem: { item in
                try await client
                    .from("itinerary_items")
                    .update(item)
                    .eq("id", value: item.id)
                    .select()
                    .single()
                    .execute()
                    .value
            },
            deleteItem: { id in
                try await client
                    .from("itinerary_items")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            },
            reorderItems: { updates in
                struct Params: Encodable {
                    let pUpdates: [ItemReorderUpdate]
                    enum CodingKeys: String, CodingKey {
                        case pUpdates = "p_updates"
                    }
                }
                try await client
                    .rpc("reorder_itinerary_items", params: Params(pUpdates: updates))
                    .execute()
            }
        )
    }()
}

extension DependencyValues {
    public var itineraryRepository: ItineraryRepository {
        get { self[ItineraryRepository.self] }
        set { self[ItineraryRepository.self] = newValue }
    }
}
