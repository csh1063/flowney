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
        .background(FlowneyTheme.background)
        .navigationTitle("디자인 시스템")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var colorSection: some View {
        Section("색상") {
            swatchRow("accent (Gold)", color: FlowneyTheme.accent)
            swatchRow("fill (Brand Primary)", color: FlowneyTheme.fill)
            swatchRow("primaryContainer", color: FlowneyTheme.primaryContainer)
            swatchRow("brandNavy (고정)", color: FlowneyTheme.brandNavy)
            swatchRow("brandGold (고정)", color: FlowneyTheme.brandGold)
            swatchRow("background", color: FlowneyTheme.background)
            swatchRow("surface", color: FlowneyTheme.surface)
            swatchRow("textPrimary", color: FlowneyTheme.textPrimary)
            swatchRow("textSecondary", color: FlowneyTheme.textSecondary)
            swatchRow("divider", color: FlowneyTheme.divider)
            swatchRow("success", color: FlowneyTheme.success)
            swatchRow("warning", color: FlowneyTheme.warning)
            swatchRow("error", color: FlowneyTheme.error)
        }
        .listRowBackground(FlowneyTheme.surface)
    }

    private func swatchRow(_ label: String, color: Color) -> some View {
        HStack(spacing: FlowneySpacing.md) {
            RoundedRectangle(cornerRadius: FlowneyRadius.sm, style: .continuous)
                .fill(color)
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: FlowneyRadius.sm, style: .continuous)
                        .stroke(FlowneyTheme.divider, lineWidth: 1)
                )
            Text(label)
                .font(FlowneyFont.body)
        }
    }

    private var typographySection: some View {
        Section("타이포그래피") {
            typeRow("screenTitle", font: FlowneyFont.screenTitle)
            typeRow("sectionHeader", font: FlowneyFont.sectionHeader)
            typeRow("body", font: FlowneyFont.body)
            typeRow("bodyEmphasis", font: FlowneyFont.bodyEmphasis)
            typeRow("caption", font: FlowneyFont.caption)
            typeRow("captionEmphasis", font: FlowneyFont.captionEmphasis)
            typeRow("numeric — 1,234,000 ₩", font: FlowneyFont.numeric)
        }
        .listRowBackground(FlowneyTheme.surface)
    }

    private func typeRow(_ label: String, font: Font) -> some View {
        VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
            Text("여행의 모든 순간")
                .font(font)
            Text(label)
                .font(FlowneyFont.caption)
                .foregroundStyle(FlowneyTheme.textSecondary)
        }
        .padding(.vertical, FlowneySpacing.xs)
    }

    private var spacingSection: some View {
        Section("여백 스케일") {
            spacingRow("xs", value: FlowneySpacing.xs)
            spacingRow("sm", value: FlowneySpacing.sm)
            spacingRow("md", value: FlowneySpacing.md)
            spacingRow("lg", value: FlowneySpacing.lg)
            spacingRow("xl", value: FlowneySpacing.xl)
            spacingRow("xxl", value: FlowneySpacing.xxl)
        }
        .listRowBackground(FlowneyTheme.surface)
    }

    private func spacingRow(_ label: String, value: CGFloat) -> some View {
        HStack(spacing: FlowneySpacing.md) {
            Text(label)
                .font(FlowneyFont.caption)
                .frame(width: 32, alignment: .leading)
            RoundedRectangle(cornerRadius: 2)
                .fill(FlowneyTheme.accent)
                .frame(width: value, height: 12)
            Text("\(Int(value))pt")
                .font(FlowneyFont.caption)
                .foregroundStyle(FlowneyTheme.textSecondary)
        }
    }

    private var radiusSection: some View {
        Section("코너 radius 스케일") {
            HStack(spacing: FlowneySpacing.lg) {
                radiusSwatch("sm", value: FlowneyRadius.sm)
                radiusSwatch("md", value: FlowneyRadius.md)
                radiusSwatch("lg", value: FlowneyRadius.lg)
                radiusSwatch("pill", value: 20)
            }
            .padding(.vertical, FlowneySpacing.sm)
        }
        .listRowBackground(FlowneyTheme.surface)
    }

    private func radiusSwatch(_ label: String, value: CGFloat) -> some View {
        VStack(spacing: FlowneySpacing.xs) {
            RoundedRectangle(cornerRadius: value, style: .continuous)
                .fill(FlowneyTheme.accent)
                .frame(width: 48, height: 48)
            Text(label)
                .font(FlowneyFont.caption)
                .foregroundStyle(FlowneyTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var cardSection: some View {
        Section("카드 (.flowneyCard())") {
            VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
                Text("여행 이름")
                    .font(FlowneyFont.bodyEmphasis)
                Text("2026.09.19 - 2026.10.03")
                    .font(FlowneyFont.caption)
                    .foregroundStyle(FlowneyTheme.textSecondary)
            }
            .flowneyCard()
            .listRowInsets(EdgeInsets())
        }
        .listRowBackground(Color.clear)
    }

    private var componentSection: some View {
        Section("컴포넌트") {
            Button("PrimaryButtonStyle") {}
                .buttonStyle(.flowneyPrimary)
                .listRowInsets(EdgeInsets())
                .padding(FlowneySpacing.md)

            HStack(spacing: FlowneySpacing.sm) {
                ForEach(PaymentStatus.allCases, id: \.rawValue) { status in
                    StatusPill(text: status.displayName, color: status.pillColor)
                }
            }
            .padding(.vertical, FlowneySpacing.xs)
        }
        .listRowBackground(FlowneyTheme.surface)
    }
}

#Preview {
    NavigationStack {
        DesignSystemCatalogView()
    }
}
