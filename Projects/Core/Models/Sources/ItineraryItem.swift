import Foundation

/// `itinerary_items` — travel_map.html의 `{n, lat, lng, t, mode, dur, noRoute}` stop 객체를
/// 실제 편집 가능한 행으로 확장한 모델. 장소·비용·결제상태 필드를 모두 포함.
public struct ItineraryItem: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var tripId: UUID
    public var dayId: UUID
    public var sortOrder: Int

    public var itemType: ItemType
    public var arrivalMode: TransportMode?
    public var plannedDurationMin: Int?
    public var noRoute: Bool

    public var name: String
    public var placeId: String?
    public var lat: Double?
    public var lng: Double?
    public var address: String?
    /// 좌표를 reverse geocoding해서 계산한 ISO 국가코드 — 한 번 계산되면 DB에 저장해두고
    /// 재사용한다(매번 다시 계산하지 않도록). `TripDay.countryCode`(여행 생성 시 한 번 찍히고
    /// 다시 못 바꾸는 값)와 달리, 이 필드는 좌표가 있는 항목마다 개별로 계산된다.
    public var countryCode: String?

    public var source: ItemSource
    public var sourceURL: String?

    public var startTime: String?
    public var costAmount: Decimal?
    public var costCurrency: String?
    public var costAmountKRW: Decimal?
    public var costCategory: CostCategory?
    public var paymentStatus: PaymentStatus?
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
        case plannedDurationMin = "planned_duration_min"
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
        case costAmount = "cost_amount"
        case costCurrency = "cost_currency"
        case costAmountKRW = "cost_amount_krw"
        case costCategory = "cost_category"
        case paymentStatus = "payment_status"
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
        plannedDurationMin: Int? = nil,
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
        costAmount: Decimal? = nil,
        costCurrency: String? = nil,
        costAmountKRW: Decimal? = nil,
        costCategory: CostCategory? = nil,
        paymentStatus: PaymentStatus? = nil,
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
        self.plannedDurationMin = plannedDurationMin
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
        self.costAmount = costAmount
        self.costCurrency = costCurrency
        self.costAmountKRW = costAmountKRW
        self.costCategory = costCategory
        self.paymentStatus = paymentStatus
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// 지도에 찍을 좌표가 있는지 (링크 없이 등록된 "식사, 미정" 같은 항목은 false).
    public var hasLocation: Bool { lat != nil && lng != nil }
}
