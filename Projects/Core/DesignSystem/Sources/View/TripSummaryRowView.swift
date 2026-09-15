import Models
import SwiftUI

public struct TripSummaryRowView: View {
    let trip: Trip

    public init(trip: Trip) {
        self.trip = trip
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
            Text(trip.name)
                .font(FlowneyFont.sectionHeader)
            Text(dateRangeText)
                .font(FlowneyFont.caption)
                .foregroundStyle(FlowneyTheme.textSecondary)
        }
        .flowneyCard()
    }

    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return "\(formatter.string(from: trip.startDate)) - \(formatter.string(from: trip.endDate))"
    }
}
