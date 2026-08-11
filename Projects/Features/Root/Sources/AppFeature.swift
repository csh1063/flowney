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

        public init() {}
    }

    public enum Action {
        case auth(AuthFeature.Action)
        case tripList(TripListFeature.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }
        Scope(state: \.tripList, action: \.tripList) {
            TripListFeature()
        }
    }
}
