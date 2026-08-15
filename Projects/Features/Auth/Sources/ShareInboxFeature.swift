import AddItem
import APIClient
import ComposableArchitecture
import Foundation
import Models

/// 마이페이지 "공유 링크" 메뉴에서 들어오는 공유 링크함. 구글맵 공유 확장으로 들어온 링크들을
/// 모아 보여주고, 하나를 고르면 일정 추가 마법사(`AddItemFlowFeature`)가 여행/날짜 선택부터
/// 진행한다.
///
/// 링크는 일정 추가에 써도 목록에서 지워지지 않는다 — 사용자가 스와이프로 직접 지우기 전까지
/// 계속 남는다. `hasBeenAdded`는 "이 링크로 어느 여행이든 한 번이라도 추가된 적 있는지"를
/// 나타내는 뱃지 플래그일 뿐, 목록에서 빠지는 조건이 아니다.
@Reducer
public struct ShareInboxFeature {
    @ObservableState
    public struct State: Equatable {
        public var shares: IdentifiedArrayOf<PendingShare> = []
        public var errorMessage: String?

        // og:title/og:image로 만든 행별 미리보기 — 실패한 건 재요청하지 않도록 별도로 추적.
        public var previews: [PendingShare.ID: LinkPreview] = [:]
        public var previewFailedIDs: Set<PendingShare.ID> = []

        // `@Presents`/`ifLet` 대신 View가 직접 AddItemFlowFeature Store를 소유하는 이 프로젝트의
        // 공통 패턴(project_tca_presents_crash 참고) — 여기서는 트리거만 들고 있는다.
        public var addItemFlowRequest: AddItemFlowFeature.State?
        // 그 요청이 어느 PendingShare에서 시작됐는지 — 저장 완료 시 뱃지를 지우는 데 쓴다.
        public var addItemFlowRequestShareID: PendingShare.ID?

        /// 지도 탭에 지금 불러와져있는 여행 — 마법사의 여행 목록에서 힌트로만 쓰인다.
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
