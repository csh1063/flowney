import APIClient
import ComposableArchitecture
import Foundation
import Models
import UIKit

@Reducer
public struct TripShareFeature {
    @ObservableState
    public struct State: Equatable {
        public var tripId: Trip.ID
        public var visibility: TripShare.Visibility = .pub
        public var password: String = ""
        public var share: TripShare?
        public var isLoading = false
        public var isSaving = false
        public var errorMessage: String?
        public var didCopyLink = false

        public init(tripId: Trip.ID) {
            self.tripId = tripId
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case shareResponse(Result<TripShare?, any Error>)
        case generateButtonTapped
        case upsertResponse(Result<TripShare, any Error>)
        case revokeButtonTapped
        case revokeResponse(Result<Void, any Error>)
        case copyLinkButtonTapped
    }

    @Dependency(\.tripShareRepository) var tripShareRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = true
                let tripID = state.tripId
                return .run { send in
                    await send(.shareResponse(Result { try await tripShareRepository.fetchShare(tripID) }))
                }

            case let .shareResponse(.success(share)):
                state.isLoading = false
                state.share = share
                if let share {
                    state.visibility = share.visibility
                }
                return .none

            case let .shareResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .generateButtonTapped:
                state.isSaving = true
                state.errorMessage = nil
                let tripID = state.tripId
                let visibility = state.visibility
                let password = visibility == .password && !state.password.isEmpty ? state.password : nil
                return .run { send in
                    await send(.upsertResponse(Result { try await tripShareRepository.upsertShare(tripID, visibility, password) }))
                }

            case let .upsertResponse(.success(share)):
                state.isSaving = false
                state.share = share
                state.password = ""
                return .none

            case let .upsertResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none

            case .revokeButtonTapped:
                state.isSaving = true
                state.errorMessage = nil
                let tripID = state.tripId
                return .run { send in
                    await send(.revokeResponse(Result { try await tripShareRepository.revokeShare(tripID) }))
                }

            case .revokeResponse(.success):
                state.isSaving = false
                state.share = nil
                return .none

            case let .revokeResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none

            case .copyLinkButtonTapped:
                guard let url = state.share?.shareURL else { return .none }
                UIPasteboard.general.string = url.absoluteString
                state.didCopyLink = true
                return .none
            }
        }
    }
}
