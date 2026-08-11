import APIClient
import ComposableArchitecture
import Foundation
import Models
import TripEdit

@Reducer
public struct TripListFeature {
    @ObservableState
    public struct State: Equatable {
        public var trips: IdentifiedArrayOf<Trip> = []
        public var isLoading = false
        public var errorMessage: String?

        public init() {}
    }

    public enum Action {
        case onAppear
        case tripsResponse(Result<[Trip], any Error>)
        case tripSaved(Trip)
        case deleteTrip(IndexSet)
        case deleteTripResponse(Result<Trip.ID, any Error>)
        case loadSampleDataButtonTapped
        case loadSampleDataResponse(Result<Trip, any Error>)
    }

    @Dependency(\.tripsRepository) var tripsRepository
    @Dependency(\.itineraryRepository) var itineraryRepository
    @Dependency(\.authClient) var authClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    do {
                        let trips = try await tripsRepository.fetchTrips()
                        await send(.tripsResponse(.success(trips)))
                    } catch {
                        await send(.tripsResponse(.failure(error)))
                    }
                }

            case let .tripsResponse(.success(trips)):
                state.isLoading = false
                state.trips = IdentifiedArrayOf(uniqueElements: trips)
                return .none

            case let .tripsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case let .tripSaved(trip):
                state.trips.updateOrAppend(trip)
                return .none

            case let .deleteTrip(indexSet):
                let ids = indexSet.map { state.trips[$0].id }
                state.trips.remove(atOffsets: indexSet)
                return .run { send in
                    for id in ids {
                        do {
                            try await tripsRepository.deleteTrip(id)
                            await send(.deleteTripResponse(.success(id)))
                        } catch {
                            await send(.deleteTripResponse(.failure(error)))
                        }
                    }
                }

            case .deleteTripResponse(.success):
                return .none

            case let .deleteTripResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case .loadSampleDataButtonTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        guard let userID = await authClient.currentSession()?.user.id else {
                            throw TripListError.notSignedIn
                        }
                        // 매번 새 UUID로 시딩해서, 이전 시도의 잔여 row가 있어도 기본키
                        // 충돌 없이 항상 새로 만들어진다.
                        let seed = SampleTravelData.makeSeed(ownerId: userID)

                        let savedTrip = try await tripsRepository.createTrip(seed.trip)
                        try await tripsRepository.upsertCountries(seed.countries)
                        _ = try await tripsRepository.createDays(seed.days)

                        // 136개 항목을 한꺼번에 동시 요청하면 서버 쪽 동시 연결 제한에 걸리기
                        // 쉬워서, 적당한 크기로 나눠서 순차 처리한다. 개별 항목 하나가 실패해도
                        // 전체를 막지 않고 넘어간다.
                        let batchSize = 8
                        for batchStart in stride(from: 0, to: seed.items.count, by: batchSize) {
                            let batch = seed.items[batchStart..<min(batchStart + batchSize, seed.items.count)]
                            await withTaskGroup(of: Void.self) { group in
                                for item in batch {
                                    group.addTask { _ = try? await itineraryRepository.createItem(item) }
                                }
                                await group.waitForAll()
                            }
                        }

                        await send(.loadSampleDataResponse(.success(savedTrip)))
                    } catch {
                        await send(.loadSampleDataResponse(.failure(error)))
                    }
                }

            case let .loadSampleDataResponse(.success(trip)):
                state.isLoading = false
                state.trips.updateOrAppend(trip)
                return .none

            case let .loadSampleDataResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}

private enum TripListError: Error {
    case notSignedIn
}
