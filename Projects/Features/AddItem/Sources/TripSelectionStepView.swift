import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

struct TripSelectionStepView: View {
    @Bindable var store: StoreOf<AddItemFlowFeature>
    @State private var editStore: StoreOf<TripEditFeature>?

    var body: some View {
        Group {
            if store.isLoadingTrips && store.trips.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Button {
                        editStore = Store(initialState: TripEditFeature.State()) {
                            TripEditFeature()
                        }
                    } label: {
                        Label("여행 추가하기", systemImage: "plus.circle.fill")
                            .font(WaypinFont.bodyEmphasis)
                            .foregroundStyle(WaypinTheme.accent)
                            .waypinCard()
                    }
                    .buttonStyle(.plain)
                    .waypinCardListRow()

                    ForEach(store.trips) { trip in
                        Button {
                            store.send(.tripRowTapped(trip))
                        } label: {
                            TripSummaryRowView(trip: trip)
                                .overlay(alignment: .topTrailing) {
                                    if trip.id == store.defaultTripID {
                                        Text("지금 보는 중")
                                            .font(WaypinFont.captionEmphasis)
                                            .foregroundStyle(WaypinTheme.accentLabel)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(WaypinTheme.accent, in: Capsule())
                                            .padding(WaypinSpacing.sm)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                        .waypinCardListRow()
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .contentMargins(.top, WaypinSpacing.md, for: .scrollContent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(WaypinTheme.background)
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
                            self.editStore = nil
                            store.send(.tripRowTapped(savedTrip))
                        }
                    }
            }
        }
    }
}
