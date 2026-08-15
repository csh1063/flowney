import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

/// "일정 추가" 진입점. 호출한 쪽이 여행/날짜를 이미 알면 곧장 입력 폼으로 시작하고, 모르면
/// 여행 목록 → 달력 순으로 고르게 한 뒤 폼을 보여준다. 상단 헤더는 어느 단계에서든 계속
/// 보이고, 탭하면 그 값을 다시 고를 수 있다.
public struct AddItemFlowView: View {
    @Bindable var store: StoreOf<AddItemFlowFeature>
    // `@Presents`/`ifLet` 대신 View가 직접 AddItemFeature Store를 소유하는 이 프로젝트의
    // 공통 패턴 (project_tca_presents_crash 참고).
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
                // 각 단계 콘텐츠가 화면을 다 못 채우는 크기일 때(로딩 스피너, 빈 상태 등)
                // 남은 공간을 명시적으로 차지하게 강제하지 않으면, `NavigationStack`이 통째로
                // 작아진 콘텐츠(헤더 포함)를 화면 세로 가운데로 정렬해버린다 — 헤더가 위에
                // 고정돼 보이지 않고 화면 중앙으로 같이 밀려 내려가는 원인이었다.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.easeInOut(duration: 0.3), value: store.step)
            .navigationTitle("일정 추가")
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
                            Button("추가") { addItemStore?.send(.saveButtonTapped) }
                        }
                    }
                }
            }
        }
        .onAppear { store.send(.onAppear) }
        .onChange(of: store.addItemRequest) { _, newRequest in
            guard let newRequest else { return }
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
        .onChange(of: addItemStore?.savedItem) { _, savedItem in
            guard let savedItem else { return }
            onItemAdded(savedItem)
        }
    }

    private var dayText: String? {
        guard let day = store.selectedDay else { return nil }
        return day.dayDate.formatted(.dateTime.month().day().weekday(.abbreviated))
    }

    // 폼 단계거나, 아직 한 번도 폼까지 못 가봤으면(addItemStore == nil) "취소"로 마법사
    // 전체를 닫는다. 폼을 채우다가 헤더로 다시 골라보는 중이면 "뒤로"로 폼 복귀만 시킨다.
    private var isLeadingButtonCancel: Bool {
        store.step == .form || addItemStore == nil
    }

    private var leadingButtonTitle: String {
        isLeadingButtonCancel ? "취소" : "뒤로"
    }
}
