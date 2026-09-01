import SwiftUI

public struct CurrencyManagementView: View {
    let currentCurrencies: [String]
    let onApply: ([String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selected: Set<String>

    public init(currentCurrencies: [String], onApply: @escaping ([String]) -> Void) {
        self.currentCurrencies = currentCurrencies
        self.onApply = onApply
        _selected = State(initialValue: Set(currentCurrencies))
    }

    private var catalog: [CurrencyOption] {
        CurrencyCatalog.all.filter { $0.code != "KRW" }
    }

    private var filteredCatalog: [CurrencyOption] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return catalog }
        let uppercasedQuery = trimmed.uppercased()
        return catalog.filter {
            $0.code.contains(uppercasedQuery) || $0.name.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var orderedSelectedCurrencies: [String] {
        currentCurrencies.filter { selected.contains($0) }
            + catalog.map(\.code).filter { selected.contains($0) && !currentCurrencies.contains($0) }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                selectedSummaryRow

                List(filteredCatalog) { currency in
                    Button {
                        toggle(currency.code)
                    } label: {
                        HStack(spacing: WaypinSpacing.sm) {
                            Text(currency.code)
                                .font(WaypinFont.bodyEmphasis)
                                .foregroundStyle(WaypinTheme.textPrimary)
                            Text(currency.name)
                                .font(WaypinFont.caption)
                                .foregroundStyle(WaypinTheme.textSecondary)
                            Spacer()
                            if selected.contains(currency.code) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(WaypinTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(WaypinTheme.surface)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(WaypinTheme.background)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "통화 검색")
            .navigationTitle("통화 관리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("적용") {
                        onApply(orderedSelectedCurrencies)
                        dismiss()
                    }
                }
            }
        }
    }

    private func toggle(_ code: String) {
        if selected.contains(code) {
            selected.remove(code)
        } else {
            selected.insert(code)
        }
    }

    private var selectedSummaryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: WaypinSpacing.sm) {
                pill(code: "KRW", removable: false)
                ForEach(orderedSelectedCurrencies, id: \.self) { code in
                    pill(code: code, removable: true)
                }
            }
            .padding(WaypinSpacing.lg)
        }
        .background(WaypinTheme.surface)
    }

    private func pill(code: String, removable: Bool) -> some View {
        Button {
            if removable { toggle(code) }
        } label: {
            HStack(spacing: WaypinSpacing.xs) {
                Text(code)
                    .font(WaypinFont.caption.weight(.semibold))
                if removable {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
            }
            .padding(.horizontal, WaypinSpacing.md)
            .padding(.vertical, WaypinSpacing.xs)
            .background(WaypinTheme.accent, in: Capsule())
            .foregroundStyle(WaypinTheme.accentLabel)
        }
        .buttonStyle(.plain)
        .disabled(!removable)
    }
}
