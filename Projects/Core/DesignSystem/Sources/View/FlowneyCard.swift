import SwiftUI

private struct FlowneyCardModifier: ViewModifier {
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous)
    }

    func body(content: Content) -> some View {
        content
            .padding(FlowneySpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(shape.fill(FlowneyTheme.surface))
            .overlay(shape.stroke(FlowneyTheme.divider, lineWidth: 1))
    }
}

extension View {
    public func flowneyCard() -> some View {
        modifier(FlowneyCardModifier())
    }

    public func flowneyCardListRow() -> some View {
        listRowInsets(EdgeInsets(top: FlowneySpacing.xs, leading: FlowneySpacing.lg, bottom: FlowneySpacing.xs, trailing: FlowneySpacing.lg))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}
