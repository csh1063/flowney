import Foundation

/// 구글맵 공유 확장(Share Extension)이 App Group에 남겨둔 링크 하나.
public struct PendingShare: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var urlString: String
    public var savedAt: Date
    /// 이 링크로 "어느 여행이든" 일정 추가를 한 번이라도 성공한 적 있는지. 뱃지 표시 기준 —
    /// 링크 자체는 사용 후에도 리스트에서 지워지지 않고 남는다(사용자가 직접 삭제하기 전까지).
    public var hasBeenAdded: Bool

    public init(id: UUID = UUID(), urlString: String, savedAt: Date = Date(), hasBeenAdded: Bool = false) {
        self.id = id
        self.urlString = urlString
        self.savedAt = savedAt
        self.hasBeenAdded = hasBeenAdded
    }
}

/// 구글맵 공유 확장(Share Extension)이 App Group에 남겨둔 링크들을 메인 앱이 읽어가는 통로.
/// 익스텐션은 인증된 Supabase 세션/Keychain을 공유하지 않고 URL+시각만 남기고,
/// 실제 처리(장소 해석, 여행/날짜 선택)는 메인 앱의 "공유 링크함"이 담당한다.
///
/// 여러 개를 모아두는 목록형 저장소다 — 링크는 일정에 추가해도 지워지지 않고 계속 남고,
/// 사용자가 명시적으로 삭제하기 전까지 유지된다(`hasBeenAdded`는 뱃지 표시용 플래그일 뿐).
///
/// 주의: App Group ID(`group.com.baci.waypin`)는 Apple Developer 계정에서 실제로
/// 등록해야 동작한다. 등록 전에는 `UserDefaults(suiteName:)`이 nil을 반환할 뿐 크래시는 안 남.
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

    /// 최근 저장 순으로 전체 목록을 읽는다 (읽는다고 지워지지 않는다 — 예전 단일 슬롯 버전의
    /// `consumePendingURL()`과 달리 비파괴적).
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

    /// 이 링크로 어느 여행이든 일정 추가에 성공했을 때 호출 — 뱃지를 영구적으로 없앤다.
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

/// "공유 익스텐션으로 링크를 저장한 뒤, 앱을 다음에 켰을 때 공유링크함을 자동으로 한 번
/// 열어줄지" 여부를 담는 1회성 플래그. 익스텐션이 세우고, 메인 앱이 다음 실행에서 딱 한 번
/// 소비(읽으면서 끔)한다 — 그 이후 재실행에서는 다시 안 뜬다.
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
