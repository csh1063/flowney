import DesignSystem
import Models
import SwiftUI

struct DayTabView: View {
    let day: TripDay
    let isSelected: Bool
    let weatherIcon: String?
    let columnWidth: CGFloat
    let onTapped: () -> Void
    let onItemDropped: (String) -> Void

    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: 2) {
                Text("\(day.dayIndex)일차")
                    .font(WaypinFont.caption)
                Text(dateLabel)
                    .font(WaypinFont.bodyEmphasis)
                Text(weatherIcon ?? " ")
                    .font(.caption2)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? WaypinTheme.fill : WaypinTheme.divider)
            .foregroundStyle(isSelected ? WaypinTheme.fillLabel : WaypinTheme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 3)
        }
        .buttonStyle(.plain)
        .frame(width: columnWidth)
        .dropDestination(for: String.self) { droppedIDs, _ in
            guard let itemID = droppedIDs.first else { return false }
            onItemDropped(itemID)
            return true
        }
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: day.dayDate)
    }
}
