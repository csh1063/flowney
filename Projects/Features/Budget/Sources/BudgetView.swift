import AddItem
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct BudgetView: View {
    @Bindable var store: StoreOf<BudgetFeature>
    @State private var addEntryStore: StoreOf<AddBudgetEntryFeature>?
    @State private var addItemFlowStore: StoreOf<AddItemFlowFeature>?

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    public init(store: StoreOf<BudgetFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("총 합계") {
                VStack(spacing: WaypinSpacing.md) {
                    WaypinExpandableRow {
                        summaryRow(title: "전체", amount: store.grandTotalKRW)
                    } content: {
                        currencyBreakdownRows(store.grandCurrencyTotals)
                    }
                    WaypinExpandableRow {
                        summaryRow(title: "결제완료", amount: store.paidTotalKRW)
                    } content: {
                        currencyBreakdownRows(store.paidCurrencyTotals)
                    }
                    WaypinExpandableRow {
                        summaryRow(title: "미결제", amount: store.unpaidTotalKRW)
                    } content: {
                        currencyBreakdownRows(store.unpaidCurrencyTotals)
                    }
                }
                .waypinCard()
                .waypinCardListRow()
            }

            if !store.groupedByCategory.isEmpty {
                Section("카테고리별") {
                    VStack(spacing: WaypinSpacing.md) {
                        ForEach(store.groupedByCategory) { group in
                            WaypinExpandableRow {
                                HStack {
                                    Text(group.category.displayName)
                                        .font(WaypinFont.body)
                                    Spacer()
                                    Text("\(group.lines.count)건")
                                        .font(WaypinFont.caption)
                                        .foregroundStyle(WaypinTheme.textSecondary)
                                    Text(formatted(group.totalKRW))
                                        .font(WaypinFont.numeric)
                                }
                            } content: {
                                currencyBreakdownRows(group.currencyTotals)
                            }
                        }
                    }
                    .waypinCard()
                    .waypinCardListRow()
                }
            }

            if !store.appliedExchangeRates.isEmpty {
                Section("적용 환율") {
                    VStack(spacing: WaypinSpacing.sm) {
                        ForEach(store.appliedExchangeRates) { rate in
                            HStack {
                                Text(rate.currency)
                                    .font(WaypinFont.body)
                                Spacer()
                                Text("1 \(rate.currency) ≈ ₩ \(formattedAmount(rate.rate, maximumFractionDigits: 2))")
                                    .font(WaypinFont.numeric)
                                    .foregroundStyle(WaypinTheme.textSecondary)
                            }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .waypinCard()
                    .waypinCardListRow()
                }
                .listSectionSpacing(.custom(WaypinSpacing.xl))
            }

            Section {
                WaypinSegmentedControl(
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
                                .waypinCardListRow()
                        }
                    }
                }
            } else if store.sortMode == .byCategory {
                ForEach(store.linesGroupedByCategory) { group in
                    Section(group.category?.displayName ?? "미분류") {
                        ForEach(group.lines) { line in
                            lineRow(line)
                                .waypinCardListRow()
                        }
                    }
                }
            } else {
                if !store.unpaidLines.isEmpty {
                    Section("🔜 결제해야 하는 것") {
                        ForEach(store.unpaidLines) { line in
                            lineRow(line)
                                .waypinCardListRow()
                        }
                    }
                }

                if !store.paidLines.isEmpty {
                    Section("✅ 결제완료") {
                        ForEach(store.paidLines) { line in
                            lineRow(line)
                                .waypinCardListRow()
                        }
                    }
                }
            }

            if !store.linesMissingKRWConversion.isEmpty {
                Section {
                    Text("원화 환산 금액이 없는 항목 \(store.linesMissingKRWConversion.count)건은 합계에서 빠져있어요.")
                        .font(WaypinFont.caption)
                        .foregroundStyle(WaypinTheme.textSecondary)
                        .waypinCard()
                        .waypinCardListRow()
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(WaypinTheme.background)
        .waypinLeadingTitle(store.trip.name)
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
        }
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
        .onAppear { store.send(.onAppear) }
        .onChange(of: store.addItemFlowRequest) { _, request in
            guard let request else { return }
            addItemFlowStore = Store(initialState: request) { AddItemFlowFeature() }
            store.send(.addItemFlowRequestConsumed)
        }
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
        .sheet(
            isPresented: Binding(
                get: { addItemFlowStore != nil },
                set: { isPresented in
                    if !isPresented { addItemFlowStore = nil }
                }
            )
        ) {
            if let addItemFlowStore {
                AddItemFlowView(
                    store: addItemFlowStore,
                    onItemAdded: { item in
                        store.send(.itemUpdated(item))
                        self.addItemFlowStore = nil
                    },
                    onCancelled: { self.addItemFlowStore = nil }
                )
            }
        }
    }

    private func summaryRow(title: String, amount: Decimal) -> some View {
        HStack {
            Text(title)
                .font(WaypinFont.body)
            Spacer()
            Text(formatted(amount))
                .font(WaypinFont.numeric)
        }
    }

    @ViewBuilder
    private func currencyBreakdownRows(_ totals: [BudgetFeature.State.CurrencyTotal]) -> some View {
        if totals.isEmpty {
            Text("통화별 내역이 없어요")
                .font(WaypinFont.caption)
                .foregroundStyle(WaypinTheme.textSecondary)
        } else {
            ForEach(totals) { total in
                HStack {
                    Spacer()
                    Text(amountText(total.total, currency: total.currency))
                        .font(WaypinFont.numeric)
                }
            }
        }
    }

    @ViewBuilder
    private func lineRow(_ line: BudgetFeature.State.BudgetLine) -> some View {
        switch line {
        case let .item(item):
            Button {
                store.send(.editItemTapped(item))
            } label: {
                lineRowContent(line)
                    .waypinCard()
            }
            .buttonStyle(.plain)

        case let .entry(entry):
            SwipeToDeleteCard(
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
                lineRowContent(line)
                    .waypinCard(corners: .leadingOnly)
            }
        }
    }

    private func lineRowContent(_ line: BudgetFeature.State.BudgetLine) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: WaypinSpacing.xs) {
                HStack(spacing: WaypinSpacing.xs) {
                    if case .entry = line {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundStyle(WaypinTheme.textSecondary)
                    }
                    Text(line.name)
                        .font(WaypinFont.bodyEmphasis)
                    if let date = store.state.date(for: line) {
                        Text(Self.dateFormatter.string(from: date))
                            .font(WaypinFont.caption)
                            .foregroundStyle(WaypinTheme.textSecondary)
                    }
                }
                if let status = line.paymentStatus {
                    StatusPill(text: status.displayName, color: status.pillColor)
                }
            }
            Spacer()
            if let amount = line.costAmount {
                let isKRW = (line.costCurrency ?? "").uppercased() == "KRW"
                VStack(alignment: .trailing, spacing: WaypinSpacing.xs) {
                    Text(amountText(amount, currency: line.costCurrency ?? ""))
                        .font(WaypinFont.numeric)
                    if !isKRW, let krw = line.costAmountKRW {
                        Text(formatted(krw))
                            .font(WaypinFont.caption)
                            .foregroundStyle(WaypinTheme.textSecondary)
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
