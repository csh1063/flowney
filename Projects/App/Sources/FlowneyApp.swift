import ComposableArchitecture
import Root
import SwiftUI

@main
struct FlowneyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: Self.store)
        }
    }
}
