import APIClient
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct BudgetFeature {
    @ObservableState
    public struct State: Equatable {
        public var trip: Trip
        public var items: IdentifiedArrayOf<ItineraryItem> = []
        public var isLoading = false
        public var errorMessage: String?

        public init(trip: Trip) {
            self.trip = trip
        }

        public struct CategoryGroup: Identifiable, Equatable {
            public var category: CostCategory
            public var items: [ItineraryItem]
            public var totalKRW: Decimal
            public var id: CostCategory { category }
        }

        /// 카테고리별 그룹/합계 — 저장하지 않고 items로부터 매번 파생 계산.
        public var groupedByCategory: [CategoryGroup] {
            let grouped = Dictionary(grouping: items.filter { $0.costCategory != nil }) { $0.costCategory! }
            return grouped
                .map { category, items in
                    CategoryGroup(
                        category: category,
                        items: items,
                        totalKRW: items.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) }
                    )
                }
                .sorted { $0.totalKRW > $1.totalKRW }
        }

        public var paidItems: [ItineraryItem] {
            items.filter { $0.paymentStatus == .paid }
        }

        public var unpaidItems: [ItineraryItem] {
            items.filter {
                $0.paymentStatus == .fixed || $0.paymentStatus == .pending || $0.paymentStatus == .variable
            }
        }

        public var paidTotalKRW: Decimal {
            paidItems.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) }
        }

        public var unpaidTotalKRW: Decimal {
            unpaidItems.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) }
        }

        public var grandTotalKRW: Decimal {
            items.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) }
        }

        /// 금액은 입력했지만 원화 환산은 안 넣은 항목 — 합계에서 빠져있다는 걸 알려주기 위함.
        public var itemsMissingKRWConversion: [ItineraryItem] {
            items.filter { $0.costAmount != nil && $0.costAmountKRW == nil }
        }
    }

    public enum Action {
        case onAppear
        case itemsResponse(Result<[ItineraryItem], any Error>)
    }

    @Dependency(\.itineraryRepository) var itineraryRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                let tripID = state.trip.id
                return .run { send in
                    do {
                        let items = try await itineraryRepository.fetchAllItems(tripID)
                        await send(.itemsResponse(.success(items)))
                    } catch {
                        await send(.itemsResponse(.failure(error)))
                    }
                }

            case let .itemsResponse(.success(items)):
                state.isLoading = false
                state.items = IdentifiedArrayOf(uniqueElements: items)
                return .none

            case let .itemsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}
