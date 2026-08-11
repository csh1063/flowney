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
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: lat, longitude: lng)
            guard let placemarks = try? await geocoder.reverseGeocodeLocation(location) else { return nil }
            return placemarks.first?.isoCountryCode
        }
    )
}

extension DependencyValues {
    public var countryLookupClient: CountryLookupClient {
        get { self[CountryLookupClient.self] }
        set { self[CountryLookupClient.self] = newValue }
    }
}
