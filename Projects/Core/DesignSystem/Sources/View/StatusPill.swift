import Models
import SwiftUI

public struct StatusPill: View {
    private let text: String
    private let color: Color

    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(FlowneyFont.captionEmphasis)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 999, style: .continuous))
            .foregroundStyle(color)
    }
}

extension PaymentStatus {
    public var pillColor: Color {
        switch self {
        case .paid: return FlowneyTheme.success
        case .fixed: return FlowneyTheme.accent
        case .pending: return FlowneyTheme.warning
        }
    }
}
