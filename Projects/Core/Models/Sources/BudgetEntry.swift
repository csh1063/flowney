import Foundation

public struct BudgetEntry: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var tripId: UUID

    public var name: String
    public var costAmount: Decimal?
    public var costCurrency: String?
    public var costAmountKRW: Decimal?
    public var costCategory: CostCategory?
    public var paymentStatus: PaymentStatus?
    public var notes: String?
    public var date: Date?
    public var linkedItemId: UUID?

    public var createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case name
        case costAmount = "cost_amount"
        case costCurrency = "cost_currency"
        case costAmountKRW = "cost_amount_krw"
        case costCategory = "cost_category"
        case paymentStatus = "payment_status"
        case notes
        case date
        case linkedItemId = "linked_item_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        name: String,
        costAmount: Decimal? = nil,
        costCurrency: String? = nil,
        costAmountKRW: Decimal? = nil,
        costCategory: CostCategory? = nil,
        paymentStatus: PaymentStatus? = nil,
        notes: String? = nil,
        date: Date? = nil,
        linkedItemId: UUID? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.tripId = tripId
        self.name = name
        self.costAmount = costAmount
        self.costCurrency = costCurrency
        self.costAmountKRW = costAmountKRW
        self.costCategory = costCategory
        self.paymentStatus = paymentStatus
        self.notes = notes
        self.date = date
        self.linkedItemId = linkedItemId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        tripId = try container.decode(UUID.self, forKey: .tripId)
        name = try container.decode(String.self, forKey: .name)
        costAmount = try container.decodeIfPresent(Decimal.self, forKey: .costAmount)
        costCurrency = try container.decodeIfPresent(String.self, forKey: .costCurrency)
        costAmountKRW = try container.decodeIfPresent(Decimal.self, forKey: .costAmountKRW)
        costCategory = try container.decodeIfPresent(CostCategory.self, forKey: .costCategory)
        paymentStatus = try container.decodeIfPresent(PaymentStatus.self, forKey: .paymentStatus)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        date = try DateOnly.decodeIfPresent(container, forKey: .date)
        linkedItemId = try container.decodeIfPresent(UUID.self, forKey: .linkedItemId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tripId, forKey: .tripId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(costAmount, forKey: .costAmount)
        try container.encodeIfPresent(costCurrency, forKey: .costCurrency)
        try container.encodeIfPresent(costAmountKRW, forKey: .costAmountKRW)
        try container.encodeIfPresent(costCategory, forKey: .costCategory)
        try container.encodeIfPresent(paymentStatus, forKey: .paymentStatus)
        try container.encodeIfPresent(notes, forKey: .notes)
        if let date {
            try container.encode(DateOnly.formatter.string(from: date), forKey: .date)
        } else {
            try container.encodeNil(forKey: .date)
        }
        try container.encodeIfPresent(linkedItemId, forKey: .linkedItemId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
