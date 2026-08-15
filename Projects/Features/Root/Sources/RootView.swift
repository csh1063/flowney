import APIClient
import AuthFeature
import Budget
import ComposableArchitecture
import DesignSystem
import Itinerary
import Models
import SwiftUI
import TripList

public struct RootView: View {
    private enum Tab {
        case list, map, budget, myPage
    }

    @Bindable var store: StoreOf<AppFeature>

    // 탭(지도/요금표) 간에 "지금 보고 있는 여행"을 공유하는 상태. TCA `@Presents`/`ifLet`
    // 대신 순수 SwiftUI `@State` + 독립 Store로 관리한다 — `TripListView`의 `editStore`와
    // 같은 이유(이 툴체인에서 `@Presents`가 실기기 EXC_BAD_ACCESS를 유발했던 전례,
    // project_tca_presents_crash 참고).
    @State private var currentTrip: Trip?
    // 지도 탭은 이제 상시 존재하는 화면이라(예전엔 여행을 고를 때만 만들어졌음) Store도
    // 처음부터 trip 없이 만들어서 계속 살아있게 한다 — 여행을 고르면 이 Store에
    // `.tripSelected`를 보내서 채워 넣지, Store 자체를 새로 갈아끼우지 않는다.
    @State private var itineraryStore = Store(initialState: ItineraryFeature.State()) {
        ItineraryFeature()
    }
    @State private var budgetStore: StoreOf<BudgetFeature>?
    @State private var isTripLoaderPresented = false
    // 탭 순서는 리스트/지도/요금표/마이페이지지만, 처음 열리는 화면은 항상 지도여야 한다.
    @State private var selectedTab: Tab = .map
    // 마이페이지에서 하위 페이지(계정정보/공유링크함)로 들어가있는 동안은 떠 있는 탭바를
    // 숨긴다 — MyPageView가 이 값을 올려보낸다.
    @State private var isMyPageSubpagePresented = false
    // 공유 익스텐션으로 링크를 저장한 뒤 앱을 다시 켜면, 그 첫 실행에서만 한 번
    // 공유링크함을 자동으로 열어준다.
    @State private var shouldAutoOpenShareInbox = false

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        // `AccentColor.colorset`만 믿었더니 실기기에서 내비게이션 바 버튼(뒤로가기/취소/저장
        // 등)이 여전히 기본 파란색으로 보이는 문제가 있었다 — 자산 카탈로그 이름 매칭만으로는
        // 왜인지 전역 tint가 100% 안 먹혀서, 루트에서 명시적으로 한 번 더 강제한다.
        content
            .tint(WaypinTheme.accent)
            // 세션 확인은 특정 화면(로그인 화면 등)의 onAppear가 아니라 여기서 무조건 한 번
            // 시작한다 — 그래야 어느 화면이 뜨기도 전에 스플래시 단계에서부터 확인이 진행된다.
            .onAppear { store.send(.auth(.onAppear)) }
    }

    @ViewBuilder
    private var content: some View {
        if store.auth.isCheckingSession {
            SplashView()
        } else if store.auth.isSignedIn {
            // 네이티브 탭바는 완전히 숨기고, 화면 위에 떠 있는 느낌의 둥근 커스텀 탭바를
            // 직접 그린다 — 일정 리스트 시트가 창 레벨 모달이라 뜨는 순간 이 위로도 자연스레
            // 덮이기 때문에, 시트 열릴 때 따로 탭바를 숨기는 로직이 필요 없다.
            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    mapTab.tag(Tab.map)
                    listTab.tag(Tab.list)
                    budgetTab.tag(Tab.budget)
                    NavigationStack {
                        MyPageView(
                            store: store.scope(state: \.auth, action: \.auth),
                            currentTripID: currentTrip?.id,
                            isSubpagePresented: $isMyPageSubpagePresented,
                            autoOpenShareInbox: $shouldAutoOpenShareInbox
                        )
                    }
                    .tag(Tab.myPage)
                }
                .toolbar(.hidden, for: .tabBar)

                // 마이페이지 탭에서 하위 페이지가 떠 있는 동안만 숨긴다 — 다른 탭에서는
                // 항상 보인다(`isMyPageSubpagePresented`가 탭 전환 시 확실히 안 꺼지는
                // 경우에 대비한 이중 안전장치).
                if !(selectedTab == .myPage && isMyPageSubpagePresented) {
                    floatingTabBar
                }
            }
            .onAppear { consumeAutoOpenShareInboxFlagIfNeeded() }
        } else {
            AuthView(store: store.scope(state: \.auth, action: \.auth))
        }
    }

    private var floatingTabBar: some View {
        HStack(spacing: 0) {
            floatingTabButton(.map, icon: "map", label: "지도")
            floatingTabButton(.list, icon: "list.bullet", label: "리스트")
            floatingTabButton(.budget, icon: "wonsign.circle", label: "요금표")
            floatingTabButton(.myPage, icon: "person.crop.circle", label: "마이페이지")
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(WaypinTheme.surface)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        )
        .padding(.horizontal, WaypinSpacing.lg)
        .padding(.bottom, WaypinSpacing.xs)
    }

    private func floatingTabButton(_ tab: Tab, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(WaypinFont.caption)
            }
            .foregroundStyle(isSelected ? WaypinTheme.accent : WaypinTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 지도 탭 (메인)

    private var mapTab: some View {
        NavigationStack {
            ItineraryView(store: itineraryStore) {
                isTripLoaderPresented = true
            }
        }
        .sheet(isPresented: $isTripLoaderPresented) {
            tripLoaderSheet
        }
    }

    private var tripLoaderSheet: some View {
        NavigationStack {
            TripListView(store: store.scope(state: \.tripList, action: \.tripList)) { trip in
                selectTrip(trip)
                isTripLoaderPresented = false
            }
        }
    }

    private func consumeAutoOpenShareInboxFlagIfNeeded() {
        guard PendingShareAutoOpenFlag.consumeShouldAutoOpen() else { return }
        selectedTab = .myPage
        shouldAutoOpenShareInbox = true
    }

    private func selectTrip(_ trip: Trip) {
        currentTrip = trip
        LastTripStore.save(tripID: trip.id)
        itineraryStore.send(.tripSelected(trip))
        budgetStore = Store(initialState: BudgetFeature.State(trip: trip)) {
            BudgetFeature()
        }
    }

    // MARK: - 리스트 탭 (Phase 4에서 실제 구현 — 지금은 자리만)

    private var listTab: some View {
        NavigationStack {
            VStack {
                Spacer()
                Text("준비중이에요")
                    .font(WaypinFont.body)
                    .foregroundStyle(WaypinTheme.textSecondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(WaypinTheme.background)
            .waypinLeadingTitle("리스트")
        }
    }

    // MARK: - 요금표 탭

    private var budgetTab: some View {
        NavigationStack {
            Group {
                if let budgetStore {
                    BudgetView(store: budgetStore)
                } else {
                    VStack {
                        Spacer()
                        Text("불러온 여행이 없어요")
                            .font(WaypinFont.body)
                            .foregroundStyle(WaypinTheme.textSecondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .background(WaypinTheme.background)
                    .waypinLeadingTitle("요금표")
                }
            }
        }
    }
}
