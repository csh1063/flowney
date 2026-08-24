import SwiftUI
import UIKit

extension UIColor {
    public convenience init(light: String, dark: String) {
        self.init { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension Color {
    public init(light: String, dark: String) {
        self.init(uiColor: UIColor(light: light, dark: dark))
    }
}

public enum WaypinTheme {
    public static let brandNavyHex = "#2C3E50"
    public static let brandNavy = Color(hex: brandNavyHex)
    public static let brandGold = Color(hex: "#C9A24B")
    public static let brandGoldLight = Color(hex: "#F0D48A")
    public static let brandGoldUIColor = UIColor(hex: "#C9A24B")

    public static let brandNavyUIColor = UIColor(hex: brandNavyHex)

    public static let accent = Color(light: "#2C3E50", dark: "#E8C97A")
    public static let accentUIColor = UIColor(light: "#2C3E50", dark: "#E8C97A")
    public static let accentLabel = Color(light: "#FFFFFF", dark: "#14181D")

    public static let background = Color(light: "#EFE8DA", dark: "#14181D")
    public static let backgroundUIColor = UIColor(light: "#EFE8DA", dark: "#14181D")
    public static let surface = Color(light: "#FFFFFF", dark: "#1E262E")

    public static let textPrimary = Color(light: "#1F2A33", dark: "#F3EFE7")
    public static let textSecondary = Color(light: "#6B7580", dark: "#B9AFA0")
    public static let divider = Color(light: "#E3DED2", dark: "#333F49")

    public static let success = Color(light: "#2F8F5B", dark: "#4FBF8A")
    public static let warning = Color(light: "#C98A2B", dark: "#E0A94A")
    public static let error = Color(light: "#C0392B", dark: "#E0685A")
}
