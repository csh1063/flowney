import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

struct BudgetLinkItemPickerView: View {
    let items: [ItineraryItem]
    let days: IdentifiedArrayOf<TripDay>
    let onSelect: (ItineraryItem) -> Void

    @Environment(\.dismiss) private var dismiss

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d (E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private var sortedItems: [ItineraryItem] {
        items.sorted { lhs, rhs in
            let lhsDate = days[id: lhs.dayId]?.dayDate
            let rhsDate = days[id: rhs.dayId]?.dayDate
            if lhsDate == rhsDate { return lhs.sortOrder < rhs.sortOrder }
            guard let lhsDate else { return false }
            guard let rhsDate else { return true }
            return lhsDate < rhsDate
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if sortedItems.isEmpty {
                    ContentUnavailableView("추가된 일정이 없어요", systemImage: "mappin.slash")
                } else {
                    ForEach(sortedItems) { item in
                        Button {
                            onSelect(item)
                            dismiss()
                        } label: {
                            HStack {
                                Text(item.itemType.icon)
                                VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
                                    Text(item.name)
                                        .font(FlowneyFont.bodyEmphasis)
                                        .foregroundStyle(FlowneyTheme.textPrimary)
                                    if let date = days[id: item.dayId]?.dayDate {
                                        Text(Self.dateFormatter.string(from: date))
                                            .font(FlowneyFont.caption)
                                            .foregroundStyle(FlowneyTheme.textSecondary)
                                    }
                                }
                            }
                        }
                        .listRowBackground(FlowneyTheme.surface)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(FlowneyTheme.background)
            .navigationTitle("일정 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
        }
    }
}
