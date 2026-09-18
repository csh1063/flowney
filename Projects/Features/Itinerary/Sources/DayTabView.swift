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
                    .font(FlowneyFont.caption)
                    .foregroundStyle(isSelected ? FlowneyTheme.fillLabel : weekdayColor ?? FlowneyTheme.textPrimary)
                Text(dateLabel)
                    .font(FlowneyFont.bodyEmphasis)
                    .foregroundStyle(isSelected ? FlowneyTheme.fillLabel : weekdayColor ?? FlowneyTheme.textPrimary)
                Text(weatherIcon ?? " ")
                    .font(.caption2)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? FlowneyTheme.fill : FlowneyTheme.divider)
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

    /// 공휴일 데이터 소스가 없어서 토/일만 색으로 구분한다(토=파랑, 일=빨강).
    private var weekdayColor: Color? {
        switch Calendar.current.component(.weekday, from: day.dayDate) {
        case 1: return .red
        case 7: return .blue
        default: return nil
        }
    }
}
