import SwiftUI

public enum WaypinCardCorners {
    case all
    case leadingOnly
}

private struct WaypinCardModifier: ViewModifier {
    var corners: WaypinCardCorners

    private var shape: UnevenRoundedRectangle {
        switch corners {
        case .all:
            UnevenRoundedRectangle(
                topLeadingRadius: WaypinRadius.lg,
                bottomLeadingRadius: WaypinRadius.lg,
                bottomTrailingRadius: WaypinRadius.lg,
                topTrailingRadius: WaypinRadius.lg,
                style: .continuous
            )
        case .leadingOnly:
            UnevenRoundedRectangle(
                topLeadingRadius: WaypinRadius.lg,
                bottomLeadingRadius: WaypinRadius.lg,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        }
    }

    func body(content: Content) -> some View {
        content
            .padding(WaypinSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(WaypinTheme.surface))
            .overlay(shape.stroke(WaypinTheme.divider, lineWidth: 1))
    }
}

extension View {
    public func waypinCard(corners: WaypinCardCorners = .all) -> some View {
        modifier(WaypinCardModifier(corners: corners))
    }

    public func waypinCardListRow() -> some View {
        listRowInsets(EdgeInsets(top: WaypinSpacing.xs, leading: WaypinSpacing.lg, bottom: WaypinSpacing.xs, trailing: WaypinSpacing.lg))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
