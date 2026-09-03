import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(WaypinFont.bodyEmphasis)
            .foregroundStyle(WaypinTheme.fillLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(WaypinTheme.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var waypinPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
