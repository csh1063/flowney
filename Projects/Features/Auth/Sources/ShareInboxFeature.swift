import AddItem
import APIClient
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct ShareInboxFeature {
    @ObservableState
    public struct State: Equatable {
        public var shares: IdentifiedArrayOf<PendingShare> = []
        public var errorMessage: String?

        public var previews: [PendingShare.ID: LinkPreview] = [:]
        public var previewFailedIDs: Set<PendingShare.ID> = []

        public var resolvedPlaces: [PendingShare.ID: ResolvedPlace] = [:]
        public var resolveFailedIDs: Set<PendingShare.ID> = []

        public var addItemFlowRequest: AddItemFlowFeature.State?
        public var addItemFlowRequestShareID: PendingShare.ID?

        public var defaultTripID: Trip.ID?

        public init(defaultTripID: Trip.ID?) {
            self.defaultTripID = defaultTripID
        }
    }

    public enum Action {
        case onAppear
        case rowAppeared(PendingShare)
        case previewResponse(PendingShare.ID, Result<LinkPreview, any Error>)
        case resolveResponse(PendingShare.ID, Result<ResolvedPlace, any Error>)
        case rowTapped(PendingShare)
        case deleteShare(PendingShare.ID)
        case addItemFlowRequestConsumed
        case itemAdded(PendingShare.ID)
    }

    @Dependency(\.linkPreviewClient) var linkPreviewClient
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
                var effects: [Effect<Action>] = []
                if state.previews[share.id] == nil, !state.previewFailedIDs.contains(share.id) {
                    effects.append(.run { send in
                        do {
                            let preview = try await linkPreviewClient.fetch(share.urlString)
                            await send(.previewResponse(share.id, .success(preview)))
                        } catch {
                            await send(.previewResponse(share.id, .failure(error)))
                        }
                    })
                }
                if state.resolvedPlaces[share.id] == nil, !state.resolveFailedIDs.contains(share.id) {
                    effects.append(.run { send in
                        do {
                            let place = try await placeResolverAPIClient.resolve(share.urlString)
                            await send(.resolveResponse(share.id, .success(place)))
                        } catch {
                            await send(.resolveResponse(share.id, .failure(error)))
                        }
                    })
                }
                return .merge(effects)

            case let .previewResponse(id, .success(preview)):
                state.previews[id] = preview
                return .none

            case let .previewResponse(id, .failure):
                state.previewFailedIDs.insert(id)
                return .none

            case let .resolveResponse(id, .success(place)):
                state.resolvedPlaces[id] = place
                return .none

            case let .resolveResponse(id, .failure):
                state.resolveFailedIDs.insert(id)
                return .none

            case let .rowTapped(share):
                state.addItemFlowRequest = AddItemFlowFeature.State(
                    defaultTripID: state.defaultTripID,
                    mode: .link,
                    linkURLText: share.urlString,
                    prefillName: state.previews[share.id]?.name ?? "",
                    prefillResolvedPlace: state.resolvedPlaces[share.id]
                )
                state.addItemFlowRequestShareID = share.id
                return .none

            case let .deleteShare(id):
                state.shares.remove(id: id)
                PendingShareStore.remove(id: id)
                return .none

            case .addItemFlowRequestConsumed:
                state.addItemFlowRequest = nil
                return .none

            case let .itemAdded(shareID):
                PendingShareStore.markAdded(id: shareID)
                state.shares[id: shareID]?.hasBeenAdded = true
                state.addItemFlowRequestShareID = nil
                return .none
            }
        }
    }
}
