import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

public struct TripListView: View {
    @Bindable var store: StoreOf<TripListFeature>
    @Environment(\.dismiss) private var dismiss
    @State private var editStore: StoreOf<TripEditFeature>?
    let onTripSelected: (Trip) -> Void

    public init(store: StoreOf<TripListFeature>, onTripSelected: @escaping (Trip) -> Void) {
        self.store = store
        self.onTripSelected = onTripSelected
    }

    public var body: some View {
        Group {
            if store.trips.isEmpty && store.isLoading {
                ProgressView("불러오는 중…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.trips.isEmpty {
                ContentUnavailableView {
                    Label("등록된 여행이 없어요", systemImage: "airplane")
                } description: {
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(WaypinTheme.error)
                    } else {
                        Text("아래 버튼으로 첫 여행을 만들어보세요.")
                    }
                } actions: {
                    Button("여행 추가하기") {
                        editStore = Store(initialState: TripEditFeature.State()) {
                            TripEditFeature()
                        }
                    }
                    .buttonStyle(.waypinPrimary)
                    Button("샘플 여행 불러오기") {
                        store.send(.loadSampleDataButtonTapped)
                    }
                }
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
                            onTripSelected(trip)
                        } label: {
                            TripSummaryRowView(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .waypinCardListRow()
                    }
                    .onDelete { store.send(.deleteTrip($0)) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(WaypinTheme.background)
        .navigationTitle("여행 목록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .onAppear { store.send(.onAppear) }
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
                            store.send(.tripSaved(savedTrip))
                            self.editStore = nil
                        }
                    }
            }
        }
    }
}
