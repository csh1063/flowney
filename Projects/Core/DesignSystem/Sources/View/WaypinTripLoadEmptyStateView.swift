import SwiftUI

public struct WaypinTripLoadEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let onTripListRequested: () -> Void

    public init(
        icon: String,
        title: String = "불러온 여행이 없어요",
        description: String = "지도 탭에서 여행을 먼저 불러와주세요.",
        onTripListRequested: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.onTripListRequested = onTripListRequested
    }

    public var body: some View {
        VStack(spacing: WaypinSpacing.lg) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(WaypinTheme.textSecondary)
            VStack(spacing: WaypinSpacing.xs) {
                Text(title)
                    .font(WaypinFont.sectionHeader)
                    .foregroundStyle(WaypinTheme.textPrimary)
                Text(description)
                    .font(WaypinFont.body)
                    .foregroundStyle(WaypinTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                onTripListRequested()
            } label: {
                Label("여행 불러오기", systemImage: "airplane")
            }
            .buttonStyle(.waypinPrimary)
            .padding(.horizontal, WaypinSpacing.xxl)
            .padding(.vertical, WaypinSpacing.md)
            Spacer()
        }
        .padding(WaypinSpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(WaypinTheme.background)
    }
}
