import AddItem
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
        public var entries: IdentifiedArrayOf<BudgetEntry> = []
        public var days: IdentifiedArrayOf<TripDay> = []
        public var isLoading = false
        public var errorMessage: String?
        public var sortMode: SortMode = .byDate
        public var addItemFlowRequest: AddItemFlowFeature.State?

        public init(trip: Trip) {
            self.trip = trip
        }

        public enum SortMode: String, CaseIterable, Equatable {
            case byDate
            case byPaymentStatus
            case byCategory

            public var displayName: String {
                switch self {
                case .byDate: return "날짜별"
                case .byPaymentStatus: return "결제전후"
                case .byCategory: return "항목별"
                }
            }
        }

        public enum BudgetLine: Identifiable, Equatable {
            case item(ItineraryItem)
            case entry(BudgetEntry)

            public var id: AnyHashable {
                switch self {
                case let .item(item): item.id
                case let .entry(entry): entry.id
                }
            }

            public var name: String {
                switch self {
                case let .item(item): item.name
                case let .entry(entry): entry.name
                }
            }

            public var costAmount: Decimal? {
                switch self {
                case let .item(item): item.costAmount
                case let .entry(entry): entry.costAmount
                }
            }

            public var costCurrency: String? {
                switch self {
                case let .item(item): item.costCurrency
                case let .entry(entry): entry.costCurrency
                }
            }

            public var costAmountKRW: Decimal? {
                switch self {
                case let .item(item): item.costAmountKRW
                case let .entry(entry): entry.costAmountKRW
                }
            }

            public var costCategory: CostCategory? {
                switch self {
                case let .item(item): item.costCategory
                case let .entry(entry): entry.costCategory
                }
            }

            public var paymentStatus: PaymentStatus? {
                switch self {
                case let .item(item): item.paymentStatus
                case let .entry(entry): entry.paymentStatus
                }
            }
        }

        public struct CurrencyTotal: Identifiable, Equatable {
            public var currency: String
            public var total: Decimal
            public var id: String { currency }
        }

        public struct CategoryGroup: Identifiable, Equatable {
            public var category: CostCategory
            public var lines: [BudgetLine]
            public var totalKRW: Decimal
            public var currencyTotals: [CurrencyTotal]
            public var id: CostCategory { category }
        }

        public var lines: [BudgetLine] {
            items.map(BudgetLine.item) + entries.map(BudgetLine.entry)
        }

        public func date(for line: BudgetLine) -> Date? {
            switch line {
            case let .item(item):
                return days[id: item.dayId]?.dayDate
            case let .entry(entry):
                if let date = entry.date { return date }
                if let linkedId = entry.linkedItemId, let linkedItem = items[id: linkedId] {
                    return days[id: linkedItem.dayId]?.dayDate
                }
                return nil
            }
        }

        public struct DateGroup: Identifiable, Equatable {
            public var date: Date?
            public var lines: [BudgetLine]
            public var id: Date? { date }
        }

        public var linesGroupedByDate: [DateGroup] {
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: lines.filter { $0.costAmount != nil }) { line -> Date? in
                guard let date = date(for: line) else { return nil }
                return calendar.startOfDay(for: date)
            }
            var groups: [DateGroup] = []
            if let undated = grouped[nil] {
                groups.append(DateGroup(date: nil, lines: undated))
            }
            for key in grouped.keys.compactMap({ $0 }).sorted() {
                groups.append(DateGroup(date: key, lines: grouped[key] ?? []))
            }
            return groups
        }

        public struct CategoryLineGroup: Identifiable, Equatable {
            public var category: CostCategory?
            public var lines: [BudgetLine]
            public var id: String { category?.rawValue ?? "uncategorized" }
        }

        public var linesGroupedByCategory: [CategoryLineGroup] {
            let filtered = lines.filter { $0.costAmount != nil }
            var groups: [CategoryLineGroup] = []
            for category in CostCategory.allCases {
                let matching = filtered.filter { $0.costCategory == category }
                if !matching.isEmpty {
                    groups.append(CategoryLineGroup(category: category, lines: matching))
                }
            }
            let uncategorized = filtered.filter { $0.costCategory == nil }
            if !uncategorized.isEmpty {
                groups.append(CategoryLineGroup(category: nil, lines: uncategorized))
            }
            return groups
        }

        private func currencyTotals(for lines: [BudgetLine]) -> [CurrencyTotal] {
            let grouped = Dictionary(
                grouping: lines.filter { $0.costCurrency != nil && $0.costAmount != nil },
                by: { $0.costCurrency! }
            )
            return grouped
                .map { currency, lines in
                    CurrencyTotal(currency: currency, total: lines.reduce(Decimal(0)) { $0 + ($1.costAmount ?? 0) })
                }
                .sorted { $0.currency < $1.currency }
        }

        public var groupedByCategory: [CategoryGroup] {
            let grouped = Dictionary(grouping: lines.filter { $0.costCategory != nil }) { $0.costCategory! }
            return grouped
                .map { category, lines in
                    CategoryGroup(
                        category: category,
                        lines: lines,
                        totalKRW: lines.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) },
                        currencyTotals: currencyTotals(for: lines)
                    )
                }
                .sorted { $0.totalKRW > $1.totalKRW }
        }

        public var paidLines: [BudgetLine] {
            lines.filter { $0.paymentStatus == .paid }
        }

        public var unpaidLines: [BudgetLine] {
            lines.filter { $0.paymentStatus == .fixed || $0.paymentStatus == .pending }
        }

        public var paidTotalKRW: Decimal {
            paidLines.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) }
        }

        public var unpaidTotalKRW: Decimal {
            unpaidLines.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) }
        }

        public var grandTotalKRW: Decimal {
            lines.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) }
        }

        public var grandCurrencyTotals: [CurrencyTotal] { currencyTotals(for: lines) }
        public var paidCurrencyTotals: [CurrencyTotal] { currencyTotals(for: paidLines) }
        public var unpaidCurrencyTotals: [CurrencyTotal] { currencyTotals(for: unpaidLines) }

        public var linesMissingKRWConversion: [BudgetLine] {
            lines.filter { $0.costAmount != nil && $0.costAmountKRW == nil }
        }

        public struct AppliedExchangeRate: Identifiable, Equatable {
            public var currency: String
            public var rate: Decimal
            public var id: String { currency }
        }

        public var appliedExchangeRates: [AppliedExchangeRate] {
            let grouped = Dictionary(
                grouping: lines.filter {
                    ($0.costCurrency?.uppercased() ?? "KRW") != "KRW"
                        && $0.costAmount != nil && $0.costAmount != 0
                        && $0.costAmountKRW != nil
                },
                by: { $0.costCurrency! }
            )
            return grouped
                .compactMap { currency, lines -> AppliedExchangeRate? in
                    let totalForeign = lines.reduce(Decimal(0)) { $0 + ($1.costAmount ?? 0) }
                    let totalKRW = lines.reduce(Decimal(0)) { $0 + ($1.costAmountKRW ?? 0) }
                    guard totalForeign != 0 else { return nil }
                    return AppliedExchangeRate(currency: currency, rate: totalKRW / totalForeign)
                }
                .sorted { $0.currency < $1.currency }
        }
    }

    public enum Action {
        case onAppear
        case itemsResponse(Result<[ItineraryItem], any Error>)
        case entriesResponse(Result<[BudgetEntry], any Error>)
        case daysResponse(Result<[TripDay], any Error>)
        case entrySaved(BudgetEntry)
        case deleteEntryButtonTapped(BudgetEntry.ID)
        case deleteEntryResponse(Result<BudgetEntry.ID, any Error>)
        case setSortMode(State.SortMode)
        case editItemTapped(ItineraryItem)
        case addItemFlowRequestConsumed
        case itemUpdated(ItineraryItem)
    }

    @Dependency(\.itineraryRepository) var itineraryRepository
    @Dependency(\.budgetEntryRepository) var budgetEntryRepository
    @Dependency(\.tripsRepository) var tripsRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                let tripID = state.trip.id
                return .merge(
                    .run { send in
                        do {
                            let items = try await itineraryRepository.fetchAllItems(tripID)
                            await send(.itemsResponse(.success(items)))
                        } catch {
                            await send(.itemsResponse(.failure(error)))
                        }
                    },
                    .run { send in
                        do {
                            let entries = try await budgetEntryRepository.fetchAllEntries(tripID)
                            await send(.entriesResponse(.success(entries)))
                        } catch {
                            await send(.entriesResponse(.failure(error)))
                        }
                    },
                    .run { send in
                        do {
                            let days = try await tripsRepository.fetchDays(tripID)
                            await send(.daysResponse(.success(days)))
                        } catch {
                            await send(.daysResponse(.failure(error)))
                        }
                    }
                )

            case let .itemsResponse(.success(items)):
                state.isLoading = false
                state.items = IdentifiedArrayOf(uniqueElements: items)
                syncTripCurrencies(tripID: state.trip.id, usedCurrencies: items.compactMap(\.costCurrency))
                return .none

            case let .itemsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .entriesResponse(.success(entries)):
                state.entries = IdentifiedArrayOf(uniqueElements: entries)
                syncTripCurrencies(tripID: state.trip.id, usedCurrencies: entries.compactMap(\.costCurrency))
                return .none

            case let .entriesResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .daysResponse(.success(days)):
                state.days = IdentifiedArrayOf(uniqueElements: days)
                return .none

            case let .daysResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .entrySaved(entry):
                state.entries[id: entry.id] = entry
                return .none

            case let .deleteEntryButtonTapped(id):
                state.entries.remove(id: id)
                return .run { send in
                    do {
                        try await budgetEntryRepository.deleteEntry(id)
                        await send(.deleteEntryResponse(.success(id)))
                    } catch {
                        await send(.deleteEntryResponse(.failure(error)))
                    }
                }

            case .deleteEntryResponse(.success):
                return .none

            case let .deleteEntryResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .setSortMode(mode):
                state.sortMode = mode
                return .none

            case let .editItemTapped(item):
                guard let day = state.days[id: item.dayId] else { return .none }
                state.addItemFlowRequest = AddItemFlowFeature.State(editingItem: item, trip: state.trip, day: day)
                return .none

            case .addItemFlowRequestConsumed:
                state.addItemFlowRequest = nil
                return .none

            case let .itemUpdated(item):
                state.items[id: item.id] = item
                if let currency = item.costCurrency {
                    syncTripCurrencies(tripID: state.trip.id, usedCurrencies: [currency])
                }
                return .none
            }
        }
    }

    private func syncTripCurrencies(tripID: Trip.ID, usedCurrencies: [String]) {
        let existing = TripCurrencyStore.read(tripID: tripID)
        let existingUppercased = Set((["KRW"] + existing).map { $0.uppercased() })
        var seen = Set<String>()
        var toAdd: [String] = []
        for currency in usedCurrencies {
            let uppercased = currency.uppercased()
            guard !existingUppercased.contains(uppercased), !seen.contains(uppercased) else { continue }
            seen.insert(uppercased)
            toAdd.append(currency)
        }
        guard !toAdd.isEmpty else { return }
        TripCurrencyStore.save(tripID: tripID, currencies: existing + toAdd)
    }
}
