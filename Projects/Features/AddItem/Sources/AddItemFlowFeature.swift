import APIClient
import ComposableArchitecture
import Foundation
import Models

/// "일정 추가"를 감싸는 마법사 — 여행/날짜가 아직 안 정해졌으면 여행 목록 → 달력 순으로
/// 고르게 하고, 둘 다 정해지면(또는 호출한 쪽이 이미 알고 있으면) 곧바로 입력 폼을 보여준다.
/// 상단 헤더(여행/날짜)는 언제든 다시 탭해서 대상을 바꿀 수 있다.
@Reducer
public struct AddItemFlowFeature {
    public enum Step: Equatable {
        case tripList
        case calendar
        case form
    }

    @ObservableState
    public struct State: Equatable {
        public var step: Step
        public var selectedTrip: Trip?
        public var selectedDay: TripDay?
        /// 지도 탭에 지금 불러와져있는 여행 — 여행 목록에서 시각적 힌트로만 쓰고, 자동으로
        /// 건너뛰지는 않는다(공유 링크함에서 들어올 때도 항상 목록부터 보여달라는 요청).
        public var defaultTripID: Trip.ID?
        public var mode: AddItemFeature.Mode
        public var linkURLText: String
        /// 공유 링크함에서 이미 og:title로 뽑아둔 이름이 있으면 폼의 이름 필드를 미리
        /// 채워준다 — 사용자가 "가져오기"를 또 누르지 않아도 되게.
        public var prefillName: String

        public var trips: IdentifiedArrayOf<Trip> = []
        public var isLoadingTrips = false
        public var days: IdentifiedArrayOf<TripDay> = []
        public var isLoadingDays = false
        public var errorMessage: String?

        // 다른 화면들과 동일한 패턴 — View가 이 값을 관찰해서 AddItemFeature Store를 한 번만
        // 만들고 바로 `.addItemRequestConsumed`를 보낸다.
        public var addItemRequest: AddItemFeature.State?

        public var isEditing: Bool = false

        /// 여행/날짜를 이미 아는 경우(지도 탭 + 버튼) `trip`/`day`/`startingSortOrder`를 모두
        /// 넘기면 네트워크 호출 없이 곧장 폼 단계로 시작한다. 모르는 경우(공유 링크함)는
        /// `nil`로 두면 여행 목록부터 시작한다.
        public init(
            trip: Trip? = nil,
            day: TripDay? = nil,
            startingSortOrder: Int? = nil,
            defaultTripID: Trip.ID? = nil,
            mode: AddItemFeature.Mode = .manual,
            linkURLText: String = "",
            prefillName: String = ""
        ) {
            selectedTrip = trip
            selectedDay = day
            self.defaultTripID = defaultTripID ?? trip?.id
            self.mode = mode
            self.linkURLText = linkURLText
            self.prefillName = prefillName
            if let trip, let day, let startingSortOrder {
                step = .form
                var addItemState = AddItemFeature.State(tripID: trip.id, dayID: day.id, startingSortOrder: startingSortOrder)
                addItemState.mode = mode
                addItemState.linkURLText = linkURLText
                addItemState.name = prefillName
                addItemRequest = addItemState
            } else {
                step = .tripList
                // 처음 열릴 때부터 여행 목록 단계로 곧장 시작한다 — 로딩 중임을 바로
                // 표시해서, fetch 응답이 오기 전 잠깐 "등록된 여행이 없어요" 빈 상태가
                // 스쳐 지나가며 마치 뭔가 눌러야 시작하는 것처럼 보이는 걸 막는다.
                isLoadingTrips = true
            }
        }

        public init(editingItem item: ItineraryItem, trip: Trip, day: TripDay) {
            selectedTrip = trip
            selectedDay = day
            defaultTripID = trip.id
            mode = .manual
            linkURLText = ""
            prefillName = ""
            isEditing = true
            step = .form
            addItemRequest = AddItemFeature.State(editing: item, tripID: trip.id, dayID: day.id)
        }
    }

