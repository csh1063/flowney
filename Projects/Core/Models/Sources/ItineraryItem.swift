import Foundation

public struct ItineraryItem: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var tripId: UUID
    public var dayId: UUID
    public var sortOrder: Int

    public var itemType: ItemType
    public var arrivalMode: TransportMode?
    public var noRoute: Bool

    public var name: String
    public var placeId: String?
    public var lat: Double?
    public var lng: Double?
    public var address: String?
    public var countryCode: String?

    public var source: ItemSource
    public var sourceURL: String?

    public var startTime: String?
    public var notes: String?

    public var createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case tripId = "trip_id"
        case dayId = "day_id"
        case sortOrder = "sort_order"
        case itemType = "item_type"
        case arrivalMode = "arrival_mode"
        case noRoute = "no_route"
        case name
        case placeId = "place_id"
        case lat
        case lng
        case address
        case countryCode = "country_code"
        case source
        case sourceURL = "source_url"
        case startTime = "start_time"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID = UUID(),
        tripId: UUID,
        dayId: UUID,
        sortOrder: Int = 0,
        itemType: ItemType = .sight,
        arrivalMode: TransportMode? = nil,
        noRoute: Bool = false,
        name: String,
        placeId: String? = nil,
        lat: Double? = nil,
        lng: Double? = nil,
        address: String? = nil,
        countryCode: String? = nil,
        source: ItemSource = .manual,
        sourceURL: String? = nil,
        startTime: String? = nil,
        notes: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.tripId = tripId
        self.dayId = dayId
        self.sortOrder = sortOrder
        self.itemType = itemType
        self.arrivalMode = arrivalMode
        self.noRoute = noRoute
        self.name = name
        self.placeId = placeId
        self.lat = lat
        self.lng = lng
        self.address = address
        self.countryCode = countryCode
        self.source = source
        self.sourceURL = sourceURL
        self.startTime = startTime
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var hasLocation: Bool { lat != nil && lng != nil }
}
