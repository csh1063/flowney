import Foundation

public enum DateOnly {
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static func normalizeToUTCMidnight(_ date: Date, referenceCalendar: Calendar = .current) -> Date {
        let components = referenceCalendar.dateComponents([.year, .month, .day], from: date)
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        return utcCalendar.date(from: components)!
    }

    static func decode(_ container: KeyedDecodingContainer<Trip.CodingKeys>, forKey key: Trip.CodingKeys) throws -> Date {
        let string = try container.decode(String.self, forKey: key)
        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Invalid date-only format: \(string)")
        }
        return date
    }

    static func decode(_ container: KeyedDecodingContainer<TripDay.CodingKeys>, forKey key: TripDay.CodingKeys) throws -> Date {
        let string = try container.decode(String.self, forKey: key)
        guard let date = formatter.date(from: string) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Invalid date-only format: \(string)")
        }
        return date
    }
}

public struct Trip: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var ownerId: UUID
    public var name: String
    public var startDate: Date
    public var endDate: Date
    public var status: TripStatus
    public var createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case name
        case startDate = "start_date"
        case endDate = "end_date"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        ownerId: UUID,
        name: String,
        startDate: Date,
        endDate: Date,
        status: TripStatus = .planning,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        ownerId = try container.decode(UUID.self, forKey: .ownerId)
        name = try container.decode(String.self, forKey: .name)
        startDate = try DateOnly.decode(container, forKey: .startDate)
        endDate = try DateOnly.decode(container, forKey: .endDate)
        status = try container.decode(TripStatus.self, forKey: .status)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(name, forKey: .name)
        try container.encode(DateOnly.formatter.string(from: startDate), forKey: .startDate)
        try container.encode(DateOnly.formatter.string(from: endDate), forKey: .endDate)
        try container.encode(status, forKey: .status)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}

public struct TripCountry: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var tripId: UUID
    public var countryCode: String
    public var color: String
    public var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case countryCode = "country_code"
        case color
        case sortOrder = "sort_order"
    }

    public init(id: UUID = UUID(), tripId: UUID, countryCode: String, color: String, sortOrder: Int = 0) {
        self.id = id
        self.tripId = tripId
        self.countryCode = countryCode
        self.color = color
        self.sortOrder = sortOrder
    }
}

public struct TripDay: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var tripId: UUID
    public var countryCode: String
    public var dayDate: Date
    public var dayIndex: Int
    public var label: String?

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case countryCode = "country_code"
        case dayDate = "day_date"
        case dayIndex = "day_index"
        case label
    }

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        countryCode: String,
        dayDate: Date,
        dayIndex: Int,
        label: String? = nil
    ) {
        self.id = id
        self.tripId = tripId
        self.countryCode = countryCode
        self.dayDate = dayDate
        self.dayIndex = dayIndex
        self.label = label
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        tripId = try container.decode(UUID.self, forKey: .tripId)
        countryCode = try container.decode(String.self, forKey: .countryCode)
        dayDate = try DateOnly.decode(container, forKey: .dayDate)
        dayIndex = try container.decode(Int.self, forKey: .dayIndex)
        label = try container.decodeIfPresent(String.self, forKey: .label)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tripId, forKey: .tripId)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(DateOnly.formatter.string(from: dayDate), forKey: .dayDate)
        try container.encode(dayIndex, forKey: .dayIndex)
        try container.encodeIfPresent(label, forKey: .label)
    }
}
