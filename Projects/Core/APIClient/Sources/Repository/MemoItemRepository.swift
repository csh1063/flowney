import ComposableArchitecture
import Foundation
import Models
import Supabase

@DependencyClient
public struct MemoItemRepository: Sendable {
    public var fetchAllItems: @Sendable (_ tripId: Trip.ID) async throws -> [MemoItem]
    public var createItem: @Sendable (_ item: MemoItem) async throws -> MemoItem
    public var updateItem: @Sendable (_ item: MemoItem) async throws -> MemoItem
    public var deleteItem: @Sendable (_ id: MemoItem.ID) async throws -> Void

    public var reorderItems: @Sendable (_ updates: [MemoItemReorderUpdate]) async throws -> Void
}

public struct MemoItemReorderUpdate: Encodable, Equatable, Sendable {
    public var id: UUID
    public var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case sortOrder = "sort_order"
    }

    public init(id: UUID, sortOrder: Int) {
        self.id = id
        self.sortOrder = sortOrder
    }
}

extension MemoItemRepository: DependencyKey {
    public static let liveValue: MemoItemRepository = {
        let client = SupabaseClientProvider.shared

        return MemoItemRepository(
            fetchAllItems: { tripId in
                try await client
                    .from("memo_items")
                    .select()
                    .eq("trip_id", value: tripId)
                    .order("sort_order", ascending: true)
                    .execute()
                    .value
            },
            createItem: { item in
                try await client
                    .from("memo_items")
                    .insert(item)
                    .select()
                    .single()
                    .execute()
                    .value
            },
            updateItem: { item in
                try await client
                    .from("memo_items")
                    .update(item)
                    .eq("id", value: item.id)
                    .select()
                    .single()
                    .execute()
                    .value
            },
            deleteItem: { id in
                try await client
                    .from("memo_items")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            },
            reorderItems: { updates in
                struct Params: Encodable {
                    let pUpdates: [MemoItemReorderUpdate]
                    enum CodingKeys: String, CodingKey {
                        case pUpdates = "p_updates"
                    }
                }
                try await client
                    .rpc("reorder_memo_items", params: Params(pUpdates: updates))
                    .execute()
            }
        )
    }()
}

extension DependencyValues {
    public var memoItemRepository: MemoItemRepository {
        get { self[MemoItemRepository.self] }
        set { self[MemoItemRepository.self] = newValue }
    }
}
