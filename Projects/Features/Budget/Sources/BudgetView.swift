import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

public struct BudgetView: View {
    @Bindable var store: StoreOf<BudgetFeature>
    let onTripListRequested: () -> Void
    @State private var addEntryStore: StoreOf<AddBudgetEntryFeature>?
    @State private var revealedRowID: AnyHashable?

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    public init(store: StoreOf<BudgetFeature>, onTripListRequested: @escaping () -> Void) {
        self.store = store
        self.onTripListRequested = onTripListRequested
    }

    public var body: some View {
        List {
            Section("총 합계") {
                VStack(spacing: FlowneySpacing.md) {
                    FlowneyExpandableRow {
                        summaryRow(title: "전체", amount: store.grandTotalKRW)
                    } content: {
                        currencyBreakdownRows(store.grandCurrencyTotals)
                    }
                    FlowneyExpandableRow {
                        summaryRow(title: "결제완료", amount: store.paidTotalKRW)
                    } content: {
                        currencyBreakdownRows(store.paidCurrencyTotals)
                    }
                    FlowneyExpandableRow {
                        summaryRow(title: "미결제", amount: store.unpaidTotalKRW)
                    } content: {
                        currencyBreakdownRows(store.unpaidCurrencyTotals)
                    }
                }
                .flowneyCard()
                .flowneyCardListRow()
            }

            if !store.groupedByCategory.isEmpty {
                Section("카테고리별") {
                    VStack(spacing: FlowneySpacing.md) {
                        ForEach(store.groupedByCategory) { group in
                            FlowneyExpandableRow {
                                HStack {
                                    Text(group.category.displayName)
                                        .font(FlowneyFont.body)
                                    Spacer()
                                    Text("\(group.lines.count)건")
                                        .font(FlowneyFont.caption)
                                        .foregroundStyle(FlowneyTheme.textSecondary)
                                    Text(formatted(group.totalKRW))
                                        .font(FlowneyFont.numeric)
                                }
                            } content: {
                                currencyBreakdownRows(group.currencyTotals)
                            }
                        }
                    }
                    .flowneyCard()
                    .flowneyCardListRow()
                }
            }

            if !store.appliedExchangeRates.isEmpty {
                Section("적용 환율") {
                    VStack(spacing: FlowneySpacing.sm) {
                        ForEach(store.appliedExchangeRates) { rate in
                            HStack {
                                Text(rate.currency)
                                    .font(FlowneyFont.body)
                                Spacer()
                                Text("1 \(rate.currency) ≈ ₩ \(formattedAmount(rate.rate, maximumFractionDigits: 2))")
                                    .font(FlowneyFont.numeric)
                                    .foregroundStyle(FlowneyTheme.textSecondary)
                            }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .flowneyCard()
                    .flowneyCardListRow()
                }
                .listSectionSpacing(.custom(FlowneySpacing.xl))
            }

            Section {
                FlowneySegmentedControl(
                    selection: Binding(
                        get: { store.sortMode },
                        set: { store.send(.setSortMode($0)) }
                    ),
                    options: BudgetFeature.State.SortMode.allCases,
                    label: \.displayName
                )
                .listRowBackground(Color.clear)
            }

            if store.sortMode == .byDate {
                ForEach(store.linesGroupedByDate) { group in
                    Section(dateSectionTitle(group.date)) {
                        ForEach(group.lines) { line in
                            lineRow(line)
                                .flowneyCardListRow()
                        }
                    }
                }
            } else if store.sortMode == .byCategory {
                ForEach(store.linesGroupedByCategory) { group in
                    Section(group.category?.displayName ?? "미분류") {
                        ForEach(group.lines) { line in
                            lineRow(line)
                                .flowneyCardListRow()
                        }
                    }
                }
            } else {
                if !store.unpaidLines.isEmpty {
                    Section("🔜 결제해야 하는 것") {
                        ForEach(store.unpaidLines) { line in
                            lineRow(line)
                                .flowneyCardListRow()
                        }
                    }
                }

                if !store.paidLines.isEmpty {
                    Section("✅ 결제완료") {
                        ForEach(store.paidLines) { line in
                            lineRow(line)
                                .flowneyCardListRow()
                        }
                    }
                }
            }

            if !store.linesMissingKRWConversion.isEmpty {
                Section {
                    Text("원화 환산 금액이 없는 항목 \(store.linesMissingKRWConversion.count)건은 합계에서 빠져있어요.")
                        .font(FlowneyFont.caption)
                        .foregroundStyle(FlowneyTheme.textSecondary)
                        .flowneyCard()
                        .flowneyCardListRow()
                }
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 72) }
        .scrollContentBackground(.hidden)
        .background(FlowneyTheme.background)
        .flowneyLeadingTitle(store.trip.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addEntryStore = Store(
                        initialState: AddBudgetEntryFeature.State(tripID: store.trip.id, items: store.items, days: store.days)
                    ) {
                        AddBudgetEntryFeature()
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                TripManagementMenuButton(
                    trip: store.trip,
                    onTripListRequested: onTripListRequested,
                    onTripUpdated: { store.send(.tripUpdated($0)) }
                )
            }
        }
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
        .onAppear { store.send(.onAppear) }
        .sheet(isPresented: Binding(
            get: { addEntryStore != nil },
            set: { if !$0 { addEntryStore = nil } }
        )) {
            if let addEntryStore {
                AddBudgetEntryView(store: addEntryStore)
                    .onChange(of: addEntryStore.savedEntry) { _, savedEntry in
                        if let savedEntry {
                            store.send(.entrySaved(savedEntry))
                        }
                        self.addEntryStore = nil
                    }
            }
        }
        .flowneyLifecycleLog(category: .budget)
    }

    private func summaryRow(title: String, amount: Decimal) -> some View {
        HStack {
            Text(title)
                .font(FlowneyFont.body)
            Spacer()
            Text(formatted(amount))
                .font(FlowneyFont.numeric)
        }
    }

    @ViewBuilder
    private func currencyBreakdownRows(_ totals: [BudgetFeature.State.CurrencyTotal]) -> some View {
        if totals.isEmpty {
            Text("통화별 내역이 없어요")
                .font(FlowneyFont.caption)
                .foregroundStyle(FlowneyTheme.textSecondary)
        } else {
            ForEach(totals) { total in
                HStack {
                    Spacer()
                    Text(amountText(total.total, currency: total.currency))
                        .font(FlowneyFont.numeric)
                }
            }
        }
    }

    @ViewBuilder
    private func lineRow(_ entry: BudgetEntry) -> some View {
        SwipeToDeleteCard(
            id: entry.id,
            revealedID: $revealedRowID,
            onDelete: { store.send(.deleteEntryButtonTapped(entry.id)) },
            onTap: {
                addEntryStore = Store(
                    initialState: AddBudgetEntryFeature.State(
                        editing: entry,
                        items: store.items,
                        days: store.days
                    )
                ) {
                    AddBudgetEntryFeature()
                }
            }
        ) {
            lineRowContent(entry)
                .padding(FlowneySpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func lineRowContent(_ entry: BudgetEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
                HStack(spacing: FlowneySpacing.xs) {
                    if entry.linkedItemId == nil {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                    }
                    Text(entry.name)
                        .font(FlowneyFont.bodyEmphasis)
                    if let date = store.state.date(for: entry) {
                        Text(Self.dateFormatter.string(from: date))
                            .font(FlowneyFont.caption)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                    }
                }
                if let status = entry.paymentStatus {
                    StatusPill(text: status.displayName, color: status.pillColor)
                }
            }
            Spacer()
            if let amount = entry.costAmount {
                let isKRW = (entry.costCurrency ?? "").uppercased() == "KRW"
                VStack(alignment: .trailing, spacing: FlowneySpacing.xs) {
                    Text(amountText(amount, currency: entry.costCurrency ?? ""))
                        .font(FlowneyFont.numeric)
                    if !isKRW, let krw = entry.costAmountKRW {
                        Text(formatted(krw))
                            .font(FlowneyFont.caption)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                    }
                }
            }
        }
    }

    private func formatted(_ amount: Decimal) -> String {
        "₩ \(formattedAmount(amount, maximumFractionDigits: 0))"
    }

    private func amountText(_ amount: Decimal, currency: String) -> String {
        "\(CurrencyCatalog.symbol(for: currency)) \(formattedAmount(amount))"
    }

    private func dateSectionTitle(_ date: Date?) -> String {
        guard let date else { return "미정" }
        return Self.dateFormatter.string(from: date)
    }

    private func formattedAmount(_ amount: Decimal, maximumFractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
