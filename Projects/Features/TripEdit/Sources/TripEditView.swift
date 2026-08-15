import ComposableArchitecture
import DesignSystem
import SwiftUI

public struct TripEditView: View {
    @Bindable var store: StoreOf<TripEditFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<TripEditFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: WaypinSpacing.lg) {
                    sectionBlock("여행 이름") {
                        TextField("예: 유럽 배낭여행", text: $store.name)
                    }

                    sectionBlock("여행 기간") {
                        VStack(spacing: WaypinSpacing.sm) {
                            DatePicker("시작일", selection: $store.startDate, displayedComponents: .date)
                            DatePicker("종료일", selection: $store.endDate, displayedComponents: .date)
                        }
                    }

                    sectionBlock("나라 선택") {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: WaypinSpacing.sm) {
                            ForEach(CountryCatalog.all) { country in
                                countryChip(country)
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
            Text(country.name)
                .font(WaypinFont.caption)
                .padding(.horizontal, WaypinSpacing.sm)
                .padding(.vertical, WaypinSpacing.xs)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color(hex: country.defaultColorHex) : WaypinTheme.divider)
                .foregroundStyle(isSelected ? .white : WaypinTheme.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: WaypinRadius.sm))
        }
        .buttonStyle(.plain)
    }
}
