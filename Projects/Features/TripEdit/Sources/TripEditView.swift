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
            Form {
                Section("여행 이름") {
                    TextField("예: 유럽 배낭여행", text: $store.name)
                }

                Section("여행 기간") {
                    DatePicker("시작일", selection: $store.startDate, displayedComponents: .date)
                    DatePicker("종료일", selection: $store.endDate, displayedComponents: .date)
                }

                Section("나라 선택") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
                        ForEach(CountryCatalog.all) { country in
                            countryChip(country)
                        }
                    }
                    .padding(.vertical, 4)
                }

                if let errorMessage = store.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
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

    private func countryChip(_ country: CountryOption) -> some View {
        let isSelected = store.selectedCountryCodes.contains(country.code)
        return Button {
            store.send(.countryToggled(country.code))
        } label: {
            Text(country.name)
                .font(.footnote)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color(hex: country.defaultColorHex) : Color.gray.opacity(0.15))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
