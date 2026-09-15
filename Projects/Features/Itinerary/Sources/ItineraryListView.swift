import AddItem
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

public struct ItineraryListView: View {
    @Bindable var store: StoreOf<ItineraryFeature>
    let onTripListRequested: () -> Void
    let onViewOnMapRequested: (TripDay.ID, ItineraryItem.ID) -> Void
    @State private var addItemFlowStore: StoreOf<AddItemFlowFeature>?
    @State private var pendingDeleteItemID: ItineraryItem.ID?
    @State private var revealedRowID: AnyHashable?

    public init(
        store: StoreOf<ItineraryFeature>,
        onTripListRequested: @escaping () -> Void,
        onViewOnMapRequested: @escaping (TripDay.ID, ItineraryItem.ID) -> Void
    ) {
        self.store = store
        self.onTripListRequested = onTripListRequested
        self.onViewOnMapRequested = onViewOnMapRequested
    }

    public var body: some View {
        Group {
            if store.trip == nil {
                FlowneyTripLoadEmptyStateView(icon: "list.bullet") {
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
                    .onMove { source, destination in
                        handleMove(source, destination)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
            }
        }
        .background(FlowneyTheme.background)
//        .ignoresSafeArea(edges: .bottom)
        .flowneyLeadingTitle(store.trip?.name ?? "리스트")
        .toolbar {
            if let trip = store.trip {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addItemButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    TripManagementMenuButton(
                        trip: trip,
                        onTripListRequested: onTripListRequested,
                        onTripUpdated: { store.send(.tripSelected($0)) }
                    )
                }
            }
        }
        .flowneyLifecycleLog(category: .itinerary)
        .sheet(isPresented: isEditingDayLabel) {
            if let dayID = store.editingDayLabelForID, let day = store.days[id: dayID] {
                DayLabelEditSheet(
                    initialLabel: day.label ?? "",
                    onConfirm: { text in store.send(.dayLabelChanged(dayID, text.isEmpty ? nil : text)) }
                )
            }
        }
        .onChange(of: store.addItemFlowRequest) { _, request in
            guard let request else { return }
            addItemFlowStore = Store(initialState: request) { AddItemFlowFeature() }
            store.send(.addItemRequestConsumed)
        }
        .sheet(
            isPresented: Binding(
                get: { addItemFlowStore != nil },
                set: { isPresented in
                    if !isPresented { addItemFlowStore = nil }
                }
            )
        ) {
            if let addItemFlowStore {
                AddItemFlowView(
                    store: addItemFlowStore,
                    onItemAdded: { item in
                        store.send(.itemAdded(item))
                        self.addItemFlowStore = nil
                    },
                    onCancelled: { self.addItemFlowStore = nil }
                )
            }
        }
//        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 48) }
        .confirmationDialog(
            "이 일정을 삭제할까요?",
            isPresented: Binding(
                get: { pendingDeleteItemID != nil },
                set: { isPresented in
                    if !isPresented { pendingDeleteItemID = nil }
                }
            ),
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) {
                if let itemID = pendingDeleteItemID {
                    store.send(.deleteItemByID(itemID))
                }
                pendingDeleteItemID = nil
            }
            Button("취소", role: .cancel) {
                pendingDeleteItemID = nil
            }
        }
    }

    private var isEditingDayLabel: Binding<Bool> {
        Binding(
            get: { store.editingDayLabelForID != nil },
            set: { isPresented in
                if !isPresented { store.send(.dayLabelEditCancelled) }
            }
        )
    }

    @ViewBuilder
    private func rowContent(_ row: ListRow) -> some View {
        switch row {
        case let .countryHeader(code):
            HStack(spacing: 6) {
                Text(CountryCatalog.flagEmoji(for: code))
                Text(CountryCatalog.option(for: code)?.name ?? code)
                    .font(FlowneyFont.screenTitle)
            }
            .padding(.top, FlowneySpacing.md)
            .listRowInsets(EdgeInsets(top: 0, leading: FlowneySpacing.lg, bottom: 0, trailing: FlowneySpacing.lg))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .moveDisabled(true)

        case let .dayHeader(day):
            dayHeaderContent(day)

        case let .item(item, day):
            itemRowContent(item, day)
        }
    }

