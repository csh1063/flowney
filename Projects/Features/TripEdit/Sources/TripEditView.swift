import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct TripEditView: View {
    @Bindable var store: StoreOf<TripEditFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var isCalendarExpanded = false
    @State private var countrySearchText = ""
    @State private var debouncedCountrySearchText = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case countrySearch
    }

    public init(store: StoreOf<TripEditFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WaypinSpacing.lg) {
                    sectionBlock("여행 이름") {
                        TextField("예: 유럽 배낭여행", text: $store.name)
                            .focused($focusedField, equals: .name)
                    }

                    sectionBlock("여행 기간") {
                        VStack(alignment: .leading, spacing: WaypinSpacing.sm) {
                            Button {
                                isCalendarExpanded.toggle()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: WaypinSpacing.xs) {
                                        Text(dateRangeText)
                                            .font(WaypinFont.bodyEmphasis)
                                            .foregroundStyle(WaypinTheme.textPrimary)
                                        Text(nightsText)
                                            .font(WaypinFont.caption)
                                            .foregroundStyle(WaypinTheme.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: isCalendarExpanded ? "chevron.up" : "chevron.down")
                                        .foregroundStyle(WaypinTheme.textSecondary)
                                }
                            }
                            .buttonStyle(.plain)

                            if isCalendarExpanded {
                                WaypinDateRangeCalendarView(startDate: $store.startDate, endDate: $store.endDate)
                            }
                        }
                    }

                    sectionBlock("나라 선택") {
                        VStack(alignment: .leading, spacing: WaypinSpacing.sm) {
                            TextField("나라 검색", text: $countrySearchText)
                                .focused($focusedField, equals: .countrySearch)
                                .task(id: countrySearchText) {
                                    try? await Task.sleep(for: .milliseconds(300))
                                    guard !Task.isCancelled else { return }
                                    debouncedCountrySearchText = countrySearchText
                                }

                            if filteredCountries.isEmpty {
                                Text("검색 결과가 없어요")
                                    .font(WaypinFont.caption)
                                    .foregroundStyle(WaypinTheme.textSecondary)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: WaypinSpacing.sm) {
                                    ForEach(filteredCountries) { country in
                                        countryChip(country)
                                    }
                                }
                            }
                        }
                    }

                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(WaypinFont.caption)
                            .foregroundStyle(WaypinTheme.error)
                            .waypinCard()
                    }
                }
                .padding(WaypinSpacing.lg)
            }
            .simultaneousGesture(TapGesture().onEnded { focusedField = nil })
            .background(WaypinTheme.background)
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
                        Button("저장") { store.send(.saveButtonTapped) }
                    }
                }
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

    private var sortedCountries: [CountryOption] {
        CountryCatalog.all.sorted { a, b in
            if a.code == "KR" { return true }
            if b.code == "KR" { return false }
            return a.name.localizedCompare(b.name) == .orderedAscending
        }
    }

    private var filteredCountries: [CountryOption] {
        let query = debouncedCountrySearchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return sortedCountries }
        return sortedCountries.filter { CountrySearchMatcher.matches(query: query, name: $0.name) }
    }

    private func sectionBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: WaypinSpacing.sm) {
            Text(title)
                .font(WaypinFont.sectionHeader)
                .foregroundStyle(WaypinTheme.textSecondary)
            content()
        }
        .waypinCard()
    }

    private func countryChip(_ country: CountryOption) -> some View {
        let isSelected = store.selectedCountryCodes.contains(country.code)
        return Button {
            store.send(.countryToggled(country.code))
        } label: {
            VStack(spacing: WaypinSpacing.xs) {
                Text(CountryCatalog.flagEmoji(for: country.code))
                    .font(.system(size: isSelected ? 44 : 22))
                Text(country.name)
                    .font(WaypinFont.caption.weight(isSelected ? .semibold : .regular))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(WaypinTheme.textPrimary)
            .padding(.horizontal, WaypinSpacing.xs)
            .frame(maxWidth: .infinity)
            .frame(height: 84)
            .background(WaypinTheme.divider)
            .clipShape(RoundedRectangle(cornerRadius: WaypinRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: WaypinRadius.sm)
                    .strokeBorder(WaypinTheme.accent, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(.plain)
    }
}
