import APIClient
import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct TripManagementMenuButton: View {
    let trip: Trip
    let onTripListRequested: () -> Void
    let onTripUpdated: (Trip) -> Void

    @State private var editStore: StoreOf<TripEditFeature>?
    @State private var shareStore: StoreOf<TripShareFeature>?
    @State private var isSavingOffline = false
    @State private var offlineSaveMessage: String?
    @Dependency(\.tripsRepository) private var tripsRepository
    @Environment(\.isOfflineViewing) private var isOfflineViewing

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

                if !isOfflineViewing {
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

                    Button {
                        saveOffline()
                    } label: {
                        Label(isSavingOffline ? "저장 중…" : "오프라인 저장", systemImage: "arrow.down.circle")
                    }
                    .disabled(isSavingOffline)
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .alert(
            offlineSaveMessage ?? "",
            isPresented: Binding(
                get: { offlineSaveMessage != nil },
                set: { if !$0 { offlineSaveMessage = nil } }
            )
        ) {
            Button("확인", role: .cancel) {}
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

    private func saveOffline() {
        isSavingOffline = true
        Task {
            do {
                try await OfflineTripSaver().save(trip: trip)
                offlineSaveMessage = "오프라인 저장 완료"
            } catch {
                offlineSaveMessage = "오프라인 저장 실패: \(error.localizedDescription)"
            }
            isSavingOffline = false
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
