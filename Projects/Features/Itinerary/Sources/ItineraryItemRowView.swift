import Models
import SwiftUI

struct ItineraryItemRowView: View {
    let item: ItineraryItem

    var body: some View {
        HStack(spacing: 12) {
            Text(iconForType)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body.weight(.medium))
                HStack(spacing: 6) {
                    if let startTime = item.startTime {
                        Text(startTime.prefix(5))
                    }
                    if let mode = item.arrivalMode {
                        Text(mode.displayName)
                    }
                    if !item.hasLocation {
                        Text("장소 미정")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            if let amount = item.costAmount {
                Text("\(amount)\(item.costCurrency ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var iconForType: String {
        switch item.itemType {
        case .start: return "🚩"
        case .sight: return "📍"
        case .meal: return "🍽️"
        case .lodge: return "🛏️"
        case .transport: return "🚗"
        case .activity: return "🎟️"
        case .shopping: return "🛍️"
        case .freeTime: return "☕️"
        case .other: return "📌"
        }
    }
}
