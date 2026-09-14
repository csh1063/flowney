import APIClient
import AuthFeature
import Budget
import ComposableArchitecture
import DesignSystem
import Itinerary
import Memo
import Models
import SwiftUI
import TripList

public struct RootView: View {
    private enum Tab: CaseIterable {
        case map, list, budget, memo, myPage
        
        var bottomHeight: CGFloat {
            switch self {
            case .map: return 20
            default:
                return 48
            }
        }
    }

    @Bindable var store: StoreOf<AppFeature>
    // @Dependency(\.tripsRepository) private var tripsRepository

    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    @State private var currentTrip: Trip?
    @State private var itineraryStore = Store(initialState: ItineraryFeature.State()) {
        ItineraryFeature()
    }
    @State private var budgetStore: StoreOf<BudgetFeature>?
    @State private var memoStore: StoreOf<MemoFeature>?
    @State private var isTripLoaderPresented = false
    @State private var selectedTab: Tab = .map
    @State private var isMyPageSubpagePresented = false
    @State private var shouldAutoOpenShareInbox = false
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        content
            .tint(FlowneyTheme.accent)
            .font(FlowneyFont.body)
            .preferredColorScheme((AppearanceMode(rawValue: appearanceModeRaw) ?? .system).colorScheme)
            .onAppear { store.send(.auth(.onAppear)) }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    consumeAutoOpenShareInboxFlagIfNeeded()
                }
            }
    }

    private static let tempSampleDataPreviewBypass = false

    @ViewBuilder
    private var content: some View {
        if Self.tempSampleDataPreviewBypass {
            mainTabScaffold
                .onAppear { seedTempSampleDataIfNeeded() }
        } else if store.auth.isCheckingSession {
            SplashView()
        } else if store.auth.isSignedIn {
            mainTabScaffold
                .onAppear {
                    consumeAutoOpenShareInboxFlagIfNeeded()
                    // Task { await loadLastTripIfNeeded() }
                }
        } else {
            AuthView(store: store.scope(state: \.auth, action: \.auth))
        }
    }

    private func seedTempSampleDataIfNeeded() {
        guard currentTrip == nil else { return }
        currentTrip = SampleTravelData.trip

        itineraryStore = Store(initialState: ItineraryFeature.State(trip: SampleTravelData.trip)) {
            ItineraryFeature()
        } withDependencies: {
            $0.tripsRepository.fetchDays = { _ in SampleTravelData.days }
            $0.tripsRepository.fetchCountries = { _ in SampleTravelData.countries }
            $0.itineraryRepository.fetchAllItems = { _ in SampleTravelData.items }
            $0.budgetEntryRepository.fetchAllEntries = { _ in SampleTravelData.budgetEntries }
        }

        budgetStore = Store(initialState: BudgetFeature.State(trip: SampleTravelData.trip)) {
            BudgetFeature()
        } withDependencies: {
            $0.itineraryRepository.fetchAllItems = { _ in SampleTravelData.items }
            $0.budgetEntryRepository.fetchAllEntries = { _ in SampleTravelData.budgetEntries }
            $0.tripsRepository.fetchDays = { _ in SampleTravelData.days }
        }

        memoStore = Store(initialState: MemoFeature.State(trip: SampleTravelData.trip)) {
            MemoFeature()
        } withDependencies: {
            $0.memoItemRepository.fetchAllItems = { _ in [] }
        }
    }

    private var mainTabScaffold: some View {
        return ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        NavigationStack {
                            tabView(for: tab)
                        }
                        .tag(tab)
                        .toolbarBackground(.hidden, for: .tabBar)
                    }
                }
                .toolbar(.hidden, for: .tabBar)

                if !(selectedTab == .myPage && isMyPageSubpagePresented) {
                    floatingTabBar
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    @ViewBuilder
    private func tabView(for tab: Tab) -> some View {
        Group {
            switch tab {
            case .map: mapTab
            case .list: listTab
            case .budget: budgetTab
            case .memo: memoTab
            case .myPage: myTab
            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 20) }
    }

    private var floatingTabBar: some View {
        HStack(spacing: FlowneySpacing.sm) {
            HStack(spacing: 0) {
                floatingTabButton(.map, icon: "map", label: "지도")
                floatingTabButton(.list, icon: "list.bullet", label: "리스트")
                floatingTabButton(.budget, icon: "wonsign.circle", label: "예산")
                floatingTabButton(.memo, icon: "checklist", label: "메모")
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(FlowneyTheme.surface)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            )

            HStack(spacing: 0) {
                floatingTabButton(.myPage, icon: "person.crop.circle", label: "마이")
            }
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(FlowneyTheme.surface)
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
            )
        }
        .padding(.horizontal, FlowneySpacing.lg)
        .padding(.bottom, FlowneySpacing.xs)
    }

    private static let floatingTabButtonWidth: CGFloat = 64
    private static let floatingTabButtonHighlightWidth: CGFloat = 52

    private func floatingTabButton(_ tab: Tab, icon: String, label: String) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(FlowneyFont.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(isSelected ? FlowneyTheme.accent : FlowneyTheme.textSecondary)
            .padding(.vertical, 6)
            .frame(width: Self.floatingTabButtonHighlightWidth)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(FlowneyTheme.fill)
                }
            }
            .frame(width: Self.floatingTabButtonWidth)
        }
        .buttonStyle(.plain)
    }

    private var mapTab: some View {
//        NavigationStack {
            ItineraryView(store: itineraryStore) {
                isTripLoaderPresented = true
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

    // private func loadLastTripIfNeeded() async {
    //     guard currentTrip == nil, let lastTripID = LastTripStore.read() else { return }
    //     guard let trip = try? await tripsRepository.fetchTrip(lastTripID) else { return }
    //     guard currentTrip == nil else { return }
    //     selectTrip(trip)
    // }

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
        memoStore = Store(initialState: MemoFeature.State(trip: trip)) {
            MemoFeature()
        }
    }

    private var listTab: some View {
        ItineraryListView(
            store: itineraryStore,
            onTripListRequested: { isTripLoaderPresented = true },
            onViewOnMapRequested: { dayID, itemID in
                itineraryStore.send(.dayTabTapped(dayID))
                itineraryStore.send(.selectStopTapped(itemID))
                itineraryStore.send(.listSelectionCleared)
                selectedTab = .map
            }
        )
    }

    private var budgetTab: some View {
        Group {
            if let budgetStore {
                BudgetView(store: budgetStore, onTripListRequested: { isTripLoaderPresented = true })
            } else {
                FlowneyTripLoadEmptyStateView(icon: "wonsign.circle") {
                    isTripLoaderPresented = true
                }
                .flowneyLeadingTitle("예산")
            }
        }
    }

    private var memoTab: some View {
        Group {
            if let memoStore {
                MemoView(store: memoStore, onTripListRequested: { isTripLoaderPresented = true })
            } else {
                FlowneyTripLoadEmptyStateView(icon: "checklist") {
                    isTripLoaderPresented = true
                }
                .flowneyLeadingTitle("메모")
            }
        }
    }
    
    private var myTab: some View {
        MyPageView(
            store: store.scope(state: \.auth, action: \.auth),
            currentTripID: currentTrip?.id,
            isSubpagePresented: $isMyPageSubpagePresented,
            autoOpenShareInbox: $shouldAutoOpenShareInbox
        )
    }
}
