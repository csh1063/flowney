import SwiftUI

/// 브랜드 accent 색을 쓰는 공용 주요 액션 버튼 스타일(로그인/저장/추가 등).
public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(WaypinTheme.accentLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(WaypinTheme.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var waypinPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
