import Foundation

public enum MemoItemKind: String, Codable, Sendable, CaseIterable {
    case checklist
    case note
}

public struct MemoItem: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var tripId: UUID

    public var kind: MemoItemKind
    public var text: String
    public var isDone: Bool
    public var dueDate: Date?
    public var sortOrder: Int

    public var createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case kind
        case text
        case isDone = "is_done"
        case dueDate = "due_date"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        kind: MemoItemKind,
        text: String,
        isDone: Bool = false,
        dueDate: Date? = nil,
        sortOrder: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.tripId = tripId
        self.kind = kind
        self.text = text
        self.isDone = isDone
        self.dueDate = dueDate
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
