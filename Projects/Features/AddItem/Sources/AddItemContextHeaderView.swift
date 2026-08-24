import DesignSystem
import SwiftUI

struct AddItemContextHeaderView: View {
    let tripName: String?
    let dayText: String?
    let isDayEnabled: Bool
    let onTripTapped: () -> Void
    let onDayTapped: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            row(title: "여행", value: tripName, placeholder: "여행을 선택하세요", isEnabled: true, action: onTripTapped)
            Divider()
            row(title: "날짜", value: dayText, placeholder: "날짜를 선택하세요", isEnabled: isDayEnabled, action: onDayTapped)
        }
        .background(WaypinTheme.surface)
        Divider()
    }

    private func row(title: String, value: String?, placeholder: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(WaypinFont.caption)
                    .foregroundStyle(WaypinTheme.textSecondary)
                    .frame(width: 44, alignment: .leading)
                Text(value ?? placeholder)
                    .font(WaypinFont.bodyEmphasis)
                    .foregroundStyle(value != nil ? WaypinTheme.textPrimary : WaypinTheme.textSecondary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(WaypinTheme.textSecondary)
            }
            .padding(.horizontal, WaypinSpacing.lg)
            .padding(.vertical, WaypinSpacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}
