import APIClient
import ComposableArchitecture
import DesignSystem
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
        public var selectedCountryCodes: [String]
        public var isSaving = false
        public var errorMessage: String?
        // `@Presents`/`ifLet` 프레젠테이션 대신 부모 View가 이 필드를 직접 관찰해서
        // 저장 완료를 감지한다 (자세한 이유는 TripListView.swift 참고).
        public var savedTrip: Trip?

        public var isEditing: Bool { tripID != nil }

        public init(editing trip: Trip? = nil, countries: [TripCountry] = []) {
            self.tripID = trip?.id
            self.name = trip?.name ?? ""
            self.startDate = trip?.startDate ?? .now
            self.endDate = trip?.endDate ?? .now.addingTimeInterval(4 * 86400)
            self.selectedCountryCodes = countries.sorted { $0.sortOrder < $1.sortOrder }.map(\.countryCode)
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case countryToggled(String)
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

            case let .countryToggled(code):
                if let idx = state.selectedCountryCodes.firstIndex(of: code) {
                    state.selectedCountryCodes.remove(at: idx)
                } else {
                    state.selectedCountryCodes.append(code)
                }
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
                guard !state.selectedCountryCodes.isEmpty else {
                    state.errorMessage = "국가를 1개 이상 선택해주세요."
                    return .none
                }
                state.errorMessage = nil
                state.isSaving = true

                let isCreating = state.tripID == nil
                let tripID = state.tripID ?? uuid()
                let name = state.name
                let startDate = state.startDate
                let endDate = state.endDate
                let countryCodes = state.selectedCountryCodes
                let calendar = Calendar.current

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

                        let countries = countryCodes.enumerated().map { index, code in
                            TripCountry(
                                tripId: tripID,
                                countryCode: code,
                                color: CountryCatalog.option(for: code)?.defaultColorHex ?? "#2c3e50",
                                sortOrder: index
                            )
                        }
                        try await tripsRepository.upsertCountries(countries)

                        if isCreating {
                            let days = Self.generateDays(
                                tripID: tripID,
                                startDate: startDate,
                                endDate: endDate,
                                defaultCountryCode: countryCodes[0],
                                calendar: calendar
                            )
                            _ = try await tripsRepository.createDays(days)
                        }

                        await send(.saveResponse(.success(savedTrip)))
                    } catch {
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
        defaultCountryCode: String,
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
                    countryCode: defaultCountryCode,
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
