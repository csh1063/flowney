import Foundation
import Models

/// 지도 탭에서 마지막으로 보던 여행을 기억해두는 저장소. `PendingShareStore`와 달리 앱
/// 익스텐션과 공유할 필요가 없어서 App Group이 아니라 그냥 `UserDefaults.standard`를 쓴다.
///
/// 주의: 저장(`save`)은 여행 선택 시 이미 연결돼 있지만, 앱 시작 시 `read()`로 자동 복원해서
/// 곧장 지도 탭에 띄우는 호출은 아직 어디서도 하지 않는다(의도적 — 매번 빈 상태부터 시작해서
/// "여행 불러오기" 수동 플로우를 테스트해보기 위함). 자동 복원은 나중에 별도로 연결한다.
public enum LastTripStore {
    private static let key = "lastViewedTripID"

    public static func save(tripID: Trip.ID) {
        UserDefaults.standard.set(tripID.uuidString, forKey: key)
    }

    public static func read() -> Trip.ID? {
        guard let raw = UserDefaults.standard.string(forKey: key) else { return nil }
        return UUID(uuidString: raw)
    }
}
