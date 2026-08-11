import AuthFeature
import Budget
import ComposableArchitecture
import Itinerary
import Models
import SwiftUI
import TripList

public struct RootView: View {
    @Bindable var store: StoreOf<AppFeature>

    // 순수 SwiftUI `@State` 배열로 내비게이션 스택을 직접 관리한다. 각 화면의 Store는
    // push되는 시점에 한 번만 만들어지고, UUID로 안정된 identity를 유지한다.
    //
    // 중요: `.navigationDestination(for:)`는 반드시 `NavigationStack`의 **안쪽 루트 콘텐츠
    // 뷰**에 붙여야 한다. `NavigationStack { ... }` 뒤에 바깥에서 체이닝하면 이 프로젝트가
    // 쓰는 Xcode 26.3 SwiftUI에서 push된 화면이 빈 채로 렌더링되지 않고 경고 아이콘만 뜨는
    // 버그가 있다 — TCA/Waypin 코드와 무관한 최소 재현(순정 SwiftUI 10줄)으로 확인됨.
    // 안쪽에 붙이면 정상 동작한다.
    private enum Route: Hashable, Identifiable {
        case itinerary(id: UUID, store: StoreOf<ItineraryFeature>)
        case budget(id: UUID, store: StoreOf<BudgetFeature>)

        var id: UUID {
            switch self {
            case let .itinerary(id, _): id
            case let .budget(id, _): id
            }
        }

        static func == (lhs: Route, rhs: Route) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    @State private var path: [Route] = []

    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }

    public var body: some View {
        if store.auth.isSignedIn {
            NavigationStack(path: $path) {
                TripListView(store: store.scope(state: \.tripList, action: \.tripList)) { trip in
                    let itineraryStore = Store(initialState: ItineraryFeature.State(trip: trip)) {
                        ItineraryFeature()
                    }
                    path.append(.itinerary(id: UUID(), store: itineraryStore))
                }
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case let .itinerary(_, itineraryStore):
                        ItineraryView(
                            store: itineraryStore,
                            onBudgetRequested: { trip in
                                let budgetStore = Store(initialState: BudgetFeature.State(trip: trip)) {
                                    BudgetFeature()
                                }
                                path.append(.budget(id: UUID(), store: budgetStore))
                            }
                        )
                    case let .budget(_, budgetStore):
                        BudgetView(store: budgetStore)
                    }
                }
            }
        } else {
            AuthView(store: store.scope(state: \.auth, action: \.auth))
        }
    }
}
