import APIClient
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct AddBudgetEntryFeature {
    @ObservableState
    public struct State: Equatable {
        public var tripID: Trip.ID
        public var editingOriginalEntry: BudgetEntry?

        public var items: IdentifiedArrayOf<ItineraryItem>
        public var days: IdentifiedArrayOf<TripDay>

        public var name: String = ""
        public var costAmountText: String = ""
        public var costCurrency: String = "KRW"
        public var costAmountKRWText: String = ""
        public var costCategory: CostCategory?
        public var paymentStatus: PaymentStatus?
        public var notes: String = ""
        public var date: Date?
        public var linkedItemId: ItineraryItem.ID?

        public var isSaving = false
        public var errorMessage: String?
        public var savedEntry: BudgetEntry?

        public init(
            tripID: Trip.ID,
            items: IdentifiedArrayOf<ItineraryItem> = [],
            days: IdentifiedArrayOf<TripDay> = []
        ) {
            self.tripID = tripID
            self.items = items
            self.days = days
        }

        public init(
            editing entry: BudgetEntry,
            items: IdentifiedArrayOf<ItineraryItem> = [],
            days: IdentifiedArrayOf<TripDay> = []
        ) {
            tripID = entry.tripId
            self.items = items
            self.days = days
            editingOriginalEntry = entry
            name = entry.name
            costAmountText = entry.costAmount.map { "\($0)" } ?? ""
            costCurrency = entry.costCurrency ?? "KRW"
            costAmountKRWText = entry.costAmountKRW.map { "\($0)" } ?? ""
            costCategory = entry.costCategory
            paymentStatus = entry.paymentStatus
            notes = entry.notes ?? ""
            date = entry.date
            linkedItemId = entry.linkedItemId
        }

        public var linkedItem: ItineraryItem? {
            linkedItemId.flatMap { items[id: $0] }
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case dateSelected(Date)
        case dateCleared
        case linkedItemSelected(ItineraryItem.ID)
        case linkedItemCleared
        case saveButtonTapped
        case saveResponse(Result<BudgetEntry, any Error>)
    }

    @Dependency(\.budgetEntryRepository) var budgetEntryRepository
    @Dependency(\.uuid) var uuid

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .dateSelected(date):
                state.date = date
                state.linkedItemId = nil
                return .none

            case .dateCleared:
                state.date = nil
                return .none

            case let .linkedItemSelected(id):
                state.linkedItemId = id
                state.date = nil
                return .none

            case .linkedItemCleared:
                state.linkedItemId = nil
                return .none

            case .saveButtonTapped:
                let trimmedName = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    state.errorMessage = "이름을 입력해주세요."
                    return .none
                }
                guard state.costAmountText.isEmpty || (state.costCategory != nil && state.paymentStatus != nil) else {
                    state.errorMessage = "금액을 입력했으면 카테고리와 결제 상태도 선택해주세요."
                    return .none
                }
                state.name = trimmedName
                state.errorMessage = nil
                state.isSaving = true

                let costAmount = Decimal(string: state.costAmountText)
                let costAmountKRW: Decimal? = if let explicit = Decimal(string: state.costAmountKRWText) {
                    explicit
                } else if state.costCurrency.uppercased() == "KRW" {
                    costAmount
                } else {
                    nil
                }
                let costCurrency = state.costAmountText.isEmpty ? nil : state.costCurrency
                let notes = state.notes.isEmpty ? nil : state.notes

                let entry: BudgetEntry
                let isEditing: Bool
                if var original = state.editingOriginalEntry {
                    original.name = trimmedName
                    original.costAmount = costAmount
                    original.costCurrency = costCurrency
                    original.costAmountKRW = costAmountKRW
                    original.costCategory = state.costCategory
                    original.paymentStatus = state.paymentStatus
                    original.notes = notes
                    original.date = state.date
                    original.linkedItemId = state.linkedItemId
                    entry = original
                    isEditing = true
                } else {
                    entry = BudgetEntry(
                        id: uuid(),
                        tripId: state.tripID,
                        name: trimmedName,
                        costAmount: costAmount,
                        costCurrency: costCurrency,
                        costAmountKRW: costAmountKRW,
                        costCategory: state.costCategory,
                        paymentStatus: state.paymentStatus,
                        notes: notes,
                        date: state.date,
                        linkedItemId: state.linkedItemId
                    )
                    isEditing = false
                }

                FlowneyLog.debug("예산 항목 저장 시작 isEditing=\(isEditing) name=\(entry.name)", category: .budget)
                return .run { [entry, isEditing] send in
                    do {
                        let saved = isEditing
                            ? try await budgetEntryRepository.updateEntry(entry)
                            : try await budgetEntryRepository.createEntry(entry)
                        await send(.saveResponse(.success(saved)))
                    } catch {
                        FlowneyLog.error("예산 항목 저장 실패: \(error)", category: .budget)
                        await send(.saveResponse(.failure(error)))
                    }
                }

            case let .saveResponse(.success(entry)):
                state.isSaving = false
                state.savedEntry = entry
                return .none

            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
