import SwiftUI

private struct WaypinCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(WaypinSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous)
                    .fill(WaypinTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: WaypinRadius.lg, style: .continuous)
                    .stroke(WaypinTheme.divider, lineWidth: 1)
            )
    }
}

extension View {
    public func waypinCard() -> some View {
        modifier(WaypinCardModifier())
    }

    public func waypinCardListRow() -> some View {
        listRowInsets(EdgeInsets(top: WaypinSpacing.xs, leading: WaypinSpacing.lg, bottom: WaypinSpacing.xs, trailing: WaypinSpacing.lg))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
