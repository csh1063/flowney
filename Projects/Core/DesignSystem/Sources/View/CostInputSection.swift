import Models
import SwiftUI

public struct CostInputSection: View {
    let tripCurrencies: [String]
    let onManageCurrenciesTapped: () -> Void

    @Binding var costAmountText: String
    @Binding var costCurrency: String
    @Binding var costAmountKRWText: String
    @Binding var costCategory: CostCategory?
    @Binding var paymentStatus: PaymentStatus?

    public init(
        tripCurrencies: [String],
        costAmountText: Binding<String>,
        costCurrency: Binding<String>,
        costAmountKRWText: Binding<String>,
        costCategory: Binding<CostCategory?>,
        paymentStatus: Binding<PaymentStatus?>,
        onManageCurrenciesTapped: @escaping () -> Void
    ) {
        self.tripCurrencies = tripCurrencies
        self.onManageCurrenciesTapped = onManageCurrenciesTapped
        _costAmountText = costAmountText
        _costCurrency = costCurrency
        _costAmountKRWText = costAmountKRWText
        _costCategory = costCategory
        _paymentStatus = paymentStatus
    }

    private var displayedCurrencies: [String] {
        var result = ["KRW"] + tripCurrencies.filter { $0 != "KRW" }
        if !result.contains(where: { $0.uppercased() == costCurrency.uppercased() }) {
            result.append(costCurrency)
        }
        return result
    }

    public var body: some View {
        Group {
            HStack {
                TextField("금액", text: $costAmountText)
                    .keyboardType(.decimalPad)
                currencyMenu
            }

            if costCurrency.uppercased() != "KRW" && !costAmountText.isEmpty {
                TextField("원화 환산 금액 (선택 — 합계에 쓰여요)", text: $costAmountKRWText)
                    .keyboardType(.decimalPad)
            }

            Picker("카테고리", selection: $costCategory) {
                Text("선택 안 함").tag(CostCategory?.none)
                ForEach(CostCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(CostCategory?.some(category))
                }
            }
            .pickerStyle(.menu)

            Picker("결제 상태", selection: $paymentStatus) {
                Text("선택 안 함").tag(PaymentStatus?.none)
                ForEach(PaymentStatus.allCases, id: \.self) { status in
                    Text(status.displayName).tag(PaymentStatus?.some(status))
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var currencyMenu: some View {
        Menu {
            ForEach(displayedCurrencies, id: \.self) { currency in
                Button {
                    costCurrency = currency
                } label: {
                    if currency.uppercased() == costCurrency.uppercased() {
                        Label(currency, systemImage: "checkmark")
                    } else {
                        Text(currency)
                    }
                }
            }
            Button {
                onManageCurrenciesTapped()
            } label: {
                Label("통화 관리", systemImage: "slider.horizontal.3")
            }
        } label: {
            HStack(spacing: FlowneySpacing.xs) {
                Text(costCurrency)
                    .font(FlowneyFont.bodyEmphasis)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(FlowneyTheme.textPrimary)
            .padding(.horizontal, FlowneySpacing.sm)
            .padding(.vertical, FlowneySpacing.xs)
            .background(FlowneyTheme.divider, in: Capsule())
        }
    }
}
