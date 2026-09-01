import Foundation
import Models

public enum TripCurrencyStore {
    private static func key(_ tripID: Trip.ID) -> String {
        "tripCurrencies_\(tripID.uuidString)"
    }

    public static func read(tripID: Trip.ID) -> [String] {
        UserDefaults.standard.stringArray(forKey: key(tripID)) ?? []
    }

    public static func save(tripID: Trip.ID, currencies: [String]) {
        UserDefaults.standard.set(currencies, forKey: key(tripID))
    }
}
