import ComposableArchitecture
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
                summaryRow(title: "전체", amount: store.grandTotalKRW)
                summaryRow(title: "결제완료", amount: store.paidTotalKRW)
                summaryRow(title: "미결제", amount: store.unpaidTotalKRW)
            }

            if !store.groupedByCategory.isEmpty {
                Section("카테고리별") {
                    ForEach(store.groupedByCategory) { group in
                        HStack {
                            Text(group.category.displayName)
                            Spacer()
                            Text("\(group.items.count)건")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(formatted(group.totalKRW))
                                .font(.body.weight(.medium))
                        }
                    }
                }
            }

            if !store.unpaidItems.isEmpty {
                Section("🔜 결제해야 하는 것") {
                    ForEach(store.unpaidItems) { item in
                        itemRow(item)
                    }
                }
            }

            if !store.paidItems.isEmpty {
                Section("✅ 결제완료") {
                    ForEach(store.paidItems) { item in
                        itemRow(item)
                    }
                }
            }

            if !store.itemsMissingKRWConversion.isEmpty {
                Section {
                    Text("원화 환산 금액이 없는 항목 \(store.itemsMissingKRWConversion.count)건은 합계에서 빠져있어요. 일정 편집에서 채워주세요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("\(store.trip.name) 요금표")
        .navigationBarTitleDisplayMode(.inline)
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
            Spacer()
            Text(formatted(amount))
                .font(.body.weight(.semibold))
        }
    }

    private func itemRow(_ item: ItineraryItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                if let status = item.paymentStatus {
                    Text(status.displayName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let amount = item.costAmount {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(amount)\(item.costCurrency ?? "")")
                    if let krw = item.costAmountKRW {
                        Text(formatted(krw))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
