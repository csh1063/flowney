import SwiftUI

public struct WaypinSegmentedControl<Option: Hashable>: View {
    @Binding private var selection: Option
    private let options: [Option]
    private let label: (Option) -> String

    public init(selection: Binding<Option>, options: [Option], label: @escaping (Option) -> String) {
        self._selection = selection
        self.options = options
        self.label = label
    }

    public var body: some View {
        HStack(spacing: WaypinSpacing.sm) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(WaypinFont.bodyEmphasis)
                        .foregroundStyle(isSelected ? WaypinTheme.fillLabel : WaypinTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, WaypinSpacing.sm + 2)
                        .background(isSelected ? WaypinTheme.fill : WaypinTheme.divider)
                        .clipShape(RoundedRectangle(cornerRadius: WaypinRadius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: WaypinRadius.sm, style: .continuous)
                                .strokeBorder(isSelected ? Color.clear : WaypinTheme.accent.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
