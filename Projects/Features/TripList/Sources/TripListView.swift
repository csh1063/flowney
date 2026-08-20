import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

public struct TripListView: View {
    @Bindable var store: StoreOf<TripListFeature>
    @Environment(\.dismiss) private var dismiss
    // TCA의 `@Presents`/`PresentationState`/`ifLet` 프레젠테이션 메커니즘이 이 프로젝트가
    // 쓰는 툴체인(Xcode 26.3 / Swift 6.2.4)에서 TCA 1.26.1과 조합했을 때 실기기에서
    // EXC_BAD_ACCESS를 유발하는 게 확인돼서(내용물을 빈 reducer로 바꿔도, `$store.scope`를
    // 안 써도 동일하게 재현됨 — 원인이 `@Presents`/`ifLet` 자체), 이 화면만은 그 메커니즘을
    // 전혀 쓰지 않고 순수 SwiftUI `@State` + 독립된 Store로 프레젠테이션을 직접 관리한다.
    @State private var editStore: StoreOf<TripEditFeature>?
    // 화면 전환은 부모(RootView)가 NavigationStack(path:)로 관리하므로, 탭 이벤트만 콜백으로
    // 위로 전달한다.
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
                            .foregroundStyle(.red)
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
