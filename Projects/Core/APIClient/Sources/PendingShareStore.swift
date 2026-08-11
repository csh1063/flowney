import Foundation

/// 구글맵 공유 확장(Share Extension)이 App Group에 남겨둔 링크를 메인 앱이 읽어가는 통로.
/// 익스텐션은 인증된 Supabase 세션/Keychain을 공유하지 않고 URL+시각만 남기고,
/// 실제 처리(장소 해석, 여행/날짜 선택)는 메인 앱이 다음 실행 때 담당한다.
///
/// 주의: App Group ID(`group.com.baci.waypin`)는 Apple Developer 계정에서 실제로
/// 등록해야 동작한다. 등록 전에는 `UserDefaults(suiteName:)`이 nil을 반환할 뿐 크래시는 안 남.
public enum PendingShareStore {
    public static let appGroupID = "group.com.baci.waypin"
    private static let urlKey = "pendingSharedURL"
    private static let timestampKey = "pendingSharedAt"

    public static func save(url: String) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        defaults.set(url, forKey: urlKey)
        defaults.set(Date().timeIntervalSince1970, forKey: timestampKey)
    }

    /// 대기중인 링크를 꺼내면서(1회용) 동시에 지운다.
    public static func consumePendingURL() -> String? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return nil }
        guard let url = defaults.string(forKey: urlKey) else { return nil }
        defaults.removeObject(forKey: urlKey)
        defaults.removeObject(forKey: timestampKey)
        return url
    }
}
