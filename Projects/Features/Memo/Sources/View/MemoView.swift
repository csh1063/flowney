import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI
import TripEdit
import UIKit

public struct MemoView: View {
    @Bindable var store: StoreOf<MemoFeature>
    let onTripListRequested: () -> Void
    @FocusState private var isComposeFocused: Bool
    @State private var isEditingComposeDueDate = false
    @State private var keyboardDismissGesture: UITapGestureRecognizer?

    public init(store: StoreOf<MemoFeature>, onTripListRequested: @escaping () -> Void) {
        self.store = store
        self.onTripListRequested = onTripListRequested
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            // 리스트의 빈 여백처럼 어떤 컨트롤도 없는 자리를 탭했을 때만 키보드를 내리는
            // 배경 레이어 — 세그먼트 컨트롤·버튼 등은 이 레이어보다 앞에 그려지므로
            // 그쪽 탭은 여기로 전달되지 않는다(먼저 소비됨).
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { isComposeFocused = false }

//            VStack(spacing: 0) {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)
                composeBar
//            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: isComposeFocused ? 12 : 72) }
        .background(FlowneyTheme.background)
        .flowneyLeadingTitle(store.trip.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                TripManagementMenuButton(
                    trip: store.trip,
                    onTripListRequested: onTripListRequested,
                    onTripUpdated: { store.send(.tripUpdated($0)) }
                )
                .simultaneousGesture(TapGesture().onEnded { isComposeFocused = false })
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
        .onAppear {
            store.send(.onAppear)
            installKeyboardDismissGesture()
        }
        .onDisappear {
            removeKeyboardDismissGesture()
        }
    }

    private func installKeyboardDismissGesture() {
        guard keyboardDismissGesture == nil,
              let window = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first
        else { return }
        let gesture = UITapGestureRecognizer(
            target: UIApplication.shared,
            action: #selector(UIApplication.flowneyResignFirstResponder)
        )
        gesture.cancelsTouchesInView = false
        window.addGestureRecognizer(gesture)
        keyboardDismissGesture = gesture
    }

    private func removeKeyboardDismissGesture() {
        guard let gesture = keyboardDismissGesture,
              let window = UIApplication.shared.connectedScenes
                .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                .first
        else { return }
        window.removeGestureRecognizer(gesture)
        keyboardDismissGesture = nil
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
                TextField("새 항목 입력", text: $store.composeText, axis: .vertical)
                    .font(FlowneyFont.body)
                    .lineLimit(1...5)
                    .focused($isComposeFocused)

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
        .background(
            RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous)
                .fill(FlowneyTheme.surface)
                .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        )
        .padding(.horizontal, FlowneySpacing.lg)
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
    }
}

extension UIApplication {
    @objc fileprivate func flowneyResignFirstResponder() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
