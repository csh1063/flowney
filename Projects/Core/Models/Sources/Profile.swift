import Foundation

public struct Profile: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var displayName: String?
    public var avatarURL: String?
    public var preferredCurrency: String
    public var locale: String
    public var createdAt: Date
    public var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case preferredCurrency = "preferred_currency"
        case locale
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    public init(
        id: UUID,
        displayName: String? = nil,
        avatarURL: String? = nil,
        preferredCurrency: String = "KRW",
        locale: String = "ko",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.preferredCurrency = preferredCurrency
        self.locale = locale
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