    @ViewBuilder
    private func dayHeaderContent(_ day: TripDay) -> some View {
        HStack(spacing: 6) {
            Text("\(day.dayIndex)일차")
                .font(FlowneyFont.captionEmphasis)
                .foregroundStyle(FlowneyTheme.accentLabel)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(FlowneyTheme.accent, in: Capsule())

            Text(dayDateLabel(day))
                .font(FlowneyFont.sectionHeader)

            if let label = day.label, !label.isEmpty {
                Text(label)
                    .font(FlowneyFont.sectionHeader)
                    .foregroundStyle(FlowneyTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                store.send(.editDayLabelButtonTapped(day.id))
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 13))
                    .foregroundStyle(FlowneyTheme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, FlowneySpacing.sm)
        .listRowInsets(EdgeInsets(top: 0, leading: FlowneySpacing.lg, bottom: 0, trailing: FlowneySpacing.lg))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    @ViewBuilder
    private func itemRowContent(_ item: ItineraryItem, _ day: TripDay) -> some View {
        SwipeToDeleteCard(
            id: item.id,
            revealedID: $revealedRowID,
            onDelete: { pendingDeleteItemID = item.id },
            onEdit: { store.send(.editItemTapped(item)) },
            onTap: { store.send(.listItemTapped(item.id)) }
        ) {
            ListItemRowView(
                item: item,
                costEntry: store.entries[id: item.id],
                isSelected: store.listSelectedItemID == item.id,
                onMapButtonTapped: { onViewOnMapRequested(day.id, item.id) }
            )
        }
        .contentShape(Rectangle())
        .flowneyCardListRow()
    }

    private func handleMove(_ source: IndexSet, _ destination: Int) {
        var workingRows = rows
        workingRows.move(fromOffsets: source, toOffset: destination)

        var newItemsByDay: [TripDay.ID: [ItineraryItem]] = [:]
        var currentDayID: TripDay.ID?
        for row in workingRows {
            switch row {
            case let .dayHeader(day):
                currentDayID = day.id
                if newItemsByDay[day.id] == nil {
                    newItemsByDay[day.id] = []
                }
            case let .item(item, _):
                guard let currentDayID else { continue }
                newItemsByDay[currentDayID, default: []].append(item)
            case .countryHeader:
                break
            }
        }
        store.send(.itemsReorderedAcrossDays(newItemsByDay))
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
    let costEntry: BudgetEntry?
    let isSelected: Bool
    let onMapButtonTapped: () -> Void

    var body: some View {
        HStack(spacing: FlowneySpacing.md) {
            Text(item.itemType.icon)
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: FlowneySpacing.xs / 2) {
                Text(item.name)
                    .font(FlowneyFont.bodyEmphasis)
                    .foregroundStyle(FlowneyTheme.textPrimary)
                    .lineLimit(1)
                subtitle
                    .font(FlowneyFont.caption)
                    .foregroundStyle(FlowneyTheme.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: FlowneySpacing.xs)

            if isSelected {
                Button(action: onMapButtonTapped) {
                    Image(systemName: "map")
                        .font(.system(size: 12))
                        .foregroundStyle(FlowneyTheme.fillLabel)
                        .padding(6)
                        .background(FlowneyTheme.fill, in: Circle())
                }
                .buttonStyle(.plain)
                .frame(width: 40, height: 40)
            }

            VStack(alignment: .trailing, spacing: FlowneySpacing.xs / 2) {
                if let amount = costEntry?.costAmount {
                    let priceText: String = "\(amount)\(costEntry?.costCurrency ?? "")"
                    Text(priceText)
                        .font(FlowneyFont.caption)
                        .foregroundStyle(FlowneyTheme.textSecondary)
                }
                if let status = costEntry?.paymentStatus {
                    StatusPill(text: status.displayName, color: status.pillColor)
                }
            }
        }
        .padding(FlowneySpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous)
                    .stroke(FlowneyTheme.accent, lineWidth: 2)
            }
        }
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

private struct DayLabelEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    let onConfirm: (String) -> Void

    init(initialLabel: String, onConfirm: @escaping (String) -> Void) {
        _text = State(initialValue: initialLabel)
        self.onConfirm = onConfirm
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextField("이날의 제목", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, FlowneySpacing.lg)
                    .padding(.top, FlowneySpacing.lg)
                Spacer()
            }
            .navigationTitle("제목 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        onConfirm(text.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(160)])
    }
}
