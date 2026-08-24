import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

public struct AddItemFlowView: View {
    @Bindable var store: StoreOf<AddItemFlowFeature>
    @State private var addItemStore: StoreOf<AddItemFeature>?

    let onItemAdded: (ItineraryItem) -> Void
    let onCancelled: () -> Void

    public init(
        store: StoreOf<AddItemFlowFeature>,
        onItemAdded: @escaping (ItineraryItem) -> Void,
        onCancelled: @escaping () -> Void
    ) {
        self.store = store
        self.onItemAdded = onItemAdded
        self.onCancelled = onCancelled
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                AddItemContextHeaderView(
                    tripName: store.selectedTrip?.name,
                    dayText: dayText,
                    isDayEnabled: store.selectedTrip != nil,
                    onTripTapped: { store.send(.headerTripTapped) },
                    onDayTapped: { store.send(.headerDayTapped) }
                )
                .padding(.top, WaypinSpacing.sm)

                Group {
                    switch store.step {
                    case .tripList:
                        TripSelectionStepView(store: store)
                    case .calendar:
                        DaySelectionCalendarView(store: store)
                    case .form:
                        if let addItemStore {
                            AddItemFormView(store: addItemStore)
                        } else {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.easeInOut(duration: 0.3), value: store.step)
            .navigationTitle(store.isEditing ? "일정 수정" : "일정 추가")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(leadingButtonTitle) {
                        if isLeadingButtonCancel {
                            onCancelled()
                        } else {
                            store.send(.backToFormTapped)
                        }
                    }
                }
                if store.step == .form {
                    ToolbarItem(placement: .confirmationAction) {
                        if let addItemStore, addItemStore.isSaving {
                            ProgressView()
                        } else {
                            Button(store.isEditing ? "수정" : "추가") { addItemStore?.send(.saveButtonTapped) }
                        }
                    }
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
            consumeAddItemRequestIfNeeded()
        }
        .onChange(of: store.addItemRequest) { _, _ in
            consumeAddItemRequestIfNeeded()
        }
        .onChange(of: addItemStore?.savedItem) { _, savedItem in
            guard let savedItem else { return }
            onItemAdded(savedItem)
        }
    }

    private func consumeAddItemRequestIfNeeded() {
        guard let newRequest = store.addItemRequest else { return }
        if let addItemStore {
            addItemStore.send(.contextChanged(
                tripID: newRequest.tripID,
                dayID: newRequest.dayID,
                startingSortOrder: newRequest.startingSortOrder
            ))
        } else {
            addItemStore = Store(initialState: newRequest) { AddItemFeature() }
        }
        store.send(.addItemRequestConsumed)
    }

    private var dayText: String? {
        guard let day = store.selectedDay else { return nil }
        return day.dayDate.formatted(.dateTime.month().day().weekday(.abbreviated))
    }

    private var isLeadingButtonCancel: Bool {
        store.step == .form || addItemStore == nil
    }

    private var leadingButtonTitle: String {
        isLeadingButtonCancel ? "취소" : "뒤로"
    }
}
