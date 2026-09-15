import Foundation

public enum LastMapCameraStore {
    private static let latKey = "lastMapCameraLat"
    private static let lngKey = "lastMapCameraLng"

    public static func save(lat: Double, lng: Double) {
        UserDefaults.standard.set(lat, forKey: latKey)
        UserDefaults.standard.set(lng, forKey: lngKey)
    }

    public static func read() -> (lat: Double, lng: Double)? {
        guard UserDefaults.standard.object(forKey: latKey) != nil else { return nil }
        let lat = UserDefaults.standard.double(forKey: latKey)
        let lng = UserDefaults.standard.double(forKey: lngKey)
        return (lat, lng)
    }
}
