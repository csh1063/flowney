import Foundation

public enum TripStatus: String, Codable, Sendable, CaseIterable {
    case planning
    case confirmed
    case completed
    case archived
}

/// `itinerary_items.item_type`
public enum ItemType: String, Codable, Sendable, CaseIterable {
    case start
    case sight
    case meal
    case lodge
    case transport
    case activity
    case shopping
    case freeTime = "free_time"
    case other

    public var displayName: String {
        switch self {
        case .start: return "출발"
        case .sight: return "관광"
        case .meal: return "식사"
        case .lodge: return "숙소"
        case .transport: return "이동"
        case .activity: return "액티비티"
        case .shopping: return "쇼핑"
        case .freeTime: return "자유시간"
        case .other: return "기타"
        }
    }

    public var icon: String {
        switch self {
        case .start: return "🚩"
        case .sight: return "📍"
        case .meal: return "🍽️"
        case .lodge: return "🛏️"
        case .transport: return "🚗"
        case .activity: return "🎟️"
        case .shopping: return "🛍️"
        case .freeTime: return "☕️"
        case .other: return "📌"
        }
    }
}

/// `itinerary_items.arrival_mode` — 이 항목에 "도착할 때" 사용한 교통수단.
public enum TransportMode: String, Codable, Sendable, CaseIterable {
    case start
    case walk
    case tram
    case metro
    case train
    case bus
    case gondola
    case funicular
    case car
    case boat
    /// 산악 톱니바퀴 열차(융프라우요흐 구간 등) — 구글 Directions가 별도 vehicle type으로
    /// 구분해주지 않아 실제 경로탐색 결과로는 절대 나오지 않고, 수동으로만 지정된다.
    case cograil

    public var displayName: String {
        switch self {
        case .start: return "시작"
        case .walk: return "도보"
        case .tram: return "트램"
        case .metro: return "지하철"
        case .train: return "기차"
        case .bus: return "버스"
        case .gondola: return "곤돌라"
        case .funicular: return "푸니쿨라"
        case .car: return "자동차"
        case .boat: return "선박"
        case .cograil: return "산악톱니열차"
        }
    }

    /// html의 MODE_DURATION(ms)에서 출발은 그대로 두고, 도보는 1.2초로, 그 외(환승 대기
    /// 시간 제외)는 각각 0.2초씩 줄인 값.
    public var baseAnimationDurationMs: Double {
        switch self {
        case .start: return 300
        case .walk: return 1200
        case .train, .cograil: return 600
        case .metro, .tram: return 800
        case .bus: return 1000
        case .gondola, .funicular: return 800
        case .car: return 1000
        case .boat: return 800
        }
    }
}

/// `itinerary_items.source`
public enum ItemSource: String, Codable, Sendable, CaseIterable {
    case manual
    case link
    case shareExtension = "share_extension"
    case reuse
}

/// `itinerary_items.cost_category`
public enum CostCategory: String, Codable, Sendable, CaseIterable {
    case entrance
    case transport
    case food
    case lodging
    case shopping
    case activity
    case other

    public var displayName: String {
        switch self {
        case .entrance: return "입장료"
        case .transport: return "교통비"
        case .food: return "식비"
        case .lodging: return "숙박비"
        case .shopping: return "쇼핑"
        case .activity: return "액티비티"
        case .other: return "기타"
        }
    }
}

/// `itinerary_items.payment_status` — travel_map.html의 결제완료/가격확정/미정/가격변동/패스포함/무료 pill과 1:1.
public enum PaymentStatus: String, Codable, Sendable, CaseIterable {
    case paid
    case fixed
    case pending
    case variable
    case passinc
    case free

    public var displayName: String {
        switch self {
        case .paid: return "결제완료"
        case .fixed: return "가격확정"
        case .pending: return "미정"
        case .variable: return "가격변동"
        case .passinc: return "패스포함"
        case .free: return "무료"
        }
    }
}
