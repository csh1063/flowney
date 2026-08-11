import AddItem
import ComposableArchitecture
import Models
import SwiftUI

public struct ItineraryView: View {
    @Bindable var store: StoreOf<ItineraryFeature>
    // `@Presents`/`ifLet` 대신 이 View가 직접 AddItemFeature Store를 소유한다
    // (TripListView와 동일한 이유·패턴).
    @State private var addItemStore: StoreOf<AddItemFeature>?
    // 리스트 시트는 두 단계(약 3.5줄 / 약 1.5줄)로만 오간다. 어느 단계인지에 따라 지도가
    // 실제로 "보이는" 영역이 달라지므로, 카메라를 맞출 때 이 높이만큼 아래쪽을 더 띄운다.
    @State private var sheetDetent: PresentationDetent = .height(expandedListHeight)
    // 화면 전환은 부모(RootView)가 NavigationStack(path:)로 관리하므로, 요청만 콜백으로
    // 위로 전달한다. 경로 탐색은 더 이상 별도 화면이 아니라 이 화면 안의 액션이라
    // 콜백이 필요 없다.
    let onBudgetRequested: (Trip) -> Void

    private let dayColumnWidth: CGFloat = 64
    private static let expandedListHeight: CGFloat = 220
    private static let collapsedListHeight: CGFloat = 120

    public init(
        store: StoreOf<ItineraryFeature>,
        onBudgetRequested: @escaping (Trip) -> Void
    ) {
        self.store = store
        self.onBudgetRequested = onBudgetRequested
    }

    private var currentListHeight: CGFloat {
        sheetDetent == .height(Self.collapsedListHeight) ? Self.collapsedListHeight : Self.expandedListHeight
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerSection
            mapSection
        }
        .navigationTitle(store.trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
                        Label("경로 탐색", systemImage: "point.topleft.down.curvedto.point.bottomright.up")
                    }
                }
                .disabled(store.isSearchingAllRoutes)
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    onBudgetRequested(store.trip)
                } label: {
                    Label("요금표", systemImage: "wonsign.circle")
                }
            }
        }
        .onAppear { store.send(.onAppear) }
        .onChange(of: store.addItemRequest) { _, request in
            guard let request else { return }
            addItemStore = Store(initialState: request) { AddItemFeature() }
            store.send(.addItemRequestConsumed)
        }
        .sheet(isPresented: .constant(true)) {
            itemListSheet
                .presentationDetents([.height(Self.collapsedListHeight), .height(Self.expandedListHeight)], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
                .interactiveDismissDisabled()
        }
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
            .padding(.horizontal)
            .padding(.top, 8)

            // 응답 오기 전에는 빈 칸(공백 한 칸)을 같은 폰트로 깔아둬서, 나중에 텍스트가
            // 채워질 때 그 위/아래 레이아웃이 밀리지 않도록 처음부터 자리를 잡아둔다.
            Text(store.selectedDayWeather.map(weatherSummary) ?? " ")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
    }

    private func weatherSummary(_ weather: DayWeather) -> String {
        var text = "\(weather.icon) \(weather.tmin)°/\(weather.tmax)° 강수확률 \(weather.pop)%(\(weather.precip)mm)"
        if weather.historical {
            text += " (지난 평균)"
        }
        return text
    }

    // MARK: - 지도 + 이전/다음 버튼

    private var mapSection: some View {
        ZStack(alignment: .bottomTrailing) {
            RouteMapView(
                items: store.selectedItems,
                legs: store.selectedDayLegs,
                currentStopIndex: store.currentStopIndex,
                animateTrigger: store.animateTrigger,
                jumpTrigger: store.jumpTrigger,
                focusedItemID: store.selectedItemID,
                bottomInset: currentListHeight,
                onAnimationCompleted: { store.send(.legAnimationCompleted) },
                onMarkerTapped: { store.send(.selectStopTapped($0)) }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .bottom)

            if let errorMessage = store.errorMessage {
                VStack(spacing: 8) {
                    Label("문제가 발생했어요", systemImage: "exclamationmark.triangle")
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            // 시트 높이가 바뀌면(3.5줄 ↔ 1.5줄) 버튼도 그 위에 딱 붙어서 같이 움직인다.
            prevNextControls
                .padding(.trailing, 16)
                .padding(.bottom, currentListHeight + 16)
                .animation(.easeInOut(duration: 0.25), value: currentListHeight)
        }
    }

    private var prevNextControls: some View {
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

    private var itemListSheet: some View {
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
                            // 이게 없으면 draggable/contextMenu 제스처와 겹치면서 텍스트가
                            // 있는 부분만 탭이 먹는 것처럼 보였다.
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(.selectStopTapped(item.id))
                            }
                            .id(item.id)
                            .draggable(item.id.uuidString)
                            .contextMenu {
                                if store.days.count > 1 {
                                    Menu("다른 날짜로 이동") {
                                        ForEach(store.days.filter { $0.id != store.selectedDayID }) { day in
                                            Button("\(day.dayIndex)일차") {
                                                store.send(.itemDroppedOnDay(item.id, day.id))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .onDelete { store.send(.deleteItems($0)) }
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
        .sheet(
            isPresented: Binding(
                get: { addItemStore != nil },
                set: { isPresented in
                    if !isPresented { addItemStore = nil }
                }
            )
        ) {
            if let addItemStore {
                AddItemView(store: addItemStore)
                    .onChange(of: addItemStore.savedItem) { _, savedItem in
                        if let savedItem {
                            store.send(.itemAdded(savedItem))
                            self.addItemStore = nil
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
