import SwiftUI

public enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    public static let storageKey = "appearanceMode"

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }

    public var displayName: String {
        switch self {
        case .system: "시스템"
        case .light: "라이트"
        case .dark: "다크"
        }
    }
}
