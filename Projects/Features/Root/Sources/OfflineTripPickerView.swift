import APIClient
import ComposableArchitecture
import DesignSystem
import Foundation
import Models
import SwiftUI

struct OfflineTripPickerView: View {
    @Dependency(\.offlineCacheClient) private var offlineCacheClient
    @State private var savedTrips: [Trip] = []
    @State private var isLoading = true
    let onTripSelected: (Trip) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if savedTrips.isEmpty {
                    ContentUnavailableView {
                        Label("오프라인 상태예요", systemImage: "wifi.slash")
                    } description: {
                        Text("저장해둔 오프라인 여행이 없어요. 인터넷에 연결한 뒤 여행에서 \"오프라인 저장\"을 먼저 해두세요.")
                    }
                } else {
                    List {
                        Section {
                            Label("오프라인 상태예요 — 저장해둔 여행만 볼 수 있어요", systemImage: "wifi.slash")
                                .font(FlowneyFont.caption)
                                .foregroundStyle(FlowneyTheme.textSecondary)
                        }
                        ForEach(savedTrips) { trip in
                            Button {
                                onTripSelected(trip)
                            } label: {
                                TripSummaryRowView(trip: trip)
                            }
                            .buttonStyle(.plain)
                            .flowneyCardListRow()
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(FlowneyTheme.background)
            .navigationTitle("오프라인 여행 선택")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task { await loadSavedTrips() }
    }

    private func loadSavedTrips() async {
        defer { isLoading = false }
        guard
            let data = await offlineCacheClient.load(OfflineCacheKey.savedTrips),
            let trips = try? JSONDecoder().decode([Trip].self, from: data)
        else {
            savedTrips = []
            return
        }
        savedTrips = trips
    }
}
