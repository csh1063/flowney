import Foundation

public enum TripStatus: String, Codable, Sendable, CaseIterable {
    case planning
    case confirmed
    case completed
    case archived
}

public enum ItemType: String, Codable, Sendable, CaseIterable {
    case airport
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
        case .airport: return "공항"
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
        case .airport: return "✈️"
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

public enum ItemSource: String, Codable, Sendable, CaseIterable {
    case manual
    case link
    case shareExtension = "share_extension"
    case reuse
}

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

public enum PaymentStatus: String, Codable, Sendable, CaseIterable {
    case paid
    case fixed
    case pending

    public var displayName: String {
        switch self {
        case .paid: return "결제완료"
        case .fixed: return "가격확정"
        case .pending: return "미정"
        }
    }
}
