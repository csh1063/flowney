import SwiftUI

public struct FlowneySegmentedControl<Option: Hashable>: View {
    @Binding private var selection: Option
    private let options: [Option]
    private let label: (Option) -> String

    public init(selection: Binding<Option>, options: [Option], label: @escaping (Option) -> String) {
        self._selection = selection
        self.options = options
        self.label = label
    }

    public var body: some View {
        HStack(spacing: FlowneySpacing.sm) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = option
                    }
                } label: {
                    Text(label(option))
                        .font(FlowneyFont.bodyEmphasis)
                        .foregroundStyle(isSelected ? FlowneyTheme.fillLabel : FlowneyTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, FlowneySpacing.sm + 2)
                        .background(isSelected ? FlowneyTheme.fill : FlowneyTheme.divider)
                        .clipShape(RoundedRectangle(cornerRadius: FlowneyRadius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: FlowneyRadius.sm, style: .continuous)
                                .strokeBorder(isSelected ? Color.clear : FlowneyTheme.accent.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
