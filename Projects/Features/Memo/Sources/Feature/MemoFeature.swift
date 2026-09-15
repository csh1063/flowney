import APIClient
import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct MemoFeature {
    @ObservableState
    public struct State: Equatable {
        public var trip: Trip
        public var items: IdentifiedArrayOf<MemoItem> = []
        public var isLoading = false
        public var errorMessage: String?

        public var composeText: String = ""
        public var composeKind: MemoItemKind = .note
        public var composeDueDate: Date?
        public var composeHasNoDueDate: Bool = true

        public var editingDueDateForItemID: MemoItem.ID?

        public init(trip: Trip) {
            self.trip = trip
        }
    }

    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case itemsResponse(Result<[MemoItem], any Error>)

        case composeSubmitted
        case createResponse(Result<MemoItem, any Error>)

        case toggleDoneButtonTapped(MemoItem.ID)
        case toggleDoneResponse(Result<MemoItem, any Error>)

        case editDueDateButtonTapped(MemoItem.ID)
        case dueDateChanged(MemoItem.ID, Date?)
        case dueDateUpdateResponse(Result<MemoItem, any Error>)

        case deleteItem(MemoItem.ID)
        case deleteItemResponse(Result<MemoItem.ID, any Error>)

        case itemsMoved(IndexSet, Int)
        case reorderPersistResponse(Result<Void, any Error>)

        case notificationAuthorizationResponse(Bool)
        case tripUpdated(Trip)
    }

    @Dependency(\.memoItemRepository) var memoItemRepository
    @Dependency(\.notificationScheduler) var notificationScheduler
    @Dependency(\.uuid) var uuid

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = true
                let tripID = state.trip.id
                return .merge(
                    .run { send in
                        do {
                            let items = try await memoItemRepository.fetchAllItems(tripID)
                            await send(.itemsResponse(.success(items)))
                        } catch {
                            await send(.itemsResponse(.failure(error)))
                        }
                    },
                    .run { send in
                        let granted = await notificationScheduler.requestAuthorization()
                        await send(.notificationAuthorizationResponse(granted))
                    }
                )

            case let .itemsResponse(.success(items)):
                state.isLoading = false
                state.items = IdentifiedArrayOf(uniqueElements: items.sorted { $0.sortOrder < $1.sortOrder })
                return .none

            case let .itemsResponse(.failure(error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none

            case .notificationAuthorizationResponse:
                return .none

            case let .tripUpdated(trip):
                state.trip = trip
                return .none

            case .composeSubmitted:
                let trimmed = state.composeText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }

                let dueDate: Date? = {
                    guard state.composeKind == .checklist, !state.composeHasNoDueDate else { return nil }
                    return state.composeDueDate ?? Self.defaultDueDate(for: state.trip)
                }()

                let item = MemoItem(
                    id: uuid(),
                    tripId: state.trip.id,
                    kind: state.composeKind,
                    text: trimmed,
                    dueDate: dueDate,
                    sortOrder: state.items.count
                )
                state.items.append(item)
                state.composeText = ""
                state.composeDueDate = nil
                state.composeHasNoDueDate = true

                return .run { [memoItemRepository, notificationScheduler, item] send in
                    do {
                        let saved = try await memoItemRepository.createItem(item)
                        if saved.kind == .checklist, let dueDate = saved.dueDate {
                            await notificationScheduler.scheduleReminder(saved.id, saved.text, dueDate)
                        }
                        await send(.createResponse(.success(saved)))
                    } catch {
                        await send(.createResponse(.failure(error)))
                    }
                }

            case let .createResponse(.success(item)):
                state.items[id: item.id] = item
                return .none

            case let .createResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .toggleDoneButtonTapped(id):
                guard var item = state.items[id: id] else { return .none }
                item.isDone.toggle()

                state.items.remove(id: id)
                if item.isDone {
                    state.items.append(item)
                } else {
                    state.items.insert(item, at: 0)
                }
                for (index, itemID) in state.items.ids.enumerated() {
                    state.items[id: itemID]?.sortOrder = index
                }
                item = state.items[id: item.id] ?? item
                let reorderUpdates = state.items.map { MemoItemReorderUpdate(id: $0.id, sortOrder: $0.sortOrder) }

                return .run { [memoItemRepository, notificationScheduler, item, reorderUpdates] send in
                    do {
                        let saved = try await memoItemRepository.updateItem(item)
                        if saved.isDone {
                            await notificationScheduler.cancelReminder(saved.id)
                        } else if let dueDate = saved.dueDate {
                            await notificationScheduler.scheduleReminder(saved.id, saved.text, dueDate)
                        }
                        try await memoItemRepository.reorderItems(reorderUpdates)
                        await send(.toggleDoneResponse(.success(saved)))
                    } catch {
                        await send(.toggleDoneResponse(.failure(error)))
                    }
                }

            case let .toggleDoneResponse(.success(item)):
                state.items[id: item.id] = item
                return .none

            case let .toggleDoneResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .editDueDateButtonTapped(id):
                state.editingDueDateForItemID = id
                return .none

            case let .dueDateChanged(id, newDate):
                state.editingDueDateForItemID = nil
                guard var item = state.items[id: id] else { return .none }
                item.dueDate = newDate
                state.items[id: id] = item

                return .run { [memoItemRepository, notificationScheduler, item] send in
                    do {
                        let saved = try await memoItemRepository.updateItem(item)
                        await notificationScheduler.cancelReminder(saved.id)
                        if let dueDate = saved.dueDate, !saved.isDone {
                            await notificationScheduler.scheduleReminder(saved.id, saved.text, dueDate)
                        }
                        await send(.dueDateUpdateResponse(.success(saved)))
                    } catch {
                        await send(.dueDateUpdateResponse(.failure(error)))
                    }
                }

            case let .dueDateUpdateResponse(.success(item)):
                state.items[id: item.id] = item
                return .none

            case let .dueDateUpdateResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .deleteItem(id):
                state.items.remove(id: id)
                return .run { [memoItemRepository, notificationScheduler, id] send in
                    await notificationScheduler.cancelReminder(id)
                    do {
                        try await memoItemRepository.deleteItem(id)
                        await send(.deleteItemResponse(.success(id)))
                    } catch {
                        await send(.deleteItemResponse(.failure(error)))
                    }
                }

            case .deleteItemResponse(.success):
                return .none

            case let .deleteItemResponse(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none

            case let .itemsMoved(source, destination):
                state.items.move(fromOffsets: source, toOffset: destination)
                for (index, id) in state.items.ids.enumerated() {
                    state.items[id: id]?.sortOrder = index
                }
                let updates = state.items.map { MemoItemReorderUpdate(id: $0.id, sortOrder: $0.sortOrder) }
                return .run { [memoItemRepository, updates] send in
                    do {
                        try await memoItemRepository.reorderItems(updates)
                        await send(.reorderPersistResponse(.success(())))
                    } catch {
                        await send(.reorderPersistResponse(.failure(error)))
                    }
                }

            case .reorderPersistResponse:
                return .none
            }
        }
    }

    static func defaultDueDate(for trip: Trip) -> Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: trip.endDate) ?? trip.endDate
    }
}
