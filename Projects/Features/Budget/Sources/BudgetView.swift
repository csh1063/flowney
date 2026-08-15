import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct BudgetView: View {
    @Bindable var store: StoreOf<BudgetFeature>

    public init(store: StoreOf<BudgetFeature>) {
        self.store = store
    }

    public var body: some View {
        List {
            Section("총 합계") {
                VStack(spacing: WaypinSpacing.sm) {
                    summaryRow(title: "전체", amount: store.grandTotalKRW)
                    summaryRow(title: "결제완료", amount: store.paidTotalKRW)
                    summaryRow(title: "미결제", amount: store.unpaidTotalKRW)
                }
                .waypinCard()
                .waypinCardListRow()
            }

            if !store.groupedByCategory.isEmpty {
                Section("카테고리별") {
                    VStack(spacing: WaypinSpacing.sm) {
                        ForEach(store.groupedByCategory) { group in
                            HStack {
                                Text(group.category.displayName)
                                    .font(WaypinFont.body)
                                Spacer()
                                Text("\(group.items.count)건")
                                    .font(WaypinFont.caption)
                                    .foregroundStyle(WaypinTheme.textSecondary)
                                Text(formatted(group.totalKRW))
                                    .font(WaypinFont.numeric)
                            }
                        }
                    }
                    .waypinCard()
                    .waypinCardListRow()
                }
            }

            if !store.unpaidItems.isEmpty {
                Section("🔜 결제해야 하는 것") {
                    ForEach(store.unpaidItems) { item in
                        itemRow(item)
                            .waypinCard()
                            .waypinCardListRow()
                    }
                }
            }

            if !store.paidItems.isEmpty {
                Section("✅ 결제완료") {
                    ForEach(store.paidItems) { item in
                        itemRow(item)
                            .waypinCard()
                            .waypinCardListRow()
                    }
                }
            }

            if !store.itemsMissingKRWConversion.isEmpty {
                Section {
                    Text("원화 환산 금액이 없는 항목 \(store.itemsMissingKRWConversion.count)건은 합계에서 빠져있어요. 일정 편집에서 채워주세요.")
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
        .waypinLeadingTitle("\(store.trip.name) 요금표")
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
        .onAppear { store.send(.onAppear) }
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

    private func itemRow(_ item: ItineraryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: WaypinSpacing.xs) {
                Text(item.name)
                    .font(WaypinFont.bodyEmphasis)
                if let status = item.paymentStatus {
                    StatusPill(text: status.displayName, color: status.pillColor)
                }
            }
            Spacer()
            if let amount = item.costAmount {
                let priceText: String = "\(amount)\(item.costCurrency ?? "")"
                VStack(alignment: .trailing, spacing: WaypinSpacing.xs) {
                    Text(priceText)
                        .font(WaypinFont.numeric)
                    if let krw = item.costAmountKRW {
                        Text(formatted(krw))
                            .font(WaypinFont.caption)
                            .foregroundStyle(WaypinTheme.textSecondary)
                    }
                }
            }
        }
    }

    private func formatted(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let text = formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
        return "₩\(text)"
    }
}
