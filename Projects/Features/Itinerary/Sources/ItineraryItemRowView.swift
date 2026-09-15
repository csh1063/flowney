import DesignSystem
import Models
import SwiftUI

struct ItineraryItemRowView: View {
    let item: ItineraryItem
    let costEntry: BudgetEntry?

    var body: some View {
        HStack(spacing: FlowneySpacing.md) {
            Text(item.itemType.icon)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: FlowneySpacing.xs / 2) {
                Text(item.name)
                    .font(FlowneyFont.bodyEmphasis)
                subtitle
                    .font(FlowneyFont.caption)
                    .foregroundStyle(FlowneyTheme.textSecondary)
            }

            Spacer()

            if let amount = costEntry?.costAmount {
                let priceText: String = "\(amount)\(costEntry?.costCurrency ?? "")"
                Text(priceText)
                    .font(FlowneyFont.caption)
                    .foregroundStyle(FlowneyTheme.textSecondary)
            }
        }
        .padding(.vertical, FlowneySpacing.xs + 4)
    }

    @ViewBuilder
    private var subtitle: some View {
        if item.startTime != nil || item.arrivalMode != nil {
            HStack(spacing: FlowneySpacing.xs + 2) {
                if let startTime = item.startTime {
                    Text(startTime.prefix(5))
                }
                if let mode = item.arrivalMode {
                    Text(mode.displayName)
                }
            }
        } else if !item.hasLocation {
            Text("장소 미정")
        }
    }
}
