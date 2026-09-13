import AddItem
import APIClient
import ComposableArchitecture
import DesignSystem
import Foundation
import Models

@Reducer
public struct ItineraryFeature {
    @ObservableState
    public struct State: Equatable {
        public var trip: Trip?
        public var countries: IdentifiedArrayOf<TripCountry> = []
        public var days: IdentifiedArrayOf<TripDay> = []
        public var selectedDayID: TripDay.ID?
        public var editingDayLabelForID: TripDay.ID?
        public var listSelectedItemID: ItineraryItem.ID?
        public var itemsByDay: [TripDay.ID: IdentifiedArrayOf<ItineraryItem>] = [:]
        public var entries: IdentifiedArrayOf<BudgetEntry> = []
        public var legsByDay: [TripDay.ID: IdentifiedArrayOf<RouteLeg>] = [:]
        public var weatherByDay: [TripDay.ID: DayWeather] = [:]
        public var isLoading = false
        public var errorMessage: String?
        public var addItemFlowRequest: AddItemFlowFeature.State?

        public var currentStopIndex: Int?
        public var pendingChainTargetIndex: Int?
        public var animateTrigger: Int = 0
        public var jumpTrigger: Int = 0
        public var isAnimating: Bool = false
        public var isSearchingAllRoutes: Bool = false
        public var isRefreshingTodayRoute: Bool = false
        public var isRefreshingWeather: Bool = false

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

        public var isPrevDisabled: Bool {
            isAnimating || currentStopIndex == nil || ((currentStopIndex ?? 0) <= 0 && isFirstDay)
        }

        public var isNextDisabled: Bool {
            isAnimating || (currentStopIndex != nil && (currentStopIndex ?? 0) >= selectedItems.count - 1 && isLastDay)
        }

        public var registeredCountryCodes: Set<String> {
            Set(countries.map(\.countryCode))
        }

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
        case tripSelected(Trip)
        case onAppear
        case daysResponse(Result<[TripDay], any Error>)
        case itemsResponse(Result<[ItineraryItem], any Error>)
        case entriesResponse(Result<[BudgetEntry], any Error>)
        case countriesResponse(Result<[TripCountry], any Error>)
        case weatherResponse(TripDay.ID, Result<DayWeather, any Error>)
        case dayTabTapped(TripDay.ID)
        case listItemTapped(ItineraryItem.ID)
        case listSelectionCleared
        case editDayLabelButtonTapped(TripDay.ID)
        case dayLabelEditCancelled
        case dayLabelChanged(TripDay.ID, String?)
        case dayLabelUpdateResponse(Result<TripDay, any Error>)
        case addItemButtonTapped
        case editItemTapped(ItineraryItem)
        case addItemRequestConsumed
        case itemAdded(ItineraryItem)
        case deleteItems(IndexSet)
        case deleteItemByID(ItineraryItem.ID)
        case deleteItemResponse(Result<ItineraryItem.ID, any Error>)
        case itemsMovedWithinDay(IndexSet, Int)
        case itemDroppedOnDay(ItineraryItem.ID, TripDay.ID)
        case itemsReorderedAcrossDays([TripDay.ID: [ItineraryItem]])
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
        case allRoutesRefreshFailed(any Error)

        case todayRouteRefreshButtonTapped
        case todayRouteRefreshFinished

        case refreshAllWeatherButtonTapped
        case weatherRefreshFinished
    }

    @Dependency(\.tripsRepository) var tripsRepository
    @Dependency(\.itineraryRepository) var itineraryRepository
    @Dependency(\.budgetEntryRepository) var budgetEntryRepository
    @Dependency(\.routeAPIClient) var routeAPIClient
    @Dependency(\.routeCacheClient) var routeCacheClient
    @Dependency(\.weatherAPIClient) var weatherAPIClient
    @Dependency(\.countryLookupClient) var countryLookupClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .tripSelected(trip):
                state = State(trip: trip)
                return .send(.onAppear)

