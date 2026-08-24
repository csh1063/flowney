import Models
import SwiftUI

public struct DesignSystemCatalogView: View {
    public init() {}

    public var body: some View {
        List {
            colorSection
            typographySection
            spacingSection
            radiusSection
            cardSection
            componentSection
        }
        .scrollContentBackground(.hidden)
        .background(WaypinTheme.background)
        .navigationTitle("디자인 시스템")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var colorSection: some View {
        Section("색상") {
            swatchRow("accent (라이트=네이비/다크=골드)", color: WaypinTheme.accent)
            swatchRow("brandNavy (고정)", color: WaypinTheme.brandNavy)
            swatchRow("brandGold (고정)", color: WaypinTheme.brandGold)
            swatchRow("background", color: WaypinTheme.background)
            swatchRow("surface", color: WaypinTheme.surface)
            swatchRow("textPrimary", color: WaypinTheme.textPrimary)
            swatchRow("textSecondary", color: WaypinTheme.textSecondary)
            swatchRow("divider", color: WaypinTheme.divider)
            swatchRow("success", color: WaypinTheme.success)
            swatchRow("warning", color: WaypinTheme.warning)
            swatchRow("error", color: WaypinTheme.error)
        }
        .listRowBackground(WaypinTheme.surface)
    }

    private func swatchRow(_ label: String, color: Color) -> some View {
        HStack(spacing: WaypinSpacing.md) {
            RoundedRectangle(cornerRadius: WaypinRadius.sm, style: .continuous)
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: WaypinRadius.sm, style: .continuous)
                        .stroke(WaypinTheme.divider, lineWidth: 1)
                )
            Text(label)
                .font(WaypinFont.body)
        }
    }

    private var typographySection: some View {
        Section("타이포그래피") {
            typeRow("screenTitle", font: WaypinFont.screenTitle)
            typeRow("sectionHeader", font: WaypinFont.sectionHeader)
            typeRow("body", font: WaypinFont.body)
            typeRow("bodyEmphasis", font: WaypinFont.bodyEmphasis)
            typeRow("caption", font: WaypinFont.caption)
            typeRow("captionEmphasis", font: WaypinFont.captionEmphasis)
            typeRow("numeric — ₩1,234,000", font: WaypinFont.numeric)
        }
        .listRowBackground(WaypinTheme.surface)
    }

    private func typeRow(_ label: String, font: Font) -> some View {
        VStack(alignment: .leading, spacing: WaypinSpacing.xs) {
            Text("여행의 모든 순간")
                .font(font)
            Text(label)
                .font(WaypinFont.caption)
                .foregroundStyle(WaypinTheme.textSecondary)
        }
        .padding(.vertical, WaypinSpacing.xs)
    }

    private var spacingSection: some View {
        Section("여백 스케일") {
            spacingRow("xs", value: WaypinSpacing.xs)
            spacingRow("sm", value: WaypinSpacing.sm)
            spacingRow("md", value: WaypinSpacing.md)
            spacingRow("lg", value: WaypinSpacing.lg)
            spacingRow("xl", value: WaypinSpacing.xl)
            spacingRow("xxl", value: WaypinSpacing.xxl)
        }
        .listRowBackground(WaypinTheme.surface)
    }

    private func spacingRow(_ label: String, value: CGFloat) -> some View {
        HStack(spacing: WaypinSpacing.md) {
            Text(label)
                .font(WaypinFont.caption)
                .frame(width: 32, alignment: .leading)
            RoundedRectangle(cornerRadius: 2)
                .fill(WaypinTheme.accent)
                .frame(width: value, height: 12)
            Text("\(Int(value))pt")
                .font(WaypinFont.caption)
                .foregroundStyle(WaypinTheme.textSecondary)
        }
    }

    private var radiusSection: some View {
        Section("코너 radius 스케일") {
            HStack(spacing: WaypinSpacing.lg) {
                radiusSwatch("sm", value: WaypinRadius.sm)
                radiusSwatch("md", value: WaypinRadius.md)
                radiusSwatch("lg", value: WaypinRadius.lg)
                radiusSwatch("pill", value: 20)
            }
            .padding(.vertical, WaypinSpacing.sm)
        }
        .listRowBackground(WaypinTheme.surface)
    }

    private func radiusSwatch(_ label: String, value: CGFloat) -> some View {
        VStack(spacing: WaypinSpacing.xs) {
            RoundedRectangle(cornerRadius: value, style: .continuous)
                .fill(WaypinTheme.accent)
                .frame(width: 48, height: 48)
            Text(label)
                .font(WaypinFont.caption)
                .foregroundStyle(WaypinTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var cardSection: some View {
        Section("카드 (.waypinCard())") {
            VStack(alignment: .leading, spacing: WaypinSpacing.xs) {
                Text("여행 이름")
                    .font(WaypinFont.bodyEmphasis)
                Text("2026.09.19 - 2026.10.03")
                    .font(WaypinFont.caption)
                    .foregroundStyle(WaypinTheme.textSecondary)
            }
            .waypinCard()
            .listRowInsets(EdgeInsets())
        }
        .listRowBackground(Color.clear)
    }

    private var componentSection: some View {
        Section("컴포넌트") {
            Button("PrimaryButtonStyle") {}
                .buttonStyle(.waypinPrimary)
                .listRowInsets(EdgeInsets())
                .padding(WaypinSpacing.md)

            HStack(spacing: WaypinSpacing.sm) {
                ForEach(PaymentStatus.allCases, id: \.rawValue) { status in
                    StatusPill(text: status.displayName, color: status.pillColor)
                }
            }
            .padding(.vertical, WaypinSpacing.xs)
        }
        .listRowBackground(WaypinTheme.surface)
    }
}

#Preview {
    NavigationStack {
        DesignSystemCatalogView()
    }
}
