import AddItem
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

public struct ItineraryView: View {
    @Bindable var store: StoreOf<ItineraryFeature>
    @State private var editStore: StoreOf<TripEditFeature>?
    @State private var shareStore: StoreOf<TripShareFeature>?
    @State private var addItemFlowStore: StoreOf<AddItemFlowFeature>?
    @State private var isListSheetPresented = false
    @State private var sheetDetent: PresentationDetent = .height(Self.expandedListHeight)
    let onTripListRequested: () -> Void

    private let dayColumnWidth: CGFloat = 64
    private static let expandedListHeight: CGFloat = 220
    private static let collapsedListHeight: CGFloat = 120

    public init(store: StoreOf<ItineraryFeature>, onTripListRequested: @escaping () -> Void) {
        self.store = store
        self.onTripListRequested = onTripListRequested
    }

    private var currentListHeight: CGFloat {
        guard isListSheetPresented else { return 0 }
        return sheetDetent == .height(Self.collapsedListHeight) ? Self.collapsedListHeight : Self.expandedListHeight
    }

    public var body: some View {
        VStack(spacing: 0) {
            if store.trip != nil {
                headerSection
            } else {
                loadTripButton
            }

            ZStack(alignment: .top) {
                mapLayer

                if store.trip != nil, let errorMessage = store.errorMessage {
                    errorBanner(errorMessage)
                }

                if store.trip != nil, store.days.isEmpty {
                    WaypinTheme.background
                        .overlay { ProgressView() }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: currentListHeight)
        }
        .overlay(alignment: .bottomTrailing) {
            if store.trip != nil {
                controlBar
                    .padding(.trailing, 16)
                    .padding(.bottom, max(24, currentListHeight - UIApplication.shared.keyWindowSafeAreaInsets.bottom))
            }
        }
        .waypinLeadingTitle(store.trip?.name ?? "Waypin")
        .toolbar {
            if store.trip != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.send(.addItemButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section("데이터 갱신") {
                            Button {
                                store.send(.searchAllRoutesButtonTapped)
                            } label: {
                                Label(
                                    store.isSearchingAllRoutes ? "탐색 중…" : "전체 경로 탐색",
                                    systemImage: store.isSearchingAllRoutes ? "hourglass" : "point.topleft.down.curvedto.point.bottomright.up"
                                )
                            }
                            .disabled(store.isSearchingAllRoutes)

                            Button {
                                store.send(.todayRouteRefreshButtonTapped)
                            } label: {
                                Label(
                                    store.isRefreshingTodayRoute ? "갱신 중…" : "오늘 경로 갱신",
                                    systemImage: store.isRefreshingTodayRoute ? "hourglass" : "arrow.clockwise"
                                )
                            }
                            .disabled(store.isRefreshingTodayRoute)

                            Button {
                                store.send(.refreshAllWeatherButtonTapped)
                            } label: {
                                Label(
                                    store.isRefreshingWeather ? "갱신 중…" : "전체 날씨 갱신",
                                    systemImage: store.isRefreshingWeather ? "hourglass" : "cloud.sun"
                                )
                            }
                            .disabled(store.isRefreshingWeather)
                        }

                        Section("여행 관리") {
                            Button {
                                onTripListRequested()
                            } label: {
                                Label("여행 목록", systemImage: "list.bullet")
                            }

                            Button {
                                if let trip = store.trip {
                                    editStore = Store(initialState: TripEditFeature.State(editing: trip, countries: Array(store.countries))) {
                                        TripEditFeature()
                                    }
                                }
                            } label: {
                                Label("여행 수정", systemImage: "pencil")
                            }

                            Button {
                                if let trip = store.trip {
                                    shareStore = Store(initialState: TripShareFeature.State(tripId: trip.id)) {
                                        TripShareFeature()
                                    }
                                }
                            } label: {
                                Label("여행 공유", systemImage: "square.and.arrow.up")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: store.addItemFlowRequest) { _, request in
            guard let request else { return }
            let wasListSheetPresented = isListSheetPresented
            isListSheetPresented = false
            Task { @MainActor in
                if wasListSheetPresented {
                    try? await Task.sleep(for: .milliseconds(350))
                }
                addItemFlowStore = Store(initialState: request) { AddItemFlowFeature() }
            }
            store.send(.addItemRequestConsumed)
        }
        .sheet(isPresented: $isListSheetPresented) {
            itemListContent
                .presentationDetents([.height(Self.collapsedListHeight), .height(Self.expandedListHeight)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
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
        .sheet(
            isPresented: Binding(
                get: { editStore != nil },
                set: { isPresented in
                    if !isPresented { editStore = nil }
                }
            )
        ) {
            if let editStore {
                TripEditView(store: editStore)
                    .onChange(of: editStore.savedTrip) { _, savedTrip in
                        if let savedTrip {
                            store.send(.tripSelected(savedTrip))
                            self.editStore = nil
                        }
                    }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { shareStore != nil },
                set: { isPresented in
                    if !isPresented { shareStore = nil }
                }
            )
        ) {
            if let shareStore {
                TripShareView(store: shareStore)
            }
        }
    }

    private var mapLayer: some View {
        RouteMapView(
            items: store.trip != nil ? store.selectedItems : [],
            legs: store.trip != nil ? store.selectedDayLegs : [],
            currentStopIndex: store.trip != nil ? store.currentStopIndex : nil,
            animateTrigger: store.animateTrigger,
            jumpTrigger: store.jumpTrigger,
            focusedItemID: store.trip != nil ? store.selectedItemID : nil,
            onAnimationCompleted: { store.send(.legAnimationCompleted) },
            onMarkerTapped: { store.send(.selectStopTapped($0)) },
            bottomInset: currentListHeight
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(edges: .bottom)
    }

    private var loadTripButton: some View {
        Button {
            onTripListRequested()
        } label: {
            Label("여행 불러오기", systemImage: "airplane")
        }
        .buttonStyle(.waypinPrimary)
        .padding(.horizontal, WaypinSpacing.xxl)
        .padding(.vertical, WaypinSpacing.md)
        .background(WaypinTheme.background)
    }

    private func errorBanner(_ message: String) -> some View {
        VStack(spacing: 8) {
            Label("문제가 발생했어요", systemImage: "exclamationmark.triangle")
            Text(message)
                .font(WaypinFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 4) {
                    CountryDayHeaderView(
                        days: Array(store.days),
                        countries: store.countries,
                        dayColumnWidth: dayColumnWidth,
                        dayCountryCodes: store.dayCountryCodes
                    )

                    HStack(spacing: 0) {
                        ForEach(store.days) { day in
                            DayTabView(
                                day: day,
                                isSelected: store.selectedDayID == day.id,
                                weatherIcon: store.weatherByDay[day.id]?.icon,
                                columnWidth: dayColumnWidth,
                                onTapped: { store.send(.dayTabTapped(day.id)) },
                                onItemDropped: { idString in
                                    guard let uuid = UUID(uuidString: idString) else { return }
                                    store.send(.itemDroppedOnDay(uuid, day.id))
                                }
                            )
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .padding(.top, 8)

            Text(store.selectedDayWeather.map(weatherSummary) ?? " ")
                .font(WaypinFont.caption)
                .foregroundStyle(WaypinTheme.textSecondary)
                .padding(.bottom, 4)
        }
        .background(WaypinTheme.background)
    }

    private func weatherSummary(_ weather: DayWeather) -> String {
        var text = "\(weather.icon) \(weather.tmin)°/\(weather.pop)%(\(weather.precip)mm)"
        if weather.historical {
            text += " (지난 평균)"
        }
        return text
    }

    private var controlBar: some View {
        HStack(spacing: 12) {
            Button {
                store.send(.prevButtonTapped)
            } label: {
                Image(systemName: "arrowtriangle.left")
                    .font(.title2)
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
            .disabled(store.isPrevDisabled)

            Button {
                if !isListSheetPresented {
                    sheetDetent = .height(Self.expandedListHeight)
                }
                isListSheetPresented.toggle()
            } label: {
                Image(systemName: isListSheetPresented ? "chevron.down" : "list.bullet")
                    .font(.title2)
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }

            Button {
                store.send(.nextButtonTapped)
            } label: {
                Image(systemName: "arrowtriangle.right")
                    .font(.title2)
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
            .disabled(store.isNextDisabled)
        }
    }

    private var itemListContent: some View {
        Group {
            if store.isLoading && store.selectedItems.isEmpty {
                ProgressView("불러오는 중…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.selectedItems.isEmpty {
                ContentUnavailableView(
                    "이 날짜엔 일정이 없어요",
                    systemImage: "calendar",
                    description: Text("오른쪽 위 + 버튼으로 일정을 추가해보세요.")
                )
            } else {
                ScrollViewReader { proxy in
                    List {
                        Button {
                            store.send(.selectAllTapped)
                        } label: {
                            HStack(spacing: 12) {
                                Text("🗺️")
                                    .font(.title3)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("전체보기")
                                        .font(WaypinFont.bodyEmphasis)
                                    Text("오늘 동선 한눈에 보기")
                                        .font(WaypinFont.caption)
                                        .foregroundStyle(WaypinTheme.textSecondary)
                                }
                                Spacer()
                                if store.currentStopIndex == nil {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 24)
                        .id(allViewRowID)

                        ForEach(store.selectedItems) { item in
                            HStack {
                                ItineraryItemRowView(item: item)
                                if store.selectedItemID == item.id {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(.blue)
                                }
                                if store.unregisteredCountryItemIDs.contains(item.id) {
                                    Button {
                                        store.send(.warningIconTapped(item.id))
                                    } label: {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(WaypinTheme.warning)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(.selectStopTapped(item.id))
                            }
                            .id(item.id)
                            .draggable(item.id.uuidString)
                            .swipeActions(edge: .leading) {
                                Button {
                                    store.send(.editItemTapped(item))
                                } label: {
                                    Label("수정", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    if let index = store.selectedItems.index(id: item.id) {
                                        store.send(.deleteItems(IndexSet(integer: index)))
                                    }
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                        .onMove { source, destination in
                            store.send(.itemsMovedWithinDay(source, destination))
                        }
                    }
                    .listStyle(.plain)
                    .onChange(of: store.selectedItemID) { _, newValue in
                        withAnimation {
                            if let newValue {
                                proxy.scrollTo(newValue, anchor: .top)
                            } else {
                                proxy.scrollTo(allViewRowID, anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog(
            "여행에 등록되지 않은 나라예요",
            isPresented: Binding(
                get: { store.warningPopupItemID != nil },
                set: { isPresented in
                    if !isPresented { store.send(.warningDismissed) }
                }
            ),
            titleVisibility: .visible
        ) {
            if let item = store.warningPopupItem {
                Button("삭제", role: .destructive) {
                    store.send(.warningDeleteConfirmed(item.id))
                }
            }
            Button("그냥 두기", role: .cancel) {
                store.send(.warningDismissed)
            }
        } message: {
            if let item = store.warningPopupItem {
                Text("\(item.name)의 위치가 여행에 등록된 나라면 그냥 둬도 되고, 주소가 잘못됐으면 삭제하세요.")
            }
        }
    }

    private var allViewRowID: String { "__all__" }
}

extension UIApplication {
    var keyWindowSafeAreaInsets: UIEdgeInsets {
        guard let scene = connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return .zero
        }
        return window.safeAreaInsets
    }
}
