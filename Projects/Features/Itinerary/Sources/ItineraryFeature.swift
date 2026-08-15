import AddItem
import APIClient
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct ItineraryFeature {
    @ObservableState
    public struct State: Equatable {
        /// 지도 탭이 상시 존재하는 화면이 되면서(예전엔 여행을 고를 때만 생성됐음), 아직 여행을
        /// 안 골랐을 수도 있는 상태를 표현하려고 옵셔널로 뒀다. `nil`이면 화면이 빈 상태(지도만,
        /// "여행 불러오기" 버튼)를 그린다.
        public var trip: Trip?
        public var countries: IdentifiedArrayOf<TripCountry> = []
        public var days: IdentifiedArrayOf<TripDay> = []
        public var selectedDayID: TripDay.ID?
        public var itemsByDay: [TripDay.ID: IdentifiedArrayOf<ItineraryItem>] = [:]
        public var legsByDay: [TripDay.ID: IdentifiedArrayOf<RouteLeg>] = [:]
        public var weatherByDay: [TripDay.ID: DayWeather] = [:]
        public var isLoading = false
        public var errorMessage: String?
        // `@Presents`/`ifLet` 프레젠테이션 대신 부모 View가 이 필드를 직접 관찰해서 새
        // AddItemFlowFeature Store를 만든다 (TripListFeature/TripEditFeature와 동일한 이유·패턴 —
        // Xcode 26.3/Swift 6.2.4 + TCA 1.26.1 조합의 실기기 EXC_BAD_ACCESS 우회).
        public var addItemFlowRequest: AddItemFlowFeature.State?

        // travel_map.html의 `curIdx`를 그대로 이식한 상태 모델. nil이면 "전체보기"(오늘 동선을
        // 한눈에 보는 모드, 리스트 맨 위 항목) — 매 날짜 진입시 항상 이 상태로 시작한다(html의
        // `renderDay()`가 `curIdx = null`로 리셋하는 것과 동일). 값이 있으면 그 인덱스의 장소가
        // "현재 위치"다.
        public var currentStopIndex: Int?
        // 리스트에서 현재보다 "앞선(미래)" 장소를 탭했을 때, 한 구간씩 애니메이션하며 이동하는
        // 중간 목표. html의 `goToStop`/`stepLeg`에 해당.
        public var pendingChainTargetIndex: Int?
        /// "다음" 버튼/앞쪽 리스트 탭 — 마커가 그 구간을 실제로 이동하는 애니메이션.
        public var animateTrigger: Int = 0
        /// "이전" 버튼, 뒤쪽/전체보기 탭, 날짜 경계 이동 — 애니메이션 없이 카메라만 즉시 이동.
        public var jumpTrigger: Int = 0
        public var isAnimating: Bool = false
        public var isSearchingAllRoutes: Bool = false

        /// 여행 생성 시 고른 나라 목록에 없는 위치에 경고 아이콘을 눌렀을 때 뜨는 확인 팝업 대상.
        public var warningPopupItemID: ItineraryItem.ID?

        public var selectedItems: IdentifiedArrayOf<ItineraryItem> {
            guard let selectedDayID else { return [] }
            return itemsByDay[selectedDayID] ?? []
        }

        public var selectedDayLegs: IdentifiedArrayOf<RouteLeg> {
            guard let selectedDayID else { return [] }
            return legsByDay[selectedDayID] ?? []
        }

        public var selectedDayWeather: DayWeather? {
            guard let selectedDayID else { return nil }
            return weatherByDay[selectedDayID]
        }

        /// html의 `selectStop`/`markListState`가 쓰던 "현재 위치" 장소 id. 전체보기(nil)면 nil.
        public var selectedItemID: ItineraryItem.ID? {
            guard let currentStopIndex, selectedItems.indices.contains(currentStopIndex) else { return nil }
            return selectedItems[currentStopIndex].id
        }

        public var isFirstDay: Bool {
            selectedDayID == nil || selectedDayID == days.first?.id
        }

        public var isLastDay: Bool {
            selectedDayID == nil || selectedDayID == days.last?.id
        }

        /// html의 `updateNavButtons`와 동일한 조건.
        // html은 "이전"이 즉시이동이라 애니메이션 중에도 눌리게 뒀지만(눌리면 진행 중이던
        // 애니메이션을 끊고 즉시 이동), 이 앱에서는 명시적으로 애니메이션 중엔 이전도 막는다.
        public var isPrevDisabled: Bool {
            isAnimating || currentStopIndex == nil || ((currentStopIndex ?? 0) <= 0 && isFirstDay)
        }

        public var isNextDisabled: Bool {
            isAnimating || (currentStopIndex != nil && (currentStopIndex ?? 0) >= selectedItems.count - 1 && isLastDay)
        }

        /// 여행 생성 시 고른 나라들 — 이 목록에 없는 국가코드로 계산된 항목은 경고 대상이다.
        public var registeredCountryCodes: Set<String> {
            Set(countries.map(\.countryCode))
        }

        // `store.someMethod(x)`는 TCA의 @dynamicMemberLookup(프로퍼티 전용)을 못 타서
        // 뷰에서 직접 호출할 수 없다 — 그래서 아래 둘은 파라미터 없는 계산 프로퍼티로
        // 한 번에 전체를 만들어두고, 뷰에서는 딕셔너리/집합 조회만 한다. 둘 다
        // `ItineraryItem.countryCode`(DB에 저장된 값)에서 바로 파생시킨다 — 별도 캐시 없음.

        /// 좌표가 계산된 국가코드는 있는데 여행에 등록된 나라가 아닌 항목들의 id.
        public var unregisteredCountryItemIDs: Set<ItineraryItem.ID> {
            let registered = registeredCountryCodes
            var result: Set<ItineraryItem.ID> = []
            for items in itemsByDay.values {
                for item in items {
                    guard let code = item.countryCode, !registered.contains(code) else { continue }
                    result.insert(item.id)
                }
            }
            return result
        }

        /// 날짜 id → 그날 항목들이 순서대로 걸친, "여행에 등록된" 국가코드만 중복 없이 나열.
        /// `CountryDayHeaderView`가 이 순서대로 헤더 컬럼을 균등 분할해서 그린다.
        public var dayCountryCodes: [TripDay.ID: [String]] {
            let registered = registeredCountryCodes
            var result: [TripDay.ID: [String]] = [:]
            for day in days {
                var seen: Set<String> = []
                var codes: [String] = []
                for item in itemsByDay[day.id] ?? [] {
                    guard let code = item.countryCode, registered.contains(code), !seen.contains(code) else { continue }
                    seen.insert(code)
                    codes.append(code)
                }
                result[day.id] = codes
            }
            return result
        }

        public var warningPopupItem: ItineraryItem? {
            guard let warningPopupItemID else { return nil }
            for items in itemsByDay.values {
                if let item = items[id: warningPopupItemID] { return item }
            }
            return nil
        }

        public init(trip: Trip? = nil) {
            self.trip = trip
        }
    }

    public enum Action {
        /// 지도 탭에서 "여행 불러오기"로 여행을 고른 순간 — 기존 Store를 새로 만드는 대신
        /// (지도 탭이 이제 상시 존재하는 화면이라) 살아있는 Store에 이 액션을 보내서 여행을
        /// 채워 넣고, 곧바로 `.onAppear`와 같은 로딩을 시작한다.
        case tripSelected(Trip)
        case onAppear
        case daysResponse(Result<[TripDay], any Error>)
        case itemsResponse(Result<[ItineraryItem], any Error>)
        case countriesResponse(Result<[TripCountry], any Error>)
        case weatherResponse(TripDay.ID, Result<DayWeather, any Error>)
        case dayTabTapped(TripDay.ID)
        case addItemButtonTapped
        case addItemRequestConsumed
        case itemAdded(ItineraryItem)
        case deleteItems(IndexSet)
        case deleteItemResponse(Result<ItineraryItem.ID, any Error>)
        case itemsMovedWithinDay(IndexSet, Int)
        case itemDroppedOnDay(ItineraryItem.ID, TripDay.ID)
        case reorderPersistResponse(Result<Void, any Error>)
        case countryCodesResolved([ItineraryItem.ID: String])
        case warningIconTapped(ItineraryItem.ID)
        case warningDismissed
        case warningDeleteConfirmed(ItineraryItem.ID)

        case selectAllTapped
        case selectStopTapped(ItineraryItem.ID)
        case prevButtonTapped
        case nextButtonTapped
        case legAnimationCompleted

        case searchAllRoutesButtonTapped
        case dayRoutesResponse(TripDay.ID, Result<[RouteLeg], any Error>)
        case searchAllRoutesFinished
    }

    @Dependency(\.tripsRepository) var tripsRepository
    @Dependency(\.itineraryRepository) var itineraryRepository
    @Dependency(\.routeAPIClient) var routeAPIClient
    @Dependency(\.routeCacheClient) var routeCacheClient
    @Dependency(\.weatherAPIClient) var weatherAPIClient
    @Dependency(\.countryLookupClient) var countryLookupClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .tripSelected(trip):
                // 다른 여행으로 갈아탈 수도 있으니(마이페이지에서 여행 목록 다시 열기 등)
                // 이전 여행의 날짜/일정/경로 캐시를 전부 비우고 새로 시작한다.
                state = State(trip: trip)
                return .send(.onAppear)

            case .onAppear:
                guard let tripID = state.trip?.id else { return .none }
                state.isLoading = true
                return .run { send in
                    var days: [TripDay] = []
                    do {
                        days = try await tripsRepository.fetchDays(tripID)
                        await send(.daysResponse(.success(days)))
                    } catch {
                        await send(.daysResponse(.failure(error)))
                    }

                    var items: [ItineraryItem] = []
                    do {
                        items = try await itineraryRepository.fetchAllItems(tripID)
                        await send(.itemsResponse(.success(items)))
                    } catch {
                        await send(.itemsResponse(.failure(error)))
                    }

                    do {
                        let countries = try await tripsRepository.fetchCountries(tripID)
                        await send(.countriesResponse(.success(countries)))
                    } catch {
                        await send(.countriesResponse(.failure(error)))
                    }

                    guard !days.isEmpty, !items.isEmpty else { return }

                    // 하루하루 따로 날씨를 부르면 도시 하나에 며칠씩 머무는 여행에서 호출이
                    // 쓸데없이 많아진다. 그날 대표 좌표(그날 첫 장소)가 이어지는 연속 구간을
                    // 하나로 묶어서, 그 구간 전체를 한 번의 range 요청으로 가져온다.
                    struct DayLocation {
                        let day: TripDay
                        let lat: Double
                        let lng: Double
                    }
                    let dayLocations: [DayLocation] = days.compactMap { day in
                        guard
                            let firstItem = items
                                .filter({ $0.dayId == day.id })
                                .sorted(by: { $0.sortOrder < $1.sortOrder })
                                .first(where: { $0.lat != nil && $0.lng != nil }),
                            let lat = firstItem.lat, let lng = firstItem.lng
                        else { return nil }
                        return DayLocation(day: day, lat: lat, lng: lng)
                    }

                    var blocks: [[DayLocation]] = []
                    for location in dayLocations {
                        if let lastBlockLocation = blocks.last?.last,
                           abs(lastBlockLocation.lat - location.lat) < 0.01,
                           abs(lastBlockLocation.lng - location.lng) < 0.01 {
                            blocks[blocks.count - 1].append(location)
                        } else {
                            blocks.append([location])
                        }
                    }

                    let keyFormatter = DateFormatter()
                    keyFormatter.calendar = Calendar(identifier: .gregorian)
                    keyFormatter.locale = Locale(identifier: "en_US_POSIX")
                    keyFormatter.timeZone = TimeZone(identifier: "UTC")
                    keyFormatter.dateFormat = "yyyy-MM-dd"

                    await withTaskGroup(of: Void.self) { group in
                        for block in blocks {
                            guard let representative = block.first else { continue }
                            group.addTask {
                                do {
                                    let weatherByDate = try await weatherAPIClient.fetchWeatherRange(
                                        representative.lat,
                                        representative.lng,
                                        block.map(\.day.dayDate)
                                    )
                                    for location in block {
                                        let key = keyFormatter.string(from: location.day.dayDate)
                                        if let weather = weatherByDate[key] {
                                            await send(.weatherResponse(location.day.id, .success(weather)))
                                        } else {
                                            await send(.weatherResponse(location.day.id, .failure(WeatherAPIError.noData)))
                                        }
                                    }
                                } catch {
                                    for location in block {
                                        await send(.weatherResponse(location.day.id, .failure(error)))
                                    }
                                }
                            }
                        }
                    }
                }

            case let .daysResponse(.success(days)):
                state.days = IdentifiedArrayOf(uniqueElements: days)
                if state.selectedDayID == nil {
                    state.selectedDayID = days.first?.id
                }
                return .none

            case let .daysResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .itemsResponse(.success(items)):
                state.isLoading = false
                state.itemsByDay = Dictionary(grouping: items, by: \.dayId)
                    .mapValues { IdentifiedArrayOf(uniqueElements: $0.sorted { $0.sortOrder < $1.sortOrder }) }
                return .merge(
                    resolveCountryCodes(for: items),
                    loadCachedRoutes(days: state.days, itemsByDay: state.itemsByDay)
                )

            case let .itemsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .countriesResponse(.success(countries)):
                state.countries = IdentifiedArrayOf(uniqueElements: countries)
                return .none

            case .countriesResponse(.failure):
                // 국가 목록은 헤더 라벨용이라 실패해도 치명적이지 않다 — 조용히 무시.
                return .none

            case let .weatherResponse(dayID, .success(weather)):
                state.weatherByDay[dayID] = weather
                return .none

            case .weatherResponse(_, .failure):
                // 날씨는 부가 정보라 실패해도 조용히 무시 — 그 날짜탭에 아이콘만 안 뜬다.
                return .none

            case let .dayTabTapped(dayID):
                // html의 renderDay()도 날짜를 바꿀 때마다 항상 전체보기(curIdx = null)로 리셋한다.
                state.selectedDayID = dayID
                state.currentStopIndex = nil
                state.pendingChainTargetIndex = nil
                state.isAnimating = false
                state.jumpTrigger += 1
                return .none

            case .addItemButtonTapped:
                guard let trip = state.trip, let dayID = state.selectedDayID, let day = state.days[id: dayID] else { return .none }
                let count = state.itemsByDay[dayID]?.count ?? 0
                state.addItemFlowRequest = AddItemFlowFeature.State(trip: trip, day: day, startingSortOrder: count, defaultTripID: trip.id)
                return .none

            case .addItemRequestConsumed:
                state.addItemFlowRequest = nil
                return .none

            case let .itemAdded(item):
                state.itemsByDay[item.dayId, default: []].append(item)
                return resolveCountryCodes(for: [item])

            case let .countryCodesResolved(resolved):
                // 계산된 국가코드를 항목 자체에 반영하고 DB에 저장해서, 다음에 이 화면을
                // 열 때는 다시 지오코딩하지 않고 그대로 읽어쓴다.
                var itemsToPersist: [ItineraryItem] = []
                for (itemID, code) in resolved {
                    guard
                        let dayID = state.itemsByDay.first(where: { $0.value[id: itemID] != nil })?.key,
                        var item = state.itemsByDay[dayID]?[id: itemID]
                    else { continue }
                    item.countryCode = code
                    state.itemsByDay[dayID]?[id: itemID] = item
                    itemsToPersist.append(item)
                }
                guard !itemsToPersist.isEmpty else { return .none }
                return .run { [itineraryRepository, itemsToPersist] _ in
                    for item in itemsToPersist {
                        _ = try? await itineraryRepository.updateItem(item)
                    }
                }

            case let .warningIconTapped(itemID):
                state.warningPopupItemID = itemID
                return .none

            case .warningDismissed:
                state.warningPopupItemID = nil
                return .none

            case let .warningDeleteConfirmed(itemID):
                state.warningPopupItemID = nil
                guard let dayID = state.itemsByDay.first(where: { $0.value[id: itemID] != nil })?.key else { return .none }
                state.itemsByDay[dayID]?.remove(id: itemID)
                return .run { send in
                    do {
                        try await itineraryRepository.deleteItem(itemID)
                        await send(.deleteItemResponse(.success(itemID)))
                    } catch {
                        await send(.deleteItemResponse(.failure(error)))
                    }
                }

            case let .deleteItems(indexSet):
                guard let dayID = state.selectedDayID else { return .none }
                var items = state.itemsByDay[dayID] ?? []
                let ids = indexSet.map { items[$0].id }
                items.remove(atOffsets: indexSet)
                state.itemsByDay[dayID] = items
                return .run { send in
                    for id in ids {
                        do {
                            try await itineraryRepository.deleteItem(id)
                            await send(.deleteItemResponse(.success(id)))
                        } catch {
                            await send(.deleteItemResponse(.failure(error)))
                        }
                    }
                }

            case .deleteItemResponse(.success):
                return .none

            case let .deleteItemResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .itemsMovedWithinDay(source, destination):
                guard let dayID = state.selectedDayID else { return .none }
                var items = state.itemsByDay[dayID] ?? []
                items.move(fromOffsets: source, toOffset: destination)
                for (index, id) in items.ids.enumerated() {
                    items[id: id]?.sortOrder = index
                }
                state.itemsByDay[dayID] = items

                let updates = items.map {
                    ItemReorderUpdate(id: $0.id, dayId: $0.dayId, sortOrder: $0.sortOrder)
                }
                return .run { send in
                    do {
                        try await itineraryRepository.reorderItems(updates)
                        await send(.reorderPersistResponse(.success(())))
                    } catch {
                        await send(.reorderPersistResponse(.failure(error)))
                    }
                }

            case let .itemDroppedOnDay(itemID, targetDayID):
                guard
                    let sourceDayID = state.itemsByDay.first(where: { $0.value[id: itemID] != nil })?.key,
                    sourceDayID != targetDayID,
                    var item = state.itemsByDay[sourceDayID]?[id: itemID]
                else { return .none }

                state.itemsByDay[sourceDayID]?.remove(id: itemID)
                if let remainingIDs = state.itemsByDay[sourceDayID]?.ids {
                    for (index, id) in remainingIDs.enumerated() {
                        state.itemsByDay[sourceDayID]?[id: id]?.sortOrder = index
                    }
                }

                item.dayId = targetDayID
                item.sortOrder = state.itemsByDay[targetDayID]?.count ?? 0
                state.itemsByDay[targetDayID, default: []].append(item)

                var updates = [ItemReorderUpdate(id: item.id, dayId: item.dayId, sortOrder: item.sortOrder)]
                if let sourceItems = state.itemsByDay[sourceDayID] {
                    updates.append(
                        contentsOf: sourceItems.map {
                            ItemReorderUpdate(id: $0.id, dayId: $0.dayId, sortOrder: $0.sortOrder)
                        }
                    )
                }

                return .run { [itineraryRepository, updates] send in
                    do {
                        try await itineraryRepository.reorderItems(updates)
                        await send(.reorderPersistResponse(.success(())))
                    } catch {
                        await send(.reorderPersistResponse(.failure(error)))
                    }
                }

            case .reorderPersistResponse:
                return .none

            case .selectAllTapped:
                guard !state.isAnimating else { return .none }
                state.currentStopIndex = nil
                state.pendingChainTargetIndex = nil
                state.jumpTrigger += 1
                return .none

            case let .selectStopTapped(itemID):
                // html의 selectStop(targetIdx) 그대로: 같은 곳이면 무시, 전체보기 상태거나
                // 지금보다 "이전(뒤)" 장소면 애니메이션 없이 즉시 이동, "이후(앞)" 장소면
                // 한 구간씩 애니메이션하며 이동.
                guard !state.isAnimating else { return .none }
                guard let targetIndex = state.selectedItems.index(id: itemID) else { return .none }
                guard targetIndex != state.currentStopIndex else { return .none }

                guard let current = state.currentStopIndex else {
                    state.currentStopIndex = targetIndex
                    state.jumpTrigger += 1
                    return .none
                }

                if targetIndex < current {
                    state.currentStopIndex = targetIndex
                    state.jumpTrigger += 1
                    return .none
                }

                state.isAnimating = true
                state.pendingChainTargetIndex = targetIndex
                state.currentStopIndex = current + 1
                state.animateTrigger += 1
                return .none

            case .prevButtonTapped:
                // html의 goPrev()는 즉시이동이라 애니메이션 중에도 눌리지만, 여기서는 애니메이션
                // 중엔 이전도 명시적으로 막는다(버튼 disabled와 별개로 리듀서에서도 방어).
                guard !state.isAnimating else { return .none }
                guard let current = state.currentStopIndex else { return .none }
                state.isAnimating = false
                state.pendingChainTargetIndex = nil

                if current > 0 {
                    state.currentStopIndex = current - 1
                    state.jumpTrigger += 1
                    return .none
                }

                guard
                    let selectedDayID = state.selectedDayID,
                    let dayIndex = state.days.index(id: selectedDayID),
                    state.days.indices.contains(dayIndex - 1)
                else { return .none }
                let previousDay = state.days[dayIndex - 1]
                state.selectedDayID = previousDay.id
                let lastIndex = max((state.itemsByDay[previousDay.id]?.count ?? 1) - 1, 0)
                state.currentStopIndex = lastIndex
                state.jumpTrigger += 1
                return .none

            case .nextButtonTapped:
                guard !state.isAnimating else { return .none }

                guard let current = state.currentStopIndex else {
                    guard !state.selectedItems.isEmpty else { return .none }
                    state.currentStopIndex = 0
                    state.jumpTrigger += 1
                    return .none
                }

                if current < state.selectedItems.count - 1 {
                    state.isAnimating = true
                    state.pendingChainTargetIndex = current + 1
                    state.currentStopIndex = current + 1
                    state.animateTrigger += 1
                    return .none
                }

                guard
                    let selectedDayID = state.selectedDayID,
                    let dayIndex = state.days.index(id: selectedDayID),
                    state.days.indices.contains(dayIndex + 1)
                else { return .none }
                let nextDay = state.days[dayIndex + 1]
                state.selectedDayID = nextDay.id
                state.currentStopIndex = 0
                state.pendingChainTargetIndex = nil
                state.jumpTrigger += 1
                return .none

            case .legAnimationCompleted:
                if let target = state.pendingChainTargetIndex, let current = state.currentStopIndex, current < target {
                    state.currentStopIndex = current + 1
                    state.animateTrigger += 1
                    return .none
                }
                state.isAnimating = false
                state.pendingChainTargetIndex = nil
                return .none

            case .searchAllRoutesButtonTapped:
                guard !state.isSearchingAllRoutes else { return .none }
                state.isSearchingAllRoutes = true
                state.errorMessage = nil
                let days = Array(state.days)
                let itemsByDay = state.itemsByDay
                return .run { send in
                    let batchSize = 5
                    for batchStart in stride(from: 0, to: days.count, by: batchSize) {
                        let batch = days[batchStart ..< min(batchStart + batchSize, days.count)]
                        await withTaskGroup(of: Void.self) { group in
                            for day in batch {
                                guard let items = itemsByDay[day.id], items.count >= 2 else { continue }
                                group.addTask {
                                    let requestItems = items.map {
                                        RouteLegRequestItem(id: $0.id, lat: $0.lat, lng: $0.lng, mode: $0.arrivalMode, noRoute: $0.noRoute)
                                    }
                                    // "전체 경로 탐색" 버튼은 사용자가 명시적으로 최신 상태를
                                    // 요청한 것이므로 캐시 여부와 상관없이 항상 새로 조회한다
                                    // (조용히 캐시부터 채우는 건 화면 진입시 loadCachedRoutes가
                                    // 이미 하고 있음). 새로 받아온 결과는 dayRoutesResponse
                                    // 성공 처리에서 그대로 캐시에 다시 저장돼 최신화된다.
                                    do {
                                        let legs = try await routeAPIClient.fetchDayRoutes(requestItems)
                                        await send(.dayRoutesResponse(day.id, .success(legs)))
                                    } catch {
                                        await send(.dayRoutesResponse(day.id, .failure(error)))
                                    }
                                }
                            }
                        }
                    }
                    await send(.searchAllRoutesFinished)
                }

            case let .dayRoutesResponse(dayID, .success(legs)):
                // 캐시 저장용 키는 "요청 당시" 아이템 좌표/수단 기준이어야 서버 캐시 키 규칙과
                // 일치한다 — 아래에서 arrivalMode를 갱신하기 전에 먼저 스냅샷을 떠 둔다.
                let requestItemsForCache = (state.itemsByDay[dayID] ?? []).map {
                    RouteLegRequestItem(id: $0.id, lat: $0.lat, lng: $0.lng, mode: $0.arrivalMode, noRoute: $0.noRoute)
                }
                state.legsByDay[dayID] = IdentifiedArrayOf(uniqueElements: legs)

                // 백엔드가 자동으로 찾아낸(또는 사용자가 이미 골라서 그대로 돌아온) 실제
                // 이동수단을 항목에 반영한다 — 그래야 리스트 행의 "도보/기차/…" 배지가
                // 검색 결과를 따라간다. arrivalMode가 비어있던 항목은 이걸로 처음 채워진다.
                var itemsToPersist: [ItineraryItem] = []
                for leg in legs where leg.status == .ok {
                    guard
                        var item = state.itemsByDay[dayID]?[id: leg.toItemId],
                        item.arrivalMode != leg.mode
                    else { continue }
                    item.arrivalMode = leg.mode
                    state.itemsByDay[dayID]?[id: leg.toItemId] = item
                    itemsToPersist.append(item)
                }
                return .run { [itineraryRepository, routeCacheClient, itemsToPersist] _ in
                    await routeCacheClient.save(legs, requestItemsForCache)
                    for item in itemsToPersist {
                        _ = try? await itineraryRepository.updateItem(item)
                    }
                }

            case let .dayRoutesResponse(_, .failure(error)):
                // 하루 실패해도 나머지 날짜는 계속 진행 — 실패한 날짜만 직선으로 남는다.
                state.errorMessage = error.localizedDescription
                return .none

            case .searchAllRoutesFinished:
                state.isSearchingAllRoutes = false
                return .none
            }
        }
    }

    /// 날짜별로 이미 기기에 캐시된 경로가 있으면 네트워크 없이 바로 채운다 — 화면 진입시마다
    /// 매번 다시 "경로 탐색" 버튼을 누르지 않아도, 예전에 한 번 탐색해둔 구간은 오프라인에서도
    /// 그대로 지도에 뜬다.
    private func loadCachedRoutes(
        days: IdentifiedArrayOf<TripDay>,
        itemsByDay: [TripDay.ID: IdentifiedArrayOf<ItineraryItem>]
    ) -> Effect<Action> {
        .run { send in
            await withTaskGroup(of: Void.self) { group in
                for day in days {
                    guard let items = itemsByDay[day.id], items.count >= 2 else { continue }
                    group.addTask {
                        let requestItems = items.map {
                            RouteLegRequestItem(id: $0.id, lat: $0.lat, lng: $0.lng, mode: $0.arrivalMode, noRoute: $0.noRoute)
                        }
                        let cached = await self.routeCacheClient.legsCoveringDay(requestItems)
                        guard !cached.legs.isEmpty else { return }
                        await send(.dayRoutesResponse(day.id, .success(cached.legs)))
                    }
                }
            }
        }
    }

    /// 좌표가 있는데 아직 국가코드가 없는(DB에도 저장 안 된) 항목들만 골라서
    /// `CountryLookupClient`로 조회한다 — 이미 계산돼서 저장된 항목은 다시 지오코딩하지 않는다.
    private func resolveCountryCodes(for items: [ItineraryItem]) -> Effect<Action> {
        let targets = items.filter { $0.hasLocation && $0.countryCode == nil }
        guard !targets.isEmpty else { return .none }
        return .run { send in
            // `CountryLookupClient`가 CLGeocoder 호출 자체를 속도 제한하기 때문에, 항목이
            // 많은(수백 개짜리 샘플 데이터 등) 여행은 전부 끝나기까지 몇 분 걸릴 수 있다 —
            // 그래서 다 모아서 한 번에 보내지 않고 하나씩 끝나는 대로 바로 보낸다. 그래야
            // DB 저장도 그때그때 되고(중간에 앱이 꺼져도 이미 끝난 만큼은 남음), 경고
            // 아이콘/국가 헤더도 계산되는 대로 점진적으로 반영된다.
            await withTaskGroup(of: Void.self) { group in
                for item in targets {
                    guard let lat = item.lat, let lng = item.lng else { continue }
                    group.addTask {
                        guard let code = await self.countryLookupClient.countryCode(lat, lng) else { return }
                        await send(.countryCodesResolved([item.id: code]))
                    }
                }
            }
        }
    }
}
