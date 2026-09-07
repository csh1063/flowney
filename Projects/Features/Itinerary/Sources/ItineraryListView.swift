import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct ItineraryListView: View {
    @Bindable var store: StoreOf<ItineraryFeature>
    let onTripListRequested: () -> Void
    let onItemTapped: (TripDay.ID, ItineraryItem.ID) -> Void

    public init(
        store: StoreOf<ItineraryFeature>,
        onTripListRequested: @escaping () -> Void,
        onItemTapped: @escaping (TripDay.ID, ItineraryItem.ID) -> Void
    ) {
        self.store = store
        self.onTripListRequested = onTripListRequested
        self.onItemTapped = onItemTapped
    }

    public var body: some View {
        Group {
            if store.trip == nil {
                WaypinTripLoadEmptyStateView(icon: "list.bullet") {
                    onTripListRequested()
                }
            } else if store.isLoading && store.days.isEmpty {
                ProgressView("불러오는 중…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(rows) { row in
                        rowContent(row)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(WaypinTheme.background)
        .waypinLeadingTitle(store.trip?.name ?? "리스트")
        .waypinLifecycleLog(category: .itinerary)
    }

    @ViewBuilder
    private func rowContent(_ row: ListRow) -> some View {
        switch row {
        case let .countryHeader(code):
            HStack(spacing: 6) {
                Text(CountryCatalog.flagEmoji(for: code))
                Text(CountryCatalog.option(for: code)?.name ?? code)
                    .font(WaypinFont.screenTitle)
            }
            .padding(.top, WaypinSpacing.md)
            .listRowInsets(EdgeInsets(top: 0, leading: WaypinSpacing.lg, bottom: 0, trailing: WaypinSpacing.lg))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

        case let .dayHeader(day):
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(day.dayIndex)일차 · \(dayDateLabel(day))")
                        .font(WaypinFont.sectionHeader)
                    if let label = day.label, !label.isEmpty {
                        Text(label)
                            .font(WaypinFont.captionEmphasis)
                            .foregroundStyle(WaypinTheme.accentLabel)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(WaypinTheme.accent, in: Capsule())
                    }
                }
            }
            .padding(.top, WaypinSpacing.sm)
            .listRowInsets(EdgeInsets(top: 0, leading: WaypinSpacing.lg, bottom: 0, trailing: WaypinSpacing.lg))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

        case let .item(item, day):
            Button {
                onItemTapped(day.id, item.id)
            } label: {
                ListItemRowView(item: item)
            }
            .buttonStyle(.plain)
            .waypinCardListRow()
        }
    }

    private func dayDateLabel(_ day: TripDay) -> String {
        Self.dayDateFormatter.string(from: day.dayDate)
    }

    private static let dayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d(E)"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()

    private enum ListRow: Identifiable {
        case countryHeader(code: String)
        case dayHeader(day: TripDay)
        case item(item: ItineraryItem, day: TripDay)

        var id: String {
            switch self {
            case let .countryHeader(code): "country-\(code)"
            case let .dayHeader(day): "day-\(day.id)"
            case let .item(item, _): "item-\(item.id)"
            }
        }
    }

    private var rows: [ListRow] {
        var result: [ListRow] = []
        var lastCountryCode: String?
        for day in store.days {
            if let code = store.dayCountryCodes[day.id]?.first, code != lastCountryCode {
                result.append(.countryHeader(code: code))
                lastCountryCode = code
            }
            result.append(.dayHeader(day: day))
            for item in store.itemsByDay[day.id] ?? [] {
                result.append(.item(item: item, day: day))
            }
        }
        return result
    }
}

private struct ListItemRowView: View {
    let item: ItineraryItem

    var body: some View {
        HStack(spacing: WaypinSpacing.md) {
            Text(item.itemType.icon)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: WaypinSpacing.xs / 2) {
                Text(item.name)
                    .font(WaypinFont.bodyEmphasis)
                    .foregroundStyle(WaypinTheme.textPrimary)
                subtitle
                    .font(WaypinFont.caption)
                    .foregroundStyle(WaypinTheme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: WaypinSpacing.xs / 2) {
                if let amount = item.costAmount {
                    let priceText: String = "\(amount)\(item.costCurrency ?? "")"
                    Text(priceText)
                        .font(WaypinFont.caption)
                        .foregroundStyle(WaypinTheme.textSecondary)
                }
                if let status = item.paymentStatus {
                    StatusPill(text: status.displayName, color: status.pillColor)
                }
            }
        }
        .waypinCard()
    }

    @ViewBuilder
    private var subtitle: some View {
        if item.startTime != nil || item.arrivalMode != nil {
            HStack(spacing: WaypinSpacing.xs + 2) {
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
