import Models
import SwiftUI

/// 여행 이름 + 기간을 카드 하나로 보여주는 행 — 여행 목록 화면과 일정 추가 마법사의
/// 여행 선택 단계가 똑같은 모양을 쓰기 위해 DesignSystem으로 뺐다.
public struct TripSummaryRowView: View {
    let trip: Trip

    public init(trip: Trip) {
        self.trip = trip
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: WaypinSpacing.xs) {
            Text(trip.name)
                .font(WaypinFont.sectionHeader)
            Text(dateRangeText)
                .font(WaypinFont.caption)
                .foregroundStyle(WaypinTheme.textSecondary)
        }
        .waypinCard()
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
}