            case .onAppear:
                guard let tripID = state.trip?.id else { return .none }
                FlowneyLog.debug("onAppear trip=\(tripID)", category: .itinerary)
                state.isLoading = true
                let cachedWeatherDayIDs = Set(state.weatherByDay.keys)
                return .run { send in
                    var days: [TripDay] = []
                    do {
                        days = try await tripsRepository.fetchDays(tripID)
                        FlowneyLog.debug("fetchDays succeeded count=\(days.count)", category: .itinerary)
                        await send(.daysResponse(.success(days)))
                    } catch {
                        FlowneyLog.error("fetchDays failed: \(error)", category: .itinerary)
                        await send(.daysResponse(.failure(error)))
                    }

                    var items: [ItineraryItem] = []
                    do {
                        items = try await itineraryRepository.fetchAllItems(tripID)
                        FlowneyLog.debug("fetchAllItems succeeded count=\(items.count)", category: .itinerary)
                        await send(.itemsResponse(.success(items)))
                    } catch {
                        FlowneyLog.error("fetchAllItems failed: \(error)", category: .itinerary)
                        await send(.itemsResponse(.failure(error)))
                    }

                    do {
                        let countries = try await tripsRepository.fetchCountries(tripID)
                        await send(.countriesResponse(.success(countries)))
                    } catch {
                        FlowneyLog.error("fetchCountries failed: \(error)", category: .itinerary)
                        await send(.countriesResponse(.failure(error)))
                    }

                    do {
                        let entries = try await budgetEntryRepository.fetchAllEntries(tripID)
                        await send(.entriesResponse(.success(entries)))
                    } catch {
                        FlowneyLog.error("fetchAllEntries failed: \(error)", category: .itinerary)
                        await send(.entriesResponse(.failure(error)))
                    }

                    await fetchWeather(days: days, items: items, skippingCachedIn: cachedWeatherDayIDs, send: send)
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
                return .none

            case let .entriesResponse(.success(entries)):
                state.entries = IdentifiedArrayOf(uniqueElements: entries)
                return .none

            case .entriesResponse(.failure):
                return .none

            case let .weatherResponse(dayID, .success(weather)):
                state.weatherByDay[dayID] = weather
                return .none

            case .weatherResponse(_, .failure):
                return .none

            case let .dayTabTapped(dayID):
                state.selectedDayID = dayID
                state.currentStopIndex = nil
                state.pendingChainTargetIndex = nil
                state.isAnimating = false
                state.jumpTrigger += 1
                return .none

            case let .listItemTapped(itemID):
                state.listSelectedItemID = state.listSelectedItemID == itemID ? nil : itemID
                return .none

            case .listSelectionCleared:
                state.listSelectedItemID = nil
                return .none

            case let .editDayLabelButtonTapped(dayID):
                state.editingDayLabelForID = dayID
                return .none

            case .dayLabelEditCancelled:
                state.editingDayLabelForID = nil
                return .none

            case let .dayLabelChanged(dayID, newLabel):
                state.editingDayLabelForID = nil
                guard var day = state.days[id: dayID] else { return .none }
                day.label = newLabel
                state.days[id: dayID] = day

                return .run { [tripsRepository, day] send in
                    do {
                        let saved = try await tripsRepository.updateDay(day)
                        await send(.dayLabelUpdateResponse(.success(saved)))
                    } catch {
                        await send(.dayLabelUpdateResponse(.failure(error)))
                    }
                }

            case let .dayLabelUpdateResponse(.success(day)):
                state.days[id: day.id] = day
                return .none

            case let .dayLabelUpdateResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .addItemButtonTapped:
                guard let trip = state.trip else { return .none }
                if let dayID = state.selectedDayID, let day = state.days[id: dayID] {
                    let count = state.itemsByDay[dayID]?.count ?? 0
                    state.addItemFlowRequest = AddItemFlowFeature.State(trip: trip, day: day, startingSortOrder: count, defaultTripID: trip.id)
                } else {
                    state.addItemFlowRequest = AddItemFlowFeature.State(defaultTripID: trip.id)
                }
                return .none

            case let .editItemTapped(item):
                guard let trip = state.trip, let day = state.days[id: item.dayId] else { return .none }
                state.listSelectedItemID = nil
                state.addItemFlowRequest = AddItemFlowFeature.State(editingItem: item, trip: trip, day: day, linkedEntry: state.entries[id: item.id])
                return .none

            case .addItemRequestConsumed:
                state.addItemFlowRequest = nil
                return .none

            case let .itemAdded(item):
                state.itemsByDay[item.dayId, default: []][id: item.id] = item
                return .merge(
                    resolveCountryCodes(for: [item]),
                    .run { [budgetEntryRepository, tripID = item.tripId] send in
                        guard let entries = try? await budgetEntryRepository.fetchAllEntries(tripID) else { return }
                        await send(.entriesResponse(.success(entries)))
                    }
                )

            case let .countryCodesResolved(resolved):
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

                var newCountries: [TripCountry] = []
                if let tripID = state.trip?.id {
                    for item in itemsToPersist {
                        guard let code = item.countryCode, !state.countries.contains(where: { $0.countryCode == code }) else { continue }
                        let country = TripCountry(
                            tripId: tripID,
                            countryCode: code,
                            color: CountryCatalog.option(for: code)?.defaultColorHex ?? FlowneyTheme.brandNavyHex,
                            sortOrder: state.countries.count
                        )
                        state.countries.append(country)
                        newCountries.append(country)
                    }
                }

                guard !itemsToPersist.isEmpty || !newCountries.isEmpty else { return .none }
                return .run { [itineraryRepository, tripsRepository, itemsToPersist, newCountries] _ in
                    for item in itemsToPersist {
                        _ = try? await itineraryRepository.updateItem(item)
                    }
                    if !newCountries.isEmpty {
                        try? await tripsRepository.upsertCountries(newCountries)
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
                state.entries.remove(id: itemID)
                return .run { send in
                    do {
                        try await itineraryRepository.deleteItem(itemID)
                        FlowneyLog.debug("deleteItem OK id=\(itemID)", category: .itinerary)
                        await send(.deleteItemResponse(.success(itemID)))
                    } catch {
                        FlowneyLog.error("deleteItem failed id=\(itemID): \(error)", category: .itinerary)
                        await send(.deleteItemResponse(.failure(error)))
                    }
                }

            case let .deleteItemByID(itemID):
                guard let dayID = state.itemsByDay.first(where: { $0.value[id: itemID] != nil })?.key else { return .none }
                state.itemsByDay[dayID]?.remove(id: itemID)
                state.entries.remove(id: itemID)
                if state.listSelectedItemID == itemID {
                    state.listSelectedItemID = nil
                }
                return .run { send in
                    do {
                        try await itineraryRepository.deleteItem(itemID)
                        FlowneyLog.debug("deleteItem OK id=\(itemID)", category: .itinerary)
                        await send(.deleteItemResponse(.success(itemID)))
                    } catch {
                        FlowneyLog.error("deleteItem failed id=\(itemID): \(error)", category: .itinerary)
                        await send(.deleteItemResponse(.failure(error)))
                    }
                }

            case let .deleteItems(indexSet):
                guard let dayID = state.selectedDayID else { return .none }
                var items = state.itemsByDay[dayID] ?? []
                let ids = indexSet.map { items[$0].id }
                items.remove(atOffsets: indexSet)
                state.itemsByDay[dayID] = items
                for id in ids { state.entries.remove(id: id) }
                return .run { send in
                    for id in ids {
                        do {
                            try await itineraryRepository.deleteItem(id)
                            FlowneyLog.debug("deleteItem OK id=\(id)", category: .itinerary)
                            await send(.deleteItemResponse(.success(id)))
                        } catch {
                            FlowneyLog.error("deleteItem failed id=\(id): \(error)", category: .itinerary)
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
                    items[id: id]?.arrivalMode = nil
                }
                state.itemsByDay[dayID] = items
                state.legsByDay[dayID] = []

                let updates = items.map {
                    ItemReorderUpdate(id: $0.id, dayId: $0.dayId, sortOrder: $0.sortOrder)
                }
                return .run { [itineraryRepository, items] send in
                    do {
                        try await itineraryRepository.reorderItems(updates)
                        for item in items {
                            _ = try? await itineraryRepository.updateItem(item)
                        }
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
                        state.itemsByDay[sourceDayID]?[id: id]?.arrivalMode = nil
                    }
                }
                state.legsByDay[sourceDayID] = []

                item.dayId = targetDayID
                item.sortOrder = state.itemsByDay[targetDayID]?.count ?? 0
                item.arrivalMode = nil
                state.itemsByDay[targetDayID, default: []].append(item)
                state.legsByDay[targetDayID] = []

                var updates = [ItemReorderUpdate(id: item.id, dayId: item.dayId, sortOrder: item.sortOrder)]
                var itemsToPersist = [item]
                if let sourceItems = state.itemsByDay[sourceDayID] {
                    updates.append(
                        contentsOf: sourceItems.map {
                            ItemReorderUpdate(id: $0.id, dayId: $0.dayId, sortOrder: $0.sortOrder)
                        }
                    )
                    itemsToPersist.append(contentsOf: sourceItems)
                }

                return .run { [itineraryRepository, updates, itemsToPersist] send in
                    do {
                        try await itineraryRepository.reorderItems(updates)
                        for item in itemsToPersist {
                            _ = try? await itineraryRepository.updateItem(item)
                        }
                        await send(.reorderPersistResponse(.success(())))
                    } catch {
                        await send(.reorderPersistResponse(.failure(error)))
                    }
                }

            case let .itemsReorderedAcrossDays(newItemsByDay):
                var updates: [ItemReorderUpdate] = []
                var itemsToPersist: [ItineraryItem] = []

                for (dayID, items) in newItemsByDay {
                    var reindexed = items
                    var dayChanged = false
                    for index in reindexed.indices {
                        if reindexed[index].dayId != dayID {
                            dayChanged = true
                        }
                        reindexed[index].dayId = dayID
                        reindexed[index].sortOrder = index
                    }
                    if dayChanged {
                        for index in reindexed.indices {
                            reindexed[index].arrivalMode = nil
                        }
                    }
                    state.itemsByDay[dayID] = IdentifiedArrayOf(uniqueElements: reindexed)
                    state.legsByDay[dayID] = []
                    updates.append(
                        contentsOf: reindexed.map { ItemReorderUpdate(id: $0.id, dayId: $0.dayId, sortOrder: $0.sortOrder) }
                    )
                    itemsToPersist.append(contentsOf: reindexed)
                }

                return .run { [itineraryRepository, updates, itemsToPersist] send in
                    do {
                        try await itineraryRepository.reorderItems(updates)
                        for item in itemsToPersist {
                            _ = try? await itineraryRepository.updateItem(item)
                        }
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
                guard !state.isSearchingAllRoutes, !state.isRefreshingTodayRoute, let tripID = state.trip?.id else { return .none }
                FlowneyLog.debug("전체 경로 탐색 시작 trip=\(tripID)", category: .route)
                state.isSearchingAllRoutes = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let results = try await routeAPIClient.refreshTripRoutes(tripID, nil, .all)
                        FlowneyLog.debug("전체 경로 탐색 응답 days=\(results.count)", category: .route)
                        for result in results {
                            await send(.dayRoutesResponse(result.dayId, .success(result.legs)))
                        }
                    } catch {
                        FlowneyLog.error("전체 경로 탐색 실패: \(error)", category: .route)
                        await send(.allRoutesRefreshFailed(error))
                    }
                    await send(.searchAllRoutesFinished)
                }

            case .todayRouteRefreshButtonTapped:
                guard !state.isRefreshingTodayRoute, !state.isSearchingAllRoutes, let tripID = state.trip?.id else { return .none }
                guard let selectedDayID = state.selectedDayID else {
                    FlowneyLog.debug("선택 날짜 경로 갱신 스킵: 선택된 날짜 없음", category: .route)
                    state.errorMessage = "먼저 날짜를 선택해주세요."
                    return .none
                }
                FlowneyLog.debug("선택 날짜 경로 갱신 시작 trip=\(tripID) day=\(selectedDayID)", category: .route)
                state.isRefreshingTodayRoute = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let results = try await routeAPIClient.refreshTripRoutes(tripID, selectedDayID, .today)
                        FlowneyLog.debug("선택 날짜 경로 갱신 응답 days=\(results.count)", category: .route)
                        for result in results {
                            await send(.dayRoutesResponse(result.dayId, .success(result.legs)))
                        }
                    } catch {
                        FlowneyLog.error("선택 날짜 경로 갱신 실패: \(error)", category: .route)
                        await send(.dayRoutesResponse(selectedDayID, .failure(error)))
                    }
                    await send(.todayRouteRefreshFinished)
                }

            case .todayRouteRefreshFinished:
                state.isRefreshingTodayRoute = false
                return .none

            case .refreshAllWeatherButtonTapped:
                guard !state.isRefreshingWeather, state.trip != nil else { return .none }
                FlowneyLog.debug("전체 날씨 갱신 시작 days=\(state.days.count)", category: .weather)
                state.isRefreshingWeather = true
                let days = Array(state.days)
                let items = Array(state.itemsByDay.values.flatMap { $0 })
                return .run { send in
                    await fetchWeather(days: days, items: items, send: send)
                    FlowneyLog.debug("전체 날씨 갱신 완료", category: .weather)
                    await send(.weatherRefreshFinished)
                }

            case .weatherRefreshFinished:
                state.isRefreshingWeather = false
                return .none

            case let .dayRoutesResponse(dayID, .success(legs)):
                let requestItemsForCache = (state.itemsByDay[dayID] ?? []).map {
                    RouteLegRequestItem(id: $0.id, lat: $0.lat, lng: $0.lng, mode: $0.arrivalMode, noRoute: $0.noRoute)
                }
                state.legsByDay[dayID] = IdentifiedArrayOf(uniqueElements: legs)

                FlowneyLog.debug("dayRoutesResponse day=\(dayID) legs=\(legs.count)", category: .route)
                for leg in legs {
                    FlowneyLog.debug("  leg to=\(leg.toItemId) status=\(leg.status) mode=\(leg.mode)", category: .route)
                }

                var itemsToPersist: [ItineraryItem] = []
                for leg in legs where leg.status == .ok {
                    guard var item = state.itemsByDay[dayID]?[id: leg.toItemId] else {
                        FlowneyLog.warning("  no matching item for leg.toItemId=\(leg.toItemId)", category: .route)
                        continue
                    }
                    guard item.arrivalMode != leg.mode else {
                        FlowneyLog.debug("  item \(item.id) arrivalMode already \(String(describing: item.arrivalMode)), skipping", category: .route)
                        continue
                    }
                    item.arrivalMode = leg.mode
                    state.itemsByDay[dayID]?[id: leg.toItemId] = item
                    itemsToPersist.append(item)
                }
                FlowneyLog.debug("dayRoutesResponse itemsToPersist=\(itemsToPersist.count)", category: .route)
                return .run { [itineraryRepository, routeCacheClient, itemsToPersist] _ in
                    await routeCacheClient.save(legs, requestItemsForCache)
                    for item in itemsToPersist {
                        do {
                            _ = try await itineraryRepository.updateItem(item)
                            FlowneyLog.debug("updateItem OK for \(item.id) arrivalMode=\(String(describing: item.arrivalMode))", category: .route)
                        } catch {
                            FlowneyLog.error("updateItem FAILED for \(item.id): \(error)", category: .route)
                        }
                    }
                }

            case let .dayRoutesResponse(_, .failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .searchAllRoutesFinished:
                state.isSearchingAllRoutes = false
                return .none

            case let .allRoutesRefreshFailed(error):
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }

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

    private func resolveCountryCodes(for items: [ItineraryItem]) -> Effect<Action> {
        let targets = items.filter { $0.hasLocation && $0.countryCode == nil }
        guard !targets.isEmpty else { return .none }
        return .run { send in
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

    private func fetchWeather(
        days allDays: [TripDay],
        items: [ItineraryItem],
        skippingCachedIn cachedDayIDs: Set<TripDay.ID> = [],
        send: Send<Action>
    ) async {
        guard !allDays.isEmpty, !items.isEmpty else { return }

        struct DayLocation {
            let day: TripDay
            let lat: Double
            let lng: Double
        }

        // 그 날 항목이 아직 없어서 위치를 모르는 날은, 가장 가까운 이전/다음 날의 위치를
        // 빌려서라도 날씨를 보여준다 — 완전히 못 보여주는 것보단 근사치가 낫다.
        var locationByDayID: [TripDay.ID: (lat: Double, lng: Double)] = [:]
        for day in allDays {
            if let firstItem = items
                .filter({ $0.dayId == day.id })
                .sorted(by: { $0.sortOrder < $1.sortOrder })
                .first(where: { $0.lat != nil && $0.lng != nil }),
                let lat = firstItem.lat, let lng = firstItem.lng {
                locationByDayID[day.id] = (lat, lng)
            }
        }
        var lastKnown: (lat: Double, lng: Double)?
        for day in allDays {
            if let known = locationByDayID[day.id] {
                lastKnown = known
            } else if let lastKnown {
                locationByDayID[day.id] = lastKnown
            }
        }
        var nextKnown: (lat: Double, lng: Double)?
        for day in allDays.reversed() {
            if let known = locationByDayID[day.id] {
                nextKnown = known
            } else if let nextKnown {
                locationByDayID[day.id] = nextKnown
            }
        }

        let days = allDays.filter { !cachedDayIDs.contains($0.id) }
        guard !days.isEmpty else { return }

        let dayLocations: [DayLocation] = days.compactMap { day in
            guard let location = locationByDayID[day.id] else { return nil }
            return DayLocation(day: day, lat: location.lat, lng: location.lng)
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
                        let weatherByDate = try await self.weatherAPIClient.fetchWeatherRange(
                            representative.lat,
                            representative.lng,
                            block.map(\.day.dayDate)
                        )
                        FlowneyLog.debug("날씨 조회 성공 days=\(block.count) lat=\(representative.lat) lng=\(representative.lng)", category: .weather)
                        for location in block {
                            let key = keyFormatter.string(from: location.day.dayDate)
                            if let weather = weatherByDate[key] {
                                await send(.weatherResponse(location.day.id, .success(weather)))
                            } else {
                                FlowneyLog.warning("날씨 데이터 없음 day=\(location.day.id)", category: .weather)
                                await send(.weatherResponse(location.day.id, .failure(WeatherAPIError.noData)))
                            }
                        }
                    } catch {
                        FlowneyLog.error("날씨 조회 실패: \(error)", category: .weather)
                        for location in block {
                            await send(.weatherResponse(location.day.id, .failure(error)))
                        }
                    }
                }
            }
        }
    }
}
