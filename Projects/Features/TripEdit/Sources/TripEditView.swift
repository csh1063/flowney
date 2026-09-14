import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct TripEditView: View {
    @Bindable var store: StoreOf<TripEditFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var isCalendarExpanded = false
    @State private var colorSelections: [TripCountry.ID: Color] = [:]
    @State private var colorPickerCountry: TripCountry?
    @FocusState private var focusedField: Field?

    private let localCountries: [TripCountry]

    private enum Field: Hashable {
        case name
    }

    public init(store: StoreOf<TripEditFeature>) {
        self.store = store
        _isCalendarExpanded = State(initialValue: !store.isEditing)
        localCountries = Array(store.countries)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FlowneySpacing.lg) {
                    sectionBlock("여행 이름") {
                        TextField("예: 유럽 배낭여행", text: $store.name)
                            .focused($focusedField, equals: .name)
                    }

                    sectionBlock("여행 기간") {
                        VStack(alignment: .leading, spacing: FlowneySpacing.sm) {
                            Button {
                                isCalendarExpanded.toggle()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
                                        Text(dateRangeText)
                                            .font(FlowneyFont.bodyEmphasis)
                                            .foregroundStyle(FlowneyTheme.textPrimary)
                                        Text(nightsText)
                                            .font(FlowneyFont.caption)
                                            .foregroundStyle(FlowneyTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: isCalendarExpanded ? "chevron.up" : "chevron.down")
                                        .foregroundStyle(FlowneyTheme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)

                            if isCalendarExpanded {
                                FlowneyDateRangeCalendarView(startDate: $store.startDate, endDate: $store.endDate)
                            }
                        }
                    }

                    if !localCountries.isEmpty {
                        sectionBlock("나라별 색") {
                            VStack(spacing: FlowneySpacing.sm) {
                                ForEach(localCountries) { country in
                                    countryColorRow(country)
                                }
                            }
                        }
                    }

                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(FlowneyFont.caption)
                            .foregroundStyle(FlowneyTheme.error)
                            .flowneyCard()
                    }
                }
                .padding(FlowneySpacing.lg)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(FlowneyTheme.background)
            .navigationTitle(store.isEditing ? "여행 수정" : "새 여행")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        store.send(.cancelButtonTapped)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if store.isSaving {
                        ProgressView()
                    } else {
                        Button("저장") {
                            let merged = localCountries.map { country -> TripCountry in
                                var updated = country
                                if let color = colorSelections[country.id] {
                                    updated.color = color.toHexString()
                                }
                                return updated
                            }
                            store.send(.binding(.set(\.countries, IdentifiedArrayOf(uniqueElements: merged))))
                            store.send(.saveButtonTapped)
                        }
                    }
                }
            }
            .flowneyLifecycleLog(category: .tripEdit)
            .sheet(item: $colorPickerCountry) { country in
                CountryColorPickerSheet(
                    countryCode: country.countryCode,
                    initialColorHex: (colorSelections[country.id] ?? Color(hex: country.color)).toHexString(),
                    onConfirm: { colorSelections[country.id] = $0 },
                    onReset: { colorSelections[country.id] = Color(hex: CountryCatalog.option(for: country.countryCode)?.defaultColorHex ?? FlowneyTheme.brandNavyHex) }
                )
            }
        }
    }

    private static let dateRangeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private var dateRangeText: String {
        let start = Self.dateRangeFormatter.string(from: store.startDate)
        let end = Self.dateRangeFormatter.string(from: store.endDate)
        return "\(start) — \(end)"
    }

    private var nightsText: String {
        let calendar = Calendar(identifier: .gregorian)
        let nights = max(
            0,
            calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: store.startDate),
                to: calendar.startOfDay(for: store.endDate)
            ).day ?? 0
        )
        return "\(nights)박\(nights + 1)일"
    }

    private func sectionBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FlowneySpacing.sm) {
            Text(title)
                .font(FlowneyFont.sectionHeader)
                .foregroundStyle(FlowneyTheme.textSecondary)
            content()
        }
        .flowneyCard()
    }

    private func countryColorRow(_ country: TripCountry) -> some View {
        Button {
            colorPickerCountry = country
        } label: {
            HStack(spacing: FlowneySpacing.sm) {
                Text(CountryCatalog.flagEmoji(for: country.countryCode))
                    .font(.system(size: 22))
                Text(CountryCatalog.option(for: country.countryCode)?.name ?? country.countryCode)
                    .font(FlowneyFont.body)
                    .foregroundStyle(FlowneyTheme.textPrimary)
                Spacer()
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(colorSelections[country.id] ?? Color(hex: country.color))
                    .frame(width: 40, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(FlowneyTheme.divider, lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
        .frame(minHeight: 40)
    }
}
