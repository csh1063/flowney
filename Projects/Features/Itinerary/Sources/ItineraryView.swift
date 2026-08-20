import AddItem
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

public struct ItineraryView: View {
    @Bindable var store: StoreOf<ItineraryFeature>
    // `@Presents`/`ifLet` 대신 이 View가 직접 TripEditFeature Store를 소유한다
    // (TripListView와 동일한 이유·패턴) — "여행 수정" 메뉴에서 쓴다.
    @State private var editStore: StoreOf<TripEditFeature>?
    // `@Presents`/`ifLet` 대신 이 View가 직접 AddItemFlowFeature Store를 소유한다
    // (TripListView와 동일한 이유·패턴).
    @State private var addItemFlowStore: StoreOf<AddItemFlowFeature>?
    // 리스트는 기존 그대로 시스템 `.sheet`다 — 창(window) 레벨 모달이라 뜨는 순간 탭바 위로
    // 자연스럽게 올라와서 가려준다(탭바를 따로 숨기는 코드가 필요 없음). 예전엔 화면 진입시
    // 항상 열려 있었는데, 이제는 기본이 닫힘이고 "위로" 버튼을 눌러야만 뜬다.
    @State private var isListSheetPresented = false
    // 리스트 시트는 두 단계(약 3.5줄 / 약 1.5줄)로만 오간다.
    @State private var sheetDetent: PresentationDetent = .height(expandedListHeight)
    // 지도 탭이 상시 화면이 되면서, 여행이 아직 안 골라졌을 때 "여행 불러오기"를 어떻게
    // 띄울지는 이 화면을 담고 있는 쪽(RootView)만 안다 — 그쪽 시트를 열어달라는 요청만
    // 콜백으로 위로 전달한다.
    let onTripListRequested: () -> Void

    private let dayColumnWidth: CGFloat = 64
    private static let expandedListHeight: CGFloat = 220
    private static let collapsedListHeight: CGFloat = 120

    public init(store: StoreOf<ItineraryFeature>, onTripListRequested: @escaping () -> Void) {
        self.store = store
        self.onTripListRequested = onTripListRequested
    }

    // 시트가 닫혀있으면 0(지도가 화면 전체를 씀), 열려있으면 두 단계 중 하나.
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
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        store.send(.searchAllRoutesButtonTapped)
                    } label: {
                        if store.isSearchingAllRoutes {
                            ProgressView()
                        } else {
                            Label("전체 경로 탐색", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                        }
                    }
                    .disabled(store.isSearchingAllRoutes)
                }
                ToolbarItem(placement: .secondaryAction) {
                    Divider()
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        onTripListRequested()
                    } label: {
                        Label("여행 목록", systemImage: "list.bullet")
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        if let trip = store.trip {
                            editStore = Store(initialState: TripEditFeature.State(editing: trip, countries: Array(store.countries))) {
                                TripEditFeature()
                            }
                        }
                    } label: {
                        Label("여행 수정", systemImage: "pencil")
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
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - 국가 띠 + 날짜탭 + 날씨 바

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
            // 예전엔 `.padding(.horizontal)`을 ScrollView 자체에 걸어서, 뷰포트 너비 자체가
            // 화면보다 좁아졌었다 — 그러면 스크롤해서 셀이 지나갈 때도 항상 화면 양끝에
            // 여백이 낀 채로만 보인다. 뷰포트는 화면 끝까지 꽉 채우고, 맨 처음/맨 끝
            // 콘텐츠에만 여백이 남도록 컨텐츠 마진으로 바꾼다.
            .contentMargins(.horizontal, 16, for: .scrollContent)
            .padding(.top, 8)

            // 응답 오기 전에는 빈 칸(공백 한 칸)을 같은 폰트로 깔아둬서, 나중에 텍스트가
            // 채워질 때 그 위/아래 레이아웃이 밀리지 않도록 처음부터 자리를 잡아둔다.
            Text(store.selectedDayWeather.map(weatherSummary) ?? " ")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
        .background(WaypinTheme.background)
    }

    private func weatherSummary(_ weather: DayWeather) -> String {
        var text = "\(weather.icon) \(weather.tmin)°/\(weather.tmax)° 강수확률 \(weather.pop)%(\(weather.precip)mm)"
        if weather.historical {
            text += " (지난 평균)"
        }
        return text
    }

    // MARK: - 이전/위로(아래로)/다음 버튼

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
                Image(systemName: isListSheetPresented ? "chevron.down" : "chevron.up")
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

    // MARK: - 하단 리스트

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
                                        .font(.body.weight(.medium))
                                    Text("오늘 동선 한눈에 보기")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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
                                // 여행 생성 때 고른 나라 목록에 없는 곳이면 경고 아이콘 —
                                // 독립된 Button이라 행 전체 탭(장소 선택)과 별도로 눌린다.
                                if store.unregisteredCountryItemIDs.contains(item.id) {
                                    Button {
                                        store.send(.warningIconTapped(item.id))
                                    } label: {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.yellow)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            // Spacer로 벌어진 빈 공간까지 포함해서 행 전체가 눌리도록.
                            // 이게 없으면 draggable 제스처와 겹치면서 텍스트가 있는 부분만
                            // 탭이 먹는 것처럼 보였다.
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
                        // html의 markListState()도 scrollIntoView({block:'start'})로 항상
                        // 리스트 맨 위로 스크롤한다 — 이미 그 이상 올릴 내용이 없으면(맨 끝
                        // 근처) 알아서 거기서 멈추고 억지로 빈 여백을 만들지 않는다.
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
                Text("\(item.name)의 위치가 여행에 등록된 나라가 아니에요. 잠깐 들른 곳이면 그냥 둬도 되고, 주소가 잘못됐으면 삭제하세요.")
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
