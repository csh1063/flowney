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

public enum FlowneyTheme {
    public static let brandNavyHex = "#0E1626"
    public static let brandNavy = Color(hex: brandNavyHex)
    public static let brandGold = Color(hex: "#FF6F59")
    public static let brandGoldLight = Color(hex: "#FFB3A3")
    public static let brandGoldUIColor = UIColor(hex: "#FF6F59")

    public static let brandNavyUIColor = UIColor(hex: brandNavyHex)

    /// Accent (Gold) — 여권 문양 포인트, 아이콘 디테일, 강조
    public static let accent = Color(light: "#C89B3C", dark: "#F4C463")
    public static let accentUIColor = UIColor(light: "#C89B3C", dark: "#F4C463")
    public static let accentLabel = Color(light: "#0F2537", dark: "#0A1118")

    /// Brand Primary — 브랜드 핵심 색상, CTA 버튼, 주요 하이라이트 (채워지는 배경)
    public static let fill = Color(light: "#0F2537", dark: "#4C7396")
    public static let fillUIColor = UIColor(light: "#0F2537", dark: "#4C7396")
    public static let fillLabel = Color(light: "#FFFFFF", dark: "#FFFFFF")

    /// Primary Container — Primary 요소 배경, 활성화된 태그
    public static let primaryContainer = Color(light: "#EBF2F7", dark: "#1A3246")
    public static let primaryContainerLabel = fill

    public static let background = Color(light: "#F8F9FA", dark: "#0A1118")
    public static let backgroundUIColor = UIColor(light: "#F8F9FA", dark: "#0A1118")
    public static let surface = Color(light: "#FFFFFF", dark: "#131F2D")

    public static let textPrimary = Color(light: "#111827", dark: "#F3F4F6")
    public static let textSecondary = Color(light: "#4B5563", dark: "#9CA3AF")
    public static let divider = Color(light: "#E5E7EB", dark: "#243647")

    /// Brand Secondary — 보조 포인트 색상, 성공 상태, 서브 뱃지
    public static let success = Color(light: "#1D7A8C", dark: "#4DD0E1")
    public static let warning = Color(light: "#C98A2B", dark: "#E0B25A")
    public static let error = Color(light: "#B23A3A", dark: "#E06868")
}
