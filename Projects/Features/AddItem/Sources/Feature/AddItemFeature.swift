import APIClient
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct AddItemFeature {
    public enum Mode: String, CaseIterable, Equatable {
        case manual
        case link
        case reuse

        public var displayName: String {
            switch self {
            case .manual: return "직접 입력"
            case .link: return "링크로 가져오기"
            case .reuse: return "기존 장소"
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
        public var savedItem: ItineraryItem?

        public var linkURLText: String = ""
        public var isResolvingLink: Bool = false
        public var resolvedLat: Double?
        public var resolvedLng: Double?
        public var resolvedPlaceId: String?
        public var linkResolveErrorMessage: String?

        public var editingOriginalItem: ItineraryItem?

        public var reuseCandidates: [ItineraryItem] = []
        public var isLoadingReuseCandidates: Bool = false

        public var dedupedReuseCandidates: [ItineraryItem] {
            var seen: Set<String> = []
            var result: [ItineraryItem] = []
            for item in reuseCandidates {
                guard let lat = item.lat, let lng = item.lng else { continue }
                let key = "\((lat * 100_000).rounded())_\((lng * 100_000).rounded())"
                guard !seen.contains(key) else { continue }
                seen.insert(key)
                result.append(item)
            }
            return result.sorted { lhs, rhs in
                if (lhs.itemType == .lodge) != (rhs.itemType == .lodge) {
                    return lhs.itemType == .lodge
                }
                return lhs.name < rhs.name
            }
        }

        public init(tripID: Trip.ID, dayID: TripDay.ID, startingSortOrder: Int) {
            self.tripID = tripID
            self.dayID = dayID
            self.startingSortOrder = startingSortOrder
        }

        public init(editing item: ItineraryItem, tripID: Trip.ID, dayID: TripDay.ID) {
            self.tripID = tripID
            self.dayID = dayID
            startingSortOrder = item.sortOrder
            editingOriginalItem = item
            name = item.name
            itemType = item.itemType
            arrivalMode = item.arrivalMode
            if let startTimeString = item.startTime, let date = AddItemFeature.timeFormatter.date(from: startTimeString) {
                hasStartTime = true
                startTime = date
            }
            costAmountText = item.costAmount.map { "\($0)" } ?? ""
            costCurrency = item.costCurrency ?? "KRW"
            costAmountKRWText = item.costAmountKRW.map { "\($0)" } ?? ""
            costCategory = item.costCategory
            paymentStatus = item.paymentStatus
            address = item.address ?? ""
            notes = item.notes ?? ""
            resolvedLat = item.lat
            resolvedLng = item.lng
            resolvedPlaceId = item.placeId
        }

        public mutating func applyResolvedPlace(_ place: ResolvedPlace?) {
            guard let place else { return }
            if name.isEmpty { name = place.name }
            address = place.address ?? address
            resolvedLat = place.lat
            resolvedLng = place.lng
            resolvedPlaceId = place.placeId
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case modeChanged(Mode)
        case resolveLinkButtonTapped
        case resolveLinkResponse(Result<ResolvedPlace, any Error>)
        case reuseCandidatesResponse(Result<[ItineraryItem], any Error>)
        case reuseCandidateTapped(ItineraryItem)
        case saveButtonTapped
        case cancelButtonTapped
        case saveResponse(Result<ItineraryItem, any Error>)
        case contextChanged(tripID: Trip.ID, dayID: TripDay.ID, startingSortOrder: Int)
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

            case let .modeChanged(newMode):
                state.mode = newMode
                guard newMode == .reuse, state.reuseCandidates.isEmpty, !state.isLoadingReuseCandidates else { return .none }
                state.isLoadingReuseCandidates = true
                return .run { [tripID = state.tripID] send in
                    do {
                        let items = try await itineraryRepository.fetchAllItems(tripID)
                        await send(.reuseCandidatesResponse(.success(items)))
                    } catch {
                        await send(.reuseCandidatesResponse(.failure(error)))
                    }
                }

            case let .reuseCandidatesResponse(.success(items)):
                state.isLoadingReuseCandidates = false
                state.reuseCandidates = items
                return .none

            case let .reuseCandidatesResponse(.failure(error)):
                state.isLoadingReuseCandidates = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .reuseCandidateTapped(item):
                state.name = item.name
                state.itemType = item.itemType
                state.address = item.address ?? state.address
                state.resolvedLat = item.lat
                state.resolvedLng = item.lng
                state.resolvedPlaceId = item.placeId
                return .none

            case .resolveLinkButtonTapped:
                let trimmed = state.linkURLText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    state.linkResolveErrorMessage = "구글맵 공유 링크를 붙여넣어주세요."
                    return .none
                }
                state.linkURLText = trimmed
                state.linkResolveErrorMessage = nil
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
                state.linkResolveErrorMessage = nil
                state.name = place.name
                state.address = place.address ?? state.address
                state.resolvedLat = place.lat
                state.resolvedLng = place.lng
                state.resolvedPlaceId = place.placeId
                return .none

            case .resolveLinkResponse(.failure):
                state.isResolvingLink = false
                state.linkResolveErrorMessage = "링크를 해석하지 못했어요. 링크를 확인하거나 직접 입력해주세요."
                return .none

            case .saveButtonTapped:
                guard !state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.errorMessage = "이름을 입력해주세요."
                    return .none
                }
                guard state.costAmountText.isEmpty || (state.costCategory != nil && state.paymentStatus != nil) else {
                    state.errorMessage = "금액을 입력했으면 카테고리와 결제 상태도 선택해주세요."
                    return .none
                }
                state.errorMessage = nil
                state.isSaving = true

                let costAmount = Decimal(string: state.costAmountText)
                let costAmountKRW: Decimal? =
                    if let explicit = Decimal(string: state.costAmountKRWText) {
                        explicit
                    } else if state.costCurrency.uppercased() == "KRW" {
                        costAmount
                    } else {
                        nil
                    }
                let startTimeString = state.hasStartTime ? Self.timeFormatter.string(from: state.startTime) : nil
                let costCurrency = state.costAmountText.isEmpty ? nil : state.costCurrency
                let address = state.address.isEmpty ? nil : state.address
                let notes = state.notes.isEmpty ? nil : state.notes

                let item: ItineraryItem
                if var original = state.editingOriginalItem {
                    original.itemType = state.itemType
                    original.arrivalMode = state.arrivalMode
                    original.name = state.name
                    original.address = address
                    if original.lat != state.resolvedLat || original.lng != state.resolvedLng {
                        original.countryCode = nil
                    }
                    original.lat = state.resolvedLat
                    original.lng = state.resolvedLng
                    original.placeId = state.resolvedPlaceId
                    if state.mode == .link || state.mode == .reuse, state.resolvedLat != nil {
                        original.source = state.mode == .reuse ? .reuse : .link
                        original.sourceURL = state.mode == .link ? state.linkURLText : nil
                    }
                    original.startTime = startTimeString
                    original.costAmount = costAmount
                    original.costCurrency = costCurrency
                    original.costAmountKRW = costAmountKRW
                    original.costCategory = state.costCategory
                    original.paymentStatus = state.paymentStatus
                    original.notes = notes
                    item = original
                } else {
                    let hasResolvedLocation = (state.mode == .link || state.mode == .reuse) && state.resolvedLat != nil && state.resolvedLng != nil
                    item = ItineraryItem(
                        id: uuid(),
                        tripId: state.tripID,
                        dayId: state.dayID,
                        sortOrder: state.startingSortOrder,
                        itemType: state.itemType,
                        arrivalMode: state.arrivalMode,
                        name: state.name,
                        placeId: hasResolvedLocation ? state.resolvedPlaceId : nil,
                        lat: hasResolvedLocation ? state.resolvedLat : nil,
                        lng: hasResolvedLocation ? state.resolvedLng : nil,
                        address: address,
                        source: state.mode == .reuse ? .reuse : (hasResolvedLocation ? .link : .manual),
                        sourceURL: state.mode == .link && hasResolvedLocation ? state.linkURLText : nil,
                        startTime: startTimeString,
                        costAmount: costAmount,
                        costCurrency: costCurrency,
                        costAmountKRW: costAmountKRW,
                        costCategory: state.costCategory,
                        paymentStatus: state.paymentStatus,
                        notes: notes
                    )
                }

                let isEditing = state.editingOriginalItem != nil
                return .run { send in
                    do {
                        let saved = isEditing
                            ? try await itineraryRepository.updateItem(item)
                            : try await itineraryRepository.createItem(item)
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

            case let .contextChanged(tripID, dayID, startingSortOrder):
                state.tripID = tripID
                state.dayID = dayID
                state.startingSortOrder = startingSortOrder
                return .none

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
