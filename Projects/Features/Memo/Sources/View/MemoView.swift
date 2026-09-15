import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit

public struct MemoView: View {
    @Bindable var store: StoreOf<MemoFeature>
    let onTripListRequested: () -> Void
    @FocusState private var isComposeFocused: Bool
    @State private var isEditingComposeDueDate = false

    public init(store: StoreOf<MemoFeature>, onTripListRequested: @escaping () -> Void) {
        self.store = store
        self.onTripListRequested = onTripListRequested
    }

    public var body: some View {
        ZStack {
            // 리스트의 빈 여백처럼 어떤 컨트롤도 없는 자리를 탭했을 때만 키보드를 내리는
            // 배경 레이어 — 세그먼트 컨트롤·버튼 등은 이 레이어보다 앞에 그려지므로
            // 그쪽 탭은 여기로 전달되지 않는다(먼저 소비됨).
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isComposeFocused = false }

            VStack(spacing: 0) {
                Group {
                    if store.isLoading && store.items.isEmpty {
                        ProgressView("불러오는 중…")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(store.items) { item in
                                MemoItemRowView(
                                    item: item,
                                    onToggleDone: { store.send(.toggleDoneButtonTapped(item.id)) },
                                    onDueDateTapped: { store.send(.editDueDateButtonTapped(item.id)) },
                                    onDelete: { store.send(.deleteItem(item.id)) }
                                )
                                .listRowBackground(Color.clear)
                            }
                            .onMove { source, destination in store.send(.itemsMoved(source, destination)) }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .scrollDismissesKeyboard(.immediately)
                    }
                }
                .frame(maxHeight: .infinity)
                .layoutPriority(1)
                composeBar
            }
        }
        .background(FlowneyTheme.background)
        .flowneyLeadingTitle("메모")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                TripManagementMenuButton(
                    trip: store.trip,
                    onTripListRequested: onTripListRequested,
                    onTripUpdated: { store.send(.tripUpdated($0)) }
                )
            }
        }
        .sheet(isPresented: isEditingDueDate) {
            if let id = store.editingDueDateForItemID, let item = store.items[id: id] {
                DueDatePickerSheet(
                    initialDate: item.dueDate ?? MemoFeature.defaultDueDate(for: store.trip),
                    onConfirm: { date in store.send(.dueDateChanged(id, date)) },
                    onClear: { store.send(.dueDateChanged(id, nil)) }
                )
            }
        }
        .onAppear { store.send(.onAppear) }
    }

    private var isEditingDueDate: Binding<Bool> {
        Binding(
            get: { store.editingDueDateForItemID != nil },
            set: { isPresented in
                if !isPresented { store.editingDueDateForItemID = nil }
            }
        )
    }

    private var composeBar: some View {
        VStack(spacing: FlowneySpacing.sm) {
            FlowneySegmentedControl(
                selection: $store.composeKind,
                options: MemoItemKind.allCases,
                label: { $0 == .checklist ? "할 일" : "메모" }
            )

            HStack(alignment: .bottom, spacing: FlowneySpacing.sm) {
                ZStack(alignment: .topLeading) {
                    if store.composeText.isEmpty {
                        Text("새 항목 입력")
                            .font(FlowneyFont.body)
                            .foregroundStyle(FlowneyTheme.textSecondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $store.composeText)
                        .font(FlowneyFont.body)
                        .scrollContentBackground(.hidden)
                        .focused($isComposeFocused)
                }
                .frame(minHeight: 24)
//                .frame(height: 24)

                Button {
                    store.send(.composeSubmitted)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .frame(width: 40, height: 40)
                }
                .disabled(store.composeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if store.composeKind == .checklist {
                Button {
                    isEditingComposeDueDate = true
                } label: {
                    Text(
                        store.composeHasNoDueDate
                            ? "기한없음"
                            : MemoItemRowView.dueDateFormatter.string(from: store.composeDueDate ?? MemoFeature.defaultDueDate(for: store.trip))
                    )
                    .font(.system(size: 14))
                    .foregroundStyle(FlowneyTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(FlowneySpacing.md)
        .background(FlowneyTheme.surface)
        .animation(.easeInOut(duration: 0.2), value: store.composeKind)
        .sheet(isPresented: $isEditingComposeDueDate) {
            DueDatePickerSheet(
                initialDate: store.composeDueDate ?? MemoFeature.defaultDueDate(for: store.trip),
                onConfirm: { date in
                    store.composeDueDate = date
                    store.composeHasNoDueDate = false
                },
                onClear: {
                    store.composeDueDate = nil
                    store.composeHasNoDueDate = true
                }
            )
        }
        .frame(minHeight: 90)
    }
}

private struct DueDatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    @State private var hasTime = false
    let onConfirm: (Date) -> Void
    let onClear: () -> Void

    init(initialDate: Date, onConfirm: @escaping (Date) -> Void, onClear: @escaping () -> Void) {
        _selectedDate = State(initialValue: initialDate)
        self.onConfirm = onConfirm
        self.onClear = onClear
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: FlowneySpacing.md) {
                DatePicker("날짜", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, FlowneySpacing.lg)

                Toggle("시간 지정", isOn: $hasTime.animation())
                    .padding(.horizontal, FlowneySpacing.lg)

                DatePicker("시간", selection: $selectedDate, displayedComponents: .hourAndMinute)
                    .padding(.horizontal, FlowneySpacing.lg)
                    .disabled(!hasTime)
                    .opacity(hasTime ? 1 : 0.4)

                Spacer()
            }
            .padding(.top, FlowneySpacing.sm)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("기한 없음") {
                        onClear()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        onConfirm(selectedDate)
                        dismiss()
                    }
                }
            }
        }
    }
}
