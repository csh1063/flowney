import SwiftUI

public struct WaypinExpandableRow<Label: View, Content: View>: View {
    @State private var isExpanded = false
    private let label: Label
    private let content: Content

    private static var chevronReservedWidth: CGFloat { 20 }

    public init(@ViewBuilder label: () -> Label, @ViewBuilder content: () -> Content) {
        self.label = label()
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: WaypinSpacing.sm) {
                    label
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(WaypinTheme.textSecondary)
                        .frame(width: Self.chevronReservedWidth)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: WaypinSpacing.xs) {
                    content
                }
                .padding(.top, WaypinSpacing.sm)
                .padding(.leading, WaypinSpacing.sm)
                .padding(.trailing, Self.chevronReservedWidth)
            }
        }
    }
}
