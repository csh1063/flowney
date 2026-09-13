import SwiftUI

public struct FlowneyTripLoadEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let onTripListRequested: () -> Void

    public init(
        icon: String,
        title: String = "불러온 여행이 없어요",
        description: String = "하단에 버튼을 눌러 여행을 먼저 불러와주세요.",
        onTripListRequested: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.onTripListRequested = onTripListRequested
    }

    public var body: some View {
        VStack(spacing: FlowneySpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .frame(width: 44, height: 44)
                .foregroundStyle(FlowneyTheme.textSecondary)
            VStack(spacing: FlowneySpacing.xs) {
                Text(title)
                    .font(FlowneyFont.sectionHeader)
                    .foregroundStyle(FlowneyTheme.textPrimary)
                Text(description)
                    .font(FlowneyFont.body)
                    .foregroundStyle(FlowneyTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                onTripListRequested()
            } label: {
                Label("여행 불러오기", systemImage: "airplane")
            }
            .buttonStyle(.flowneyPrimary)
            .padding(.horizontal, FlowneySpacing.xxl)
            .padding(.vertical, FlowneySpacing.md)
        }
        .padding(FlowneySpacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .offset(y: -20)
        .background(FlowneyTheme.background)
    }
}
