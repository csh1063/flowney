import Foundation
import Models

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
