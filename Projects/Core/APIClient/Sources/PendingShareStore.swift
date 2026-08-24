import Foundation

public struct PendingShare: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var urlString: String
    public var savedAt: Date
    public var hasBeenAdded: Bool

    public init(id: UUID = UUID(), urlString: String, savedAt: Date = Date(), hasBeenAdded: Bool = false) {
        self.id = id
        self.urlString = urlString
        self.savedAt = savedAt
        self.hasBeenAdded = hasBeenAdded
    }
}

public enum PendingShareStore {
    public static let appGroupID = "group.com.baci.waypin"
    private static let sharesKey = "pendingShares"

    public static func save(url: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        var shares = list()
        shares.append(PendingShare(urlString: url))
        persist(shares, in: defaults)
        PendingShareAutoOpenFlag.markShared()
    }

    public static func list() -> [PendingShare] {
        guard
            let defaults = UserDefaults(suiteName: appGroupID),
            let data = defaults.data(forKey: sharesKey),
            let shares = try? JSONDecoder().decode([PendingShare].self, from: data)
        else { return [] }
        return shares.sorted { $0.savedAt > $1.savedAt }
    }

    public static func remove(id: PendingShare.ID) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        var shares = list()
        shares.removeAll { $0.id == id }
        persist(shares, in: defaults)
    }

    public static func markAdded(id: PendingShare.ID) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        var shares = list()
        guard let index = shares.firstIndex(where: { $0.id == id }) else { return }
        shares[index].hasBeenAdded = true
        persist(shares, in: defaults)
    }

    private static func persist(_ shares: [PendingShare], in defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(shares) else { return }
        defaults.set(data, forKey: sharesKey)
    }
}

public enum PendingShareAutoOpenFlag {
    private static let key = "shouldAutoOpenShareInboxOnNextLaunch"

    public static func markShared() {
        UserDefaults(suiteName: PendingShareStore.appGroupID)?.set(true, forKey: key)
    }

    public static func consumeShouldAutoOpen() -> Bool {
        guard let defaults = UserDefaults(suiteName: PendingShareStore.appGroupID) else { return false }
        let value = defaults.bool(forKey: key)
        if value { defaults.removeObject(forKey: key) }
        return value
    }
}
