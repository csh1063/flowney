import ComposableArchitecture
import DesignSystem
import Root
import SwiftUI

@main
struct WaypinApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    init() {
        WaypinFont.applyUIKitAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: Self.store)
        }
    }
}
