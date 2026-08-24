import Models
import SwiftUI

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
