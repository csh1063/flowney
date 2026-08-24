import ComposableArchitecture
import CoreLocation
import Foundation

@DependencyClient
public struct CountryLookupClient: Sendable {
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

private actor GeocodeRateLimiter {
    static let shared = GeocodeRateLimiter()

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
