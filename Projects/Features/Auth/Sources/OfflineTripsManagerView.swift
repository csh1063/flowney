import APIClient
import ComposableArchitecture
import DesignSystem
import Foundation
import Models
import SwiftUI

struct OfflineTripsManagerView: View {
    @Dependency(\.offlineCacheClient) private var offlineCacheClient
    @State private var savedTrips: [Trip] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if savedTrips.isEmpty {
                ContentUnavailableView {
                    Label("저장된 오프라인 여행이 없어요", systemImage: "wifi.slash")
                } description: {
                    Text("여행 화면 상단 \"...\" 메뉴에서 \"오프라인 저장\"을 눌러 저장해두세요.")
                }
            } else {
                List {
                    ForEach(savedTrips) { trip in
                        TripSummaryRowView(trip: trip)
                            .flowneyCardListRow()
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(FlowneyTheme.background)
        .flowneyLeadingTitle("오프라인 여행 관리")
        .task { await loadSavedTrips() }
    }

    private func loadSavedTrips() async {
        defer { isLoading = false }
        guard let trips = await offlineCacheClient.loadCodable([Trip].self, key: OfflineCacheKey.savedTrips) else {
            savedTrips = []
            return
        }
        savedTrips = trips
    }

    private func delete(at offsets: IndexSet) {
        let tripsToDelete = offsets.map { savedTrips[$0] }
        savedTrips.remove(atOffsets: offsets)
        Task {
            for trip in tripsToDelete {
                await OfflineTripSaver().removeSavedTrip(trip.id)
            }
        }
    }
}
