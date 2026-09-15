import APIClient
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct AddBudgetEntryView: View {
    @Bindable var store: StoreOf<AddBudgetEntryFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var isCalendarExpanded = false
    @State private var isItemPickerPresented = false
    @State private var isCurrencyManagementPresented = false
    @State private var tripCurrencies: [String] = []

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    public init(store: StoreOf<AddBudgetEntryFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("예: 여행자보험", text: $store.name)
                }

                Section("날짜 / 일정") {
                    if let linkedItem = store.linkedItem {
                        HStack {
                            VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
                                Text("연결된 일정")
                                    .font(FlowneyFont.caption)
                                    .foregroundStyle(FlowneyTheme.textSecondary)
                                Text(linkedItem.name)
                                    .font(FlowneyFont.bodyEmphasis)
                            }
                            Spacer()
                            Button("취소") { store.send(.linkedItemCleared) }
                        }
                    } else if let date = store.date {
                        HStack {
                            Text(Self.dateFormatter.string(from: date))
                                .font(FlowneyFont.bodyEmphasis)
                            Spacer()
                            Button("취소") { store.send(.dateCleared) }
                        }
                    } else {
                        DisclosureGroup("날짜 선택", isExpanded: $isCalendarExpanded) {
                            FlowneyTripDayCalendarView(days: Array(store.days), selectedDayID: nil) { day in
                                store.send(.dateSelected(day.dayDate))
                                isCalendarExpanded = false
                            }
                            .frame(height: 320)
                            .padding(.top, FlowneySpacing.sm)
                        }
                        Button("일정에서 선택") { isItemPickerPresented = true }
                    }
                }

                Section("비용") {
                    CostInputSection(
                        tripCurrencies: tripCurrencies,
                        costAmountText: $store.costAmountText,
                        costCurrency: $store.costCurrency,
                        costAmountKRWText: $store.costAmountKRWText,
                        costCategory: $store.costCategory,
                        paymentStatus: $store.paymentStatus,
                        onManageCurrenciesTapped: { isCurrencyManagementPresented = true }
                    )
                }

                Section("메모") {
                    TextField("메모", text: $store.notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if let errorMessage = store.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(FlowneyTheme.error)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(FlowneyTheme.background)
            .navigationTitle(store.editingOriginalEntry == nil ? "예산 추가" : "예산 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if store.isSaving {
                        ProgressView()
                    } else {
                        Button("저장") { store.send(.saveButtonTapped) }
                    }
                }
            }
            .onAppear { tripCurrencies = TripCurrencyStore.read(tripID: store.tripID) }
            .onChange(of: store.savedEntry) { _, savedEntry in
                guard let currency = savedEntry?.costCurrency, currency.uppercased() != "KRW" else { return }
                guard !tripCurrencies.contains(where: { $0.uppercased() == currency.uppercased() }) else { return }
                tripCurrencies.append(currency)
                TripCurrencyStore.save(tripID: store.tripID, currencies: tripCurrencies)
            }
            .sheet(isPresented: $isItemPickerPresented) {
                BudgetLinkItemPickerView(items: Array(store.items), days: store.days) { item in
                    store.send(.linkedItemSelected(item.id))
                }
            }
        }
        .sheet(isPresented: $isCurrencyManagementPresented) {
            CurrencyManagementView(currentCurrencies: tripCurrencies) { finalCurrencies in
                TripCurrencyStore.save(tripID: store.tripID, currencies: finalCurrencies)
                tripCurrencies = finalCurrencies
                let stillValid = (["KRW"] + finalCurrencies).contains { $0.uppercased() == store.costCurrency.uppercased() }
                if !stillValid {
                    store.costCurrency = "KRW"
                }
            }
        }
    }
}
