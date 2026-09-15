import APIClient
import ComposableArchitecture
import Foundation
import Models

/// Raw data needed to open the add-item flow for an accepted share. Kept free of any
/// `AddItem` module types so the Auth module doesn't need to depend on AddItem — the
/// caller (Root) is responsible for turning this into an `AddItemFlowFeature.State`.
public struct AddItemFromShareRequest: Equatable {
    public let shareID: PendingShare.ID
    public let defaultTripID: Trip.ID?
    public let linkURLText: String
    public let prefillName: String
    public let prefillResolvedPlace: ResolvedPlace?
}

@Reducer
public struct ShareInboxFeature {
    @ObservableState
    public struct State: Equatable {
        public var shares: IdentifiedArrayOf<PendingShare> = []
        public var errorMessage: String?

        public var resolvedPlaces: [PendingShare.ID: ResolvedPlace] = [:]
        public var resolveFailedIDs: Set<PendingShare.ID> = []

        public var defaultTripID: Trip.ID?

        public init(defaultTripID: Trip.ID?) {
            self.defaultTripID = defaultTripID
        }
    }

    public enum Action {
        case onAppear
        case rowAppeared(PendingShare)
        case resolveResponse(PendingShare.ID, Result<ResolvedPlace, any Error>)
        case deleteShare(PendingShare.ID)
        case itemAdded(PendingShare.ID)
    }

    @Dependency(\.placeResolverAPIClient) var placeResolverAPIClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.shares = IdentifiedArrayOf(uniqueElements: PendingShareStore.list())
                FlowneyLog.debug("공유함 목록 로드 count=\(state.shares.count)", category: .share)
                return .none

            case let .rowAppeared(share):
                guard state.resolvedPlaces[share.id] == nil, !state.resolveFailedIDs.contains(share.id) else {
                    return .none
                }
                return .run { send in
                    do {
                        let place = try await placeResolverAPIClient.resolve(share.urlString)
                        await send(.resolveResponse(share.id, .success(place)))
                    } catch {
                        await send(.resolveResponse(share.id, .failure(error)))
                    }
                }

            case let .resolveResponse(id, .success(place)):
                state.resolvedPlaces[id] = place
                return .none

            case let .resolveResponse(id, .failure):
                state.resolveFailedIDs.insert(id)
                return .none

            case let .deleteShare(id):
                state.shares.remove(id: id)
                PendingShareStore.remove(id: id)
                return .none

            case let .itemAdded(shareID):
                PendingShareStore.markAdded(id: shareID)
                state.shares[id: shareID]?.hasBeenAdded = true
                return .none
            }
        }
    }
}
