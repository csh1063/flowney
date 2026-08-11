import APIClient
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct AddItemFeature {
    public enum Mode: String, CaseIterable, Equatable {
        case manual
        case link

        public var displayName: String {
            switch self {
            case .manual: return "직접 입력"
            case .link: return "링크로 가져오기"
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        public var tripID: Trip.ID
        public var dayID: TripDay.ID
        public var startingSortOrder: Int
        public var mode: Mode = .manual
        public var name: String = ""
        public var itemType: ItemType = .sight
        public var arrivalMode: TransportMode?
        public var hasStartTime: Bool = false
        public var startTime: Date = .now
        public var costAmountText: String = ""
        public var costCurrency: String = "KRW"
        public var costAmountKRWText: String = ""
        public var costCategory: CostCategory?
        public var paymentStatus: PaymentStatus?
        public var address: String = ""
        public var notes: String = ""
        public var isSaving = false
        public var errorMessage: String?
        // `@Presents`/`ifLet` 프레젠테이션 대신 부모 View가 이 필드를 직접 관찰해서
        // 저장 완료를 감지한다 (TripEditFeature.savedTrip과 동일한 패턴).
        public var savedItem: ItineraryItem?

        // 링크 모드 전용
        public var linkURLText: String = ""
        public var isResolvingLink: Bool = false
        public var resolvedLat: Double?
        public var resolvedLng: Double?
        public var resolvedPlaceId: String?

        public init(tripID: Trip.ID, dayID: TripDay.ID, startingSortOrder: Int) {
            self.tripID = tripID
            self.dayID = dayID
            self.startingSortOrder = startingSortOrder
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case resolveLinkButtonTapped
        case resolveLinkResponse(Result<ResolvedPlace, any Error>)
        case saveButtonTapped
        case cancelButtonTapped
        case saveResponse(Result<ItineraryItem, any Error>)
        case delegate(Delegate)

        public enum Delegate {
            case itemAdded(ItineraryItem)
            case cancelled
        }
    }

    @Dependency(\.itineraryRepository) var itineraryRepository
    @Dependency(\.placeResolverAPIClient) var placeResolverAPIClient
    @Dependency(\.uuid) var uuid

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .resolveLinkButtonTapped:
                let trimmed = state.linkURLText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    state.errorMessage = "구글맵 공유 링크를 붙여넣어주세요."
                    return .none
                }
                state.linkURLText = trimmed
                state.errorMessage = nil
                state.isResolvingLink = true
                return .run { [trimmed] send in
                    do {
                        let place = try await placeResolverAPIClient.resolve(trimmed)
                        await send(.resolveLinkResponse(.success(place)))
                    } catch {
                        await send(.resolveLinkResponse(.failure(error)))
                    }
                }

            case let .resolveLinkResponse(.success(place)):
                state.isResolvingLink = false
                state.name = place.name
                state.address = place.address ?? state.address
                state.resolvedLat = place.lat
                state.resolvedLng = place.lng
                state.resolvedPlaceId = place.placeId
                return .none

            case .resolveLinkResponse(.failure):
                // 링크 해석 실패해도 막지 않고 직접 입력으로 계속 진행할 수 있게 유도.
                state.isResolvingLink = false
                state.mode = .manual
                state.errorMessage = "링크를 해석하지 못했어요. 이름을 직접 입력해주세요."
                return .none

            case .saveButtonTapped:
                guard !state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.errorMessage = "이름을 입력해주세요."
                    return .none
                }
                state.errorMessage = nil
                state.isSaving = true

                let hasResolvedLink = state.mode == .link && state.resolvedLat != nil && state.resolvedLng != nil
                let costAmount = Decimal(string: state.costAmountText)
                let costAmountKRW: Decimal? =
                    if let explicit = Decimal(string: state.costAmountKRWText) {
                        explicit
                    } else if state.costCurrency.uppercased() == "KRW" {
                        costAmount
                    } else {
                        nil
                    }

                let item = ItineraryItem(
                    id: uuid(),
                    tripId: state.tripID,
                    dayId: state.dayID,
                    sortOrder: state.startingSortOrder,
                    itemType: state.itemType,
                    arrivalMode: state.arrivalMode,
                    name: state.name,
                    placeId: hasResolvedLink ? state.resolvedPlaceId : nil,
                    lat: hasResolvedLink ? state.resolvedLat : nil,
                    lng: hasResolvedLink ? state.resolvedLng : nil,
                    address: state.address.isEmpty ? nil : state.address,
                    source: hasResolvedLink ? .link : .manual,
                    sourceURL: hasResolvedLink ? state.linkURLText : nil,
                    startTime: state.hasStartTime ? Self.timeFormatter.string(from: state.startTime) : nil,
                    costAmount: costAmount,
                    costCurrency: state.costAmountText.isEmpty ? nil : state.costCurrency,
                    costAmountKRW: costAmountKRW,
                    costCategory: state.costCategory,
                    paymentStatus: state.paymentStatus,
                    notes: state.notes.isEmpty ? nil : state.notes
                )

                return .run { send in
                    do {
                        let saved = try await itineraryRepository.createItem(item)
                        await send(.saveResponse(.success(saved)))
                    } catch {
                        await send(.saveResponse(.failure(error)))
                    }
                }

            case let .saveResponse(.success(item)):
                state.isSaving = false
                state.savedItem = item
                return .send(.delegate(.itemAdded(item)))

            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none

            case .cancelButtonTapped:
                return .send(.delegate(.cancelled))

            case .delegate:
                return .none
            }
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
