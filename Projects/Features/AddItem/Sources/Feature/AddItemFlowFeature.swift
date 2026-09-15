import APIClient
import ComposableArchitecture
import Foundation
import Models

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
        public var defaultTripID: Trip.ID?
        public var mode: AddItemFeature.Mode
        public var linkURLText: String
        public var prefillName: String
        public var prefillResolvedPlace: ResolvedPlace? = nil

        public var trips: IdentifiedArrayOf<Trip> = []
        public var isLoadingTrips = false
        public var days: IdentifiedArrayOf<TripDay> = []
        public var isLoadingDays = false
        public var errorMessage: String?

        public var addItemRequest: AddItemFeature.State?

        public var isEditing: Bool = false

        public init(
            trip: Trip? = nil,
            day: TripDay? = nil,
            startingSortOrder: Int? = nil,
            defaultTripID: Trip.ID? = nil,
            mode: AddItemFeature.Mode = .manual,
            linkURLText: String = "",
            prefillName: String = "",
            prefillResolvedPlace: ResolvedPlace? = nil
        ) {
            selectedTrip = trip
            selectedDay = day
            self.defaultTripID = defaultTripID ?? trip?.id
            self.mode = mode
            self.linkURLText = linkURLText
            self.prefillName = prefillName
            self.prefillResolvedPlace = prefillResolvedPlace
            if let trip, let day, let startingSortOrder {
                step = .form
                var addItemState = AddItemFeature.State(tripID: trip.id, dayID: day.id, startingSortOrder: startingSortOrder)
                addItemState.mode = mode
                addItemState.linkURLText = linkURLText
                addItemState.name = prefillName
                addItemState.applyResolvedPlace(prefillResolvedPlace)
                addItemRequest = addItemState
            } else {
                step = .tripList
                isLoadingTrips = true
            }
        }

        public init(editingItem item: ItineraryItem, trip: Trip, day: TripDay, linkedEntry: BudgetEntry? = nil) {
            selectedTrip = trip
            selectedDay = day
            defaultTripID = trip.id
            mode = .manual
            linkURLText = ""
            prefillName = ""
            isEditing = true
            step = .form
            addItemRequest = AddItemFeature.State(editing: item, tripID: trip.id, dayID: day.id, linkedEntry: linkedEntry)
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
                guard day.id == state.selectedDay?.id, let trip = state.selectedTrip else { return .none }
                var addItemState = AddItemFeature.State(tripID: trip.id, dayID: day.id, startingSortOrder: count)
                addItemState.mode = state.mode
                addItemState.linkURLText = state.linkURLText
                addItemState.name = state.prefillName
                addItemState.applyResolvedPlace(state.prefillResolvedPlace)
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
