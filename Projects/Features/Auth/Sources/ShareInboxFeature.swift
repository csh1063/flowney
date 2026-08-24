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
        case rowTapped(PendingShare)
        case deleteShare(PendingShare.ID)
        case addItemFlowRequestConsumed
        case itemAdded(PendingShare.ID)
    }

    @Dependency(\.linkPreviewClient) var linkPreviewClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.shares = IdentifiedArrayOf(uniqueElements: PendingShareStore.list())
                return .none

            case let .rowAppeared(share):
                guard state.previews[share.id] == nil, !state.previewFailedIDs.contains(share.id) else { return .none }
                return .run { send in
                    do {
                        let preview = try await linkPreviewClient.fetch(share.urlString)
                        await send(.previewResponse(share.id, .success(preview)))
                    } catch {
                        await send(.previewResponse(share.id, .failure(error)))
                    }
                }

            case let .previewResponse(id, .success(preview)):
                state.previews[id] = preview
                return .none

            case let .previewResponse(id, .failure):
                state.previewFailedIDs.insert(id)
                return .none

            case let .rowTapped(share):
                state.addItemFlowRequest = AddItemFlowFeature.State(
                    defaultTripID: state.defaultTripID,
                    mode: .link,
                    linkURLText: share.urlString,
                    prefillName: state.previews[share.id]?.name ?? ""
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
