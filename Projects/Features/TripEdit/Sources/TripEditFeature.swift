import APIClient
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct TripEditFeature {
    @ObservableState
    public struct State: Equatable {
        public var tripID: Trip.ID?
        public var name: String
        public var startDate: Date
        public var endDate: Date
        public var countries: IdentifiedArrayOf<TripCountry>
        public var isSaving = false
        public var errorMessage: String?
        public var savedTrip: Trip?

        public var isEditing: Bool { tripID != nil }

        public init(editing trip: Trip? = nil, countries: [TripCountry] = []) {
            self.tripID = trip?.id
            self.name = trip?.name ?? ""
            self.startDate = trip?.startDate ?? .now
            self.endDate = trip?.endDate ?? .now.addingTimeInterval(4 * 86400)
            self.countries = IdentifiedArrayOf(uniqueElements: countries.sorted { $0.sortOrder < $1.sortOrder })
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case cancelButtonTapped
        case saveResponse(Result<Trip, any Error>)
        case delegate(Delegate)

        public enum Delegate {
            case saved(Trip)
            case cancelled
        }
    }

    @Dependency(\.tripsRepository) var tripsRepository
    @Dependency(\.authClient) var authClient
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .saveButtonTapped:
                guard !state.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    state.errorMessage = "여행 이름을 입력해주세요."
                    return .none
                }
                guard state.endDate >= state.startDate else {
                    state.errorMessage = "종료일은 시작일 이후여야 해요."
                    return .none
                }
                state.errorMessage = nil
                state.isSaving = true

                let isCreating = state.tripID == nil
                let tripID = state.tripID ?? uuid()
                let name = state.name
                let startDate = DateOnly.normalizeToUTCMidnight(state.startDate)
                let endDate = DateOnly.normalizeToUTCMidnight(state.endDate)
                let countries = Array(state.countries)
                let calendar: Calendar = {
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.timeZone = TimeZone(identifier: "UTC")!
                    return calendar
                }()

                WaypinLog.debug("트립 저장 시작 isCreating=\(isCreating) name=\(name)", category: .tripEdit)
                return .run { send in
                    do {
                        guard let userID = await authClient.currentSession()?.user.id else {
                            throw TripEditError.notSignedIn
                        }

                        let trip = Trip(
                            id: tripID,
                            ownerId: userID,
                            name: name,
                            startDate: startDate,
                            endDate: endDate
                        )
                        let savedTrip = isCreating
                            ? try await tripsRepository.createTrip(trip)
                            : try await tripsRepository.updateTrip(trip)

                        if !countries.isEmpty {
                            try await tripsRepository.upsertCountries(countries)
                        }

                        if isCreating {
                            let days = Self.generateDays(
                                tripID: tripID,
                                startDate: startDate,
                                endDate: endDate,
                                calendar: calendar
                            )
                            _ = try await tripsRepository.createDays(days)
                            WaypinLog.debug("트립 생성 완료 days=\(days.count)", category: .tripEdit)
                        }

                        await send(.saveResponse(.success(savedTrip)))
                    } catch {
                        WaypinLog.error("트립 저장 실패: \(error)", category: .tripEdit)
                        await send(.saveResponse(.failure(error)))
                    }
                }

            case let .saveResponse(.success(trip)):
                state.isSaving = false
                state.savedTrip = trip
                return .send(.delegate(.saved(trip)))

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

    private static func generateDays(
        tripID: Trip.ID,
        startDate: Date,
        endDate: Date,
        calendar: Calendar
    ) -> [TripDay] {
        var days: [TripDay] = []
        var current = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        var index = 1
        while current <= end {
            days.append(
                TripDay(
                    tripId: tripID,
                    countryCode: "",
                    dayDate: current,
                    dayIndex: index
                )
            )
            index += 1
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }
}

private enum TripEditError: Error {
    case notSignedIn
}
