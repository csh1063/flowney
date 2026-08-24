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

    @State private var currentTrip: Trip?
    @State private var itineraryStore = Store(initialState: ItineraryFeature.State()) {
        ItineraryFeature()
    }
    @State private var budgetStore: StoreOf<BudgetFeature>?
    @State private var isTripLoaderPresented = false
    @State private var selectedTab: Tab = .map
    @State private var isMyPageSubpagePresented = false
    @State private var floatingTabBarHeight: CGFloat = 0
    @State private var shouldAutoOpenShareInbox = false

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        content
            .tint(WaypinTheme.accent)
            .onAppear { store.send(.auth(.onAppear)) }
    }

    @ViewBuilder
    private var content: some View {
        if store.auth.isCheckingSession {
            SplashView()
        } else if store.auth.isSignedIn {
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

                if !(selectedTab == .myPage && isMyPageSubpagePresented) {
                    floatingTabBar
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(key: FloatingTabBarHeightPreferenceKey.self, value: proxy.size.height)
                            }
                        )
                }
            }
            .onPreferenceChange(FloatingTabBarHeightPreferenceKey.self) { floatingTabBarHeight = $0 }
            .environment(\.floatingTabBarHeight, floatingTabBarHeight)
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

    private var listTab: some View {
        NavigationStack {
            ItineraryListView(
                store: itineraryStore,
                onTripListRequested: { isTripLoaderPresented = true },
                onItemTapped: { dayID, itemID in
                    itineraryStore.send(.dayTabTapped(dayID))
                    itineraryStore.send(.selectStopTapped(itemID))
                    selectedTab = .map
                }
            )
        }
    }

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
