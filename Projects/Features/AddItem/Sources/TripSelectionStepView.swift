import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

/// 일정 추가 마법사 1단계 — 여행 목록. `TripListView`와 겉모습은 같지만(같은
/// `TripSummaryRowView` 셀 + "+ 여행 추가하기" 셀), 고르기/새로 만들기 전용으로 가볍게
/// 새로 짰다(툴바·스와이프 삭제 등 화면 전용 요소는 없음).
struct TripSelectionStepView: View {
    @Bindable var store: StoreOf<AddItemFlowFeature>
    // `@Presents`/`ifLet` 대신 View가 직접 Store를 소유하는 이 프로젝트의 공통 패턴
    // (TripListView와 동일).
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
