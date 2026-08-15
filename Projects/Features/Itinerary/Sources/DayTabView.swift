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
                    .font(.caption2)
                Text(dateLabel)
                    .font(.subheadline.weight(.semibold))
                Text(weatherIcon ?? " ")
                    .font(.caption2)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isSelected ? WaypinTheme.accent : WaypinTheme.divider)
            .foregroundStyle(isSelected ? WaypinTheme.accentLabel : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            // 날짜 칸(columnWidth) 자체는 CountryDayHeaderView의 누적 폭 계산과 맞아야 해서
            // 그대로 두고, 그 안의 알약만 살짝 인셋을 줘서 버튼 사이에 여백처럼 보이게 한다
            // (HStack에 spacing을 주면 그 누적 폭이 날짜마다 밀려서 위 국가 띠와 어긋난다).
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
