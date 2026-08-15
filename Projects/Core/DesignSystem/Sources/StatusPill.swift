import Models
import SwiftUI

/// 결제상태 등 작은 상태 배지 — Budget 화면에서 텍스트로만 보이던 결제상태를 색으로도
/// 구분되게 한다.
public struct StatusPill: View {
    private let text: String
    private let color: Color

    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 999, style: .continuous))
            .foregroundStyle(color)
    }
}

extension PaymentStatus {
    public var pillColor: Color {
        switch self {
        case .paid: return WaypinTheme.success
        case .fixed, .passinc: return WaypinTheme.accent
        case .pending, .variable: return WaypinTheme.warning
        case .free: return WaypinTheme.textSecondary
        }
    }
}
