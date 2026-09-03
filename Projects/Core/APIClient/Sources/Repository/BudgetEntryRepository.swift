import ComposableArchitecture
import Foundation
import Models
import Supabase

@DependencyClient
public struct BudgetEntryRepository: Sendable {
    public var fetchAllEntries: @Sendable (_ tripId: Trip.ID) async throws -> [BudgetEntry]
    public var createEntry: @Sendable (_ entry: BudgetEntry) async throws -> BudgetEntry
    public var updateEntry: @Sendable (_ entry: BudgetEntry) async throws -> BudgetEntry
    public var deleteEntry: @Sendable (_ id: BudgetEntry.ID) async throws -> Void
}

extension BudgetEntryRepository: DependencyKey {
    public static let liveValue: BudgetEntryRepository = {
        let client = SupabaseClientProvider.shared

        return BudgetEntryRepository(
            fetchAllEntries: { tripId in
                try await client
                    .from("budget_entries")
                    .select()
                    .eq("trip_id", value: tripId)
                    .order("created_at", ascending: true)
                    .execute()
                    .value
            },
            createEntry: { entry in
                try await client
                    .from("budget_entries")
                    .insert(entry)
                    .select()
                    .single()
                    .execute()
                    .value
            },
            updateEntry: { entry in
                try await client
                    .from("budget_entries")
                    .update(entry)
                    .eq("id", value: entry.id)
                    .select()
                    .single()
                    .execute()
                    .value
            },
            deleteEntry: { id in
                try await client
                    .from("budget_entries")
                    .delete()
                    .eq("id", value: id)
                    .execute()
            }
        )
    }()
}

extension DependencyValues {
    public var budgetEntryRepository: BudgetEntryRepository {
        get { self[BudgetEntryRepository.self] }
        set { self[BudgetEntryRepository.self] = newValue }
    }
}
