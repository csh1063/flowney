import SwiftUI
import UIKit

/// 앱 아이콘(네이비 여권 + 골드 엠블럼)에 맞춘 앱 전체 색상 토큰.
/// 다크모드 전환 로직은 아직 없지만, 기기가 시스템 다크모드일 때 자동으로 반영되도록
/// `UIColor { trait in ... }` 동적 프로바이더로 라이트/다크 쌍을 만든다 — Asset Catalog
/// Color Set 없이도 동작해서 이 모듈(DesignSystem) 안에서 바로 관리할 수 있다.
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
    // 아이콘/로고성 요소에 쓰는 고정 브랜드색 — 모드와 무관하게 항상 같은 값.
    public static let brandNavyHex = "#2C3E50"
    public static let brandNavy = Color(hex: brandNavyHex)
    public static let brandGold = Color(hex: "#C9A24B")
    public static let brandGoldLight = Color(hex: "#F0D48A")
    public static let brandGoldUIColor = UIColor(hex: "#C9A24B")

    public static let brandNavyUIColor = UIColor(hex: brandNavyHex)

    // 시스템 tint와 동일한 값(AccentColor.colorset과 짝 맞춤) — 라이트는 네이비, 다크는
    // 어두운 배경에서 더 잘 보이는 골드.
    public static let accent = Color(light: "#2C3E50", dark: "#E8C97A")
    public static let accentUIColor = UIColor(light: "#2C3E50", dark: "#E8C97A")
    // accent 배경 위에 얹는 글자색 — 라이트(네이비 배경)는 흰 글자, 다크(골드 배경)는
    // 짙은 남색 글자라야 대비가 나온다.
    public static let accentLabel = Color(light: "#FFFFFF", dark: "#14181D")

    // 처음엔 #F7F4EE였는데 surface(흰색)랑 차이가 너무 미묘해서 실기기에서 안 바뀐 것처럼
    // 보였다 — surface와 뚜렷이 구분되도록 더 진한 톤으로 조정.
    public static let background = Color(light: "#EFE8DA", dark: "#14181D")
    public static let surface = Color(light: "#FFFFFF", dark: "#1E262E")

    public static let textPrimary = Color(light: "#1F2A33", dark: "#F3EFE7")
    public static let textSecondary = Color(light: "#6B7580", dark: "#B9AFA0")
    public static let divider = Color(light: "#E3DED2", dark: "#333F49")

    public static let success = Color(light: "#2F8F5B", dark: "#4FBF8A")
    public static let warning = Color(light: "#C98A2B", dark: "#E0A94A")
    public static let error = Color(light: "#C0392B", dark: "#E0685A")
}
