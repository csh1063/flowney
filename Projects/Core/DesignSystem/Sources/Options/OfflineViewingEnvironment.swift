import SwiftUI

private struct IsOfflineViewingKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    public var isOfflineViewing: Bool {
        get { self[IsOfflineViewingKey.self] }
        set { self[IsOfflineViewingKey.self] = newValue }
    }
}
