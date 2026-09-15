import APIClient
import ComposableArchitecture
import Models
import SwiftUI

public struct TripManagementMenuButton: View {
    let trip: Trip
    let onTripListRequested: () -> Void
    let onTripUpdated: (Trip) -> Void

    @State private var editStore: StoreOf<TripEditFeature>?
    @State private var shareStore: StoreOf<TripShareFeature>?
    @Dependency(\.tripsRepository) private var tripsRepository

    public init(
        trip: Trip,
        onTripListRequested: @escaping () -> Void,
        onTripUpdated: @escaping (Trip) -> Void
    ) {
        self.trip = trip
        self.onTripListRequested = onTripListRequested
        self.onTripUpdated = onTripUpdated
    }

    public var body: some View {
        Menu {
            Section("여행 관리") {
                Button {
                    onTripListRequested()
                } label: {
                    Label("여행 목록", systemImage: "list.bullet")
                }

                Button {
                    openEdit()
                } label: {
                    Label("여행 수정", systemImage: "pencil")
                }

                Button {
                    shareStore = Store(initialState: TripShareFeature.State(tripId: trip.id)) {
                        TripShareFeature()
                    }
                } label: {
                    Label("여행 공유", systemImage: "square.and.arrow.up")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .sheet(
            isPresented: Binding(
                get: { editStore != nil },
                set: { isPresented in
                    if !isPresented { editStore = nil }
                }
            )
        ) {
            if let editStore {
                TripEditView(store: editStore)
                    .onChange(of: editStore.savedTrip) { _, savedTrip in
                        if let savedTrip {
                            onTripUpdated(savedTrip)
                            self.editStore = nil
                        }
                    }
            }
        }
        .sheet(
            isPresented: Binding(
                get: { shareStore != nil },
                set: { isPresented in
                    if !isPresented { shareStore = nil }
                }
            )
        ) {
            if let shareStore {
                TripShareView(store: shareStore)
            }
        }
    }

    private func openEdit() {
        Task {
            let countries = (try? await tripsRepository.fetchCountries(trip.id)) ?? []
            editStore = Store(initialState: TripEditFeature.State(editing: trip, countries: countries)) {
                TripEditFeature()
            }
        }
    }
}
