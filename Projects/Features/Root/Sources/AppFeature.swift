import APIClient
import AuthFeature
import ComposableArchitecture
import Foundation
import TripList

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var auth = AuthFeature.State()
        public var tripList = TripListFeature.State()
        public var isOffline = false

        public init() {}
    }

    public enum Action {
        case auth(AuthFeature.Action)
        case tripList(TripListFeature.Action)
        case networkMonitorStarted
        case connectivityChanged(Bool)
    }

    private enum CancelID {
        case networkMonitor
    }

    @Dependency(\.networkMonitorClient) var networkMonitorClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Scope(state: \.tripList, action: \.tripList) {
            TripListFeature()
        }
        Reduce { state, action in
            switch action {
            case .networkMonitorStarted:
                return .run { send in
                    for await isConnected in networkMonitorClient.connectivityChanges() {
                        await send(.connectivityChanged(isConnected))
                    }
                }
                .cancellable(id: CancelID.networkMonitor, cancelInFlight: true)

            case let .connectivityChanged(isConnected):
                state.isOffline = !isConnected
                return .none

            case .auth, .tripList:
                return .none
            }
        }
    }
}
