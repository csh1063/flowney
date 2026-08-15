import DesignSystem
import Models
import SwiftUI

struct ItineraryItemRowView: View {
    let item: ItineraryItem

    var body: some View {
        HStack(spacing: WaypinSpacing.md) {
            Text(item.itemType.icon)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: WaypinSpacing.xs / 2) {
                Text(item.name)
                    .font(WaypinFont.bodyEmphasis)
                HStack(spacing: WaypinSpacing.xs + 2) {
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
                .font(WaypinFont.caption)
                .foregroundStyle(WaypinTheme.textSecondary)
            }

            Spacer()

            if let amount = item.costAmount {
                let priceText: String = "\(amount)\(item.costCurrency ?? "")"
                Text(priceText)
                    .font(WaypinFont.caption)
                    .foregroundStyle(WaypinTheme.textSecondary)
            }
        }
        .padding(.vertical, WaypinSpacing.xs)
    }
}