    public enum Action {
        case onAppear
        case tripsResponse(Result<[Trip], any Error>)
        case tripRowTapped(Trip)
        case daysResponse(Result<[TripDay], any Error>)
        case dayCellTapped(TripDay)
        case dayItemCountResponse(TripDay, Result<Int, any Error>)
        case headerTripTapped
        case headerDayTapped
        case backToFormTapped
        case addItemRequestConsumed
    }

    @Dependency(\.tripsRepository) var tripsRepository
    @Dependency(\.itineraryRepository) var itineraryRepository

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // `isLoadingTrips`는 처음 열릴 때 트립 목록 단계로 시작하면 init에서 이미
                // true로 세팅돼있을 수 있어서(빈 상태 깜빡임 방지용), 여기서는 fetch를
                // 막는 조건으로 안 쓴다 — `trips.isEmpty`만 본다.
                guard state.trips.isEmpty else { return .none }
                state.isLoadingTrips = true
                return .run { send in
                    do {
                        let trips = try await tripsRepository.fetchTrips()
                        await send(.tripsResponse(.success(trips)))
                    } catch {
                        await send(.tripsResponse(.failure(error)))
                    }
                }

            case let .tripsResponse(.success(trips)):
                state.isLoadingTrips = false
                state.trips = IdentifiedArrayOf(uniqueElements: trips)
                return .none

            case let .tripsResponse(.failure(error)):
                state.isLoadingTrips = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .tripRowTapped(trip):
                state.selectedTrip = trip
                state.selectedDay = nil
                state.days = []
                state.step = .calendar
                state.isLoadingDays = true
                return .run { send in
                    do {
                        let days = try await tripsRepository.fetchDays(trip.id)
                        await send(.daysResponse(.success(days)))
                    } catch {
                        await send(.daysResponse(.failure(error)))
                    }
                }

            case let .daysResponse(.success(days)):
                state.isLoadingDays = false
                state.days = IdentifiedArrayOf(uniqueElements: days.sorted { $0.dayIndex < $1.dayIndex })
                return .none

            case let .daysResponse(.failure(error)):
                state.isLoadingDays = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .dayCellTapped(day):
                state.selectedDay = day
                return .run { send in
                    do {
                        let items = try await itineraryRepository.fetchDayItems(day.id)
                        await send(.dayItemCountResponse(day, .success(items.count)))
                    } catch {
                        await send(.dayItemCountResponse(day, .failure(error)))
                    }
                }

            case let .dayItemCountResponse(day, .success(count)):
                // 빠르게 다른 날짜를 연달아 눌렀을 때, 먼저 보낸 요청이 늦게 돌아와서
                // 나중 선택을 덮어쓰지 않도록 가드.
                guard day.id == state.selectedDay?.id, let trip = state.selectedTrip else { return .none }
                var addItemState = AddItemFeature.State(tripID: trip.id, dayID: day.id, startingSortOrder: count)
                addItemState.mode = state.mode
                addItemState.linkURLText = state.linkURLText
                addItemState.name = state.prefillName
                state.addItemRequest = addItemState
                state.step = .form
                return .none

            case let .dayItemCountResponse(_, .failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .headerTripTapped:
                state.step = .tripList
                guard state.trips.isEmpty, !state.isLoadingTrips else { return .none }
                state.isLoadingTrips = true
                return .run { send in
                    do {
                        let trips = try await tripsRepository.fetchTrips()
                        await send(.tripsResponse(.success(trips)))
                    } catch {
                        await send(.tripsResponse(.failure(error)))
                    }
                }

            case .headerDayTapped:
                guard let trip = state.selectedTrip else { return .none }
                state.step = .calendar
                guard state.days.isEmpty, !state.isLoadingDays else { return .none }
                state.isLoadingDays = true
                return .run { send in
                    do {
                        let days = try await tripsRepository.fetchDays(trip.id)
                        await send(.daysResponse(.success(days)))
                    } catch {
                        await send(.daysResponse(.failure(error)))
                    }
                }

            case .backToFormTapped:
                state.step = .form
                return .none

            case .addItemRequestConsumed:
                state.addItemRequest = nil
                return .none
            }
        }
    }
}
