import DesignSystem
import Models
import SwiftUI
import UIKit

struct CountryColorPickerSheet: View {
    let countryCode: String
    let onConfirm: (Color) -> Void
    let onReset: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hue: Double
    @State private var saturation: Double
    @State private var brightness: Double

    private static let palette: [String] = [
        "#E53935", "#FB8C00", "#FFB300", "#C0CA33", "#43A047",
        "#00897B", "#00ACC1", "#039BE5", "#3949AB", "#8E24AA",
        "#D81B60", "#6D4C41", "#757575", "#263238", "#1A237E",
    ]

    init(countryCode: String, initialColorHex: String, onConfirm: @escaping (Color) -> Void, onReset: @escaping () -> Void) {
        self.countryCode = countryCode
        self.onConfirm = onConfirm
        self.onReset = onReset
        let hsb = Self.hsbComponents(of: Color(hex: initialColorHex))
        _hue = State(initialValue: hsb.h)
        _saturation = State(initialValue: hsb.s)
        _brightness = State(initialValue: hsb.b)
    }

    private var selectedColor: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: FlowneySpacing.lg) {
                    previewBanner

                    sectionBlock("팔레트") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: FlowneySpacing.md) {
                            ForEach(Self.palette, id: \.self) { hex in
                                paletteSwatch(hex)
                            }
                        }
                    }

                    sectionBlock("직접 선택") {
                        VStack(spacing: FlowneySpacing.md) {
                            sliderRow(title: "색상", value: $hue)
                            sliderRow(title: "채도", value: $saturation)
                            sliderRow(title: "밝기", value: $brightness)
                        }
                    }

                    Button("기본값으로") {
                        onReset()
                        dismiss()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(FlowneySpacing.lg)
            }
            .background(FlowneyTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("확인") {
                        onConfirm(selectedColor)
                        dismiss()
                    }
                }
            }
        }
    }

    private var previewBanner: some View {
        RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous)
            .fill(selectedColor)
            .frame(height: 88)
            .overlay(
                Text("\(CountryCatalog.flagEmoji(for: countryCode)) \(CountryCatalog.option(for: countryCode)?.name ?? countryCode)")
                    .font(FlowneyFont.bodyEmphasis)
                    .foregroundStyle(Self.contrastingTextColor(for: selectedColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: FlowneyRadius.lg, style: .continuous)
                    .stroke(FlowneyTheme.divider, lineWidth: 1)
            )
    }

    private func paletteSwatch(_ hex: String) -> some View {
        let color = Color(hex: hex)
        let swatchHSB = Self.hsbComponents(of: color)
        let isSelected = abs(hue - swatchHSB.h) < 0.01
            && abs(saturation - swatchHSB.s) < 0.01
            && abs(brightness - swatchHSB.b) < 0.01
        return Circle()
            .fill(color)
            .frame(width: 36, height: 36)
            .overlay(
                Circle().stroke(FlowneyTheme.accent, lineWidth: isSelected ? 3 : 0)
            )
            .onTapGesture {
                let hsb = Self.hsbComponents(of: color)
                hue = hsb.h
                saturation = hsb.s
                brightness = hsb.b
            }
    }

    private func sliderRow(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: FlowneySpacing.xs) {
            Text(title)
                .font(FlowneyFont.caption)
                .foregroundStyle(FlowneyTheme.textSecondary)
            Slider(value: value, in: 0...1)
        }
    }

    private func sectionBlock<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: FlowneySpacing.sm) {
            Text(title)
                .font(FlowneyFont.sectionHeader)
                .foregroundStyle(FlowneyTheme.textSecondary)
            content()
        }
        .flowneyCard()
    }

    private static func hsbComponents(of color: Color) -> (h: Double, s: Double, b: Double) {
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &br, alpha: &a)
        return (Double(h), Double(s), Double(br))
    }

    private static func contrastingTextColor(for color: Color) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.6 ? .black : .white
    }
}
