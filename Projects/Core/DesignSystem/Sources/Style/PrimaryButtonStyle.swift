import SwiftUI

public struct PrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FlowneyFont.bodyEmphasis)
            .foregroundStyle(FlowneyTheme.fillLabel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(FlowneyTheme.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    public static var flowneyPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}
