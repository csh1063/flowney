import ComposableArchitecture
import CoreLocation
import Foundation

/// 일정 항목의 좌표를 ISO 국가 코드로 바꾼다 — `TripDay.countryCode`(수동/DB에서만 바뀌는 값이라
/// 실제 여행과 어긋나기 쉬웠다)를 더 이상 신뢰하지 않고, "그날 등록된 좌표가 실제로 어느 나라인지"를
/// 매번 좌표에서 직접 계산하기 위해 도입했다. `CLGeocoder`는 애플 서버로 요청을 보내는 비동기
/// API라 호출 측(ItineraryFeature)에서 항목별로 캐싱해서 중복 호출을 피해야 한다.
@DependencyClient
public struct CountryLookupClient: Sendable {
    /// 실패하거나 국가를 특정할 수 없으면 nil.
    public var countryCode: @Sendable (_ lat: Double, _ lng: Double) async -> String?
}

extension CountryLookupClient: DependencyKey {
    public static let liveValue = CountryLookupClient(
        countryCode: { lat, lng in
            await GeocodeRateLimiter.shared.waitForSlot()
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: lat, longitude: lng)
            guard let placemarks = try? await geocoder.reverseGeocodeLocation(location) else { return nil }
            return placemarks.first?.isoCountryCode
        }
    )
}

/// `CLGeocoder`는 애플이 60초에 50건으로 제한한다(넘으면 "Throttled" 에러만 계속 돌아옴).
/// 여행 하나가 항목 100개가 넘어가면(대량 샘플 데이터 등) 전부 동시에 지오코딩을 시도해서
/// 순식간에 한도를 넘기고 실패가 반복되므로, 실제로 CLGeocoder를 부르기 직전에 이 슬라이딩
/// 윈도우 리미터를 거쳐서 초과분은 자리가 날 때까지 자연스럽게 대기시킨다.
private actor GeocodeRateLimiter {
    static let shared = GeocodeRateLimiter()

    // 애플 한도(50/60초)보다 여유를 둔 안전값.
    private let maxRequestsPerWindow = 40
    private let window: TimeInterval = 60
    private var requestTimestamps: [Date] = []

    func waitForSlot() async {
        while true {
            let now = Date()
            requestTimestamps.removeAll { now.timeIntervalSince($0) > window }
            if requestTimestamps.count < maxRequestsPerWindow {
                requestTimestamps.append(now)
                return
            }
            let oldest = requestTimestamps[0]
            let waitSeconds = max(window - now.timeIntervalSince(oldest), 0.1)
            try? await Task.sleep(nanoseconds: UInt64(waitSeconds * 1_000_000_000))
        }
    }
}

extension DependencyValues {
    public var countryLookupClient: CountryLookupClient {
        get { self[CountryLookupClient.self] }
        set { self[CountryLookupClient.self] = newValue }
    }
}
