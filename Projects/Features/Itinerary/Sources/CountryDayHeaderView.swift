import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

struct CountryDayHeaderView: View {
    let days: [TripDay]
    let countries: IdentifiedArrayOf<TripCountry>
    let dayColumnWidth: CGFloat
    let dayCountryCodes: [TripDay.ID: [String]]

    private struct Segment: Identifiable {
        let id = UUID()
        let countryCode: String?
        var width: CGFloat
    }

    var body: some View {
        HStack(spacing: 1) {
            ForEach(segments) { segment in
                let color = segment.countryCode.map(countryColor) ?? Color.gray.opacity(0.35)
                HStack(spacing: 3) {
                    if let code = segment.countryCode {
                        Text(CountryCatalog.flagEmoji(for: code))
                            .font(.system(size: 11))
                    }
                    Text(segment.countryCode.flatMap { CountryCatalog.option(for: $0)?.name } ?? segment.countryCode ?? "")
                        .font(WaypinFont.captionEmphasis)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(.white)
                .frame(width: segment.width, height: 22)
                .background(
                    LinearGradient(colors: [color.opacity(0.92), color], startPoint: .top, endPoint: .bottom)
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 2, x: 0, y: 1)
    }

    private var units: [(countryCode: String?, width: CGFloat)] {
        var result: [(countryCode: String?, width: CGFloat)] = []
        var lastCode: String?
        for day in days {
            let codes = dayCountryCodes[day.id] ?? []
            if codes.isEmpty {
                result.append((countryCode: lastCode, width: dayColumnWidth))
            } else {
                let width = dayColumnWidth / CGFloat(codes.count)
                for code in codes {
                    result.append((countryCode: code, width: width))
                    lastCode = code
                }
            }
        }
        return result
    }

    private var segments: [Segment] {
        var result: [Segment] = []
        for unit in units {
            if let lastIndex = result.indices.last, result[lastIndex].countryCode == unit.countryCode {
                result[lastIndex].width += unit.width
            } else {
                result.append(Segment(countryCode: unit.countryCode, width: unit.width))
            }
        }
        return result
    }

    private func countryColor(_ code: String) -> Color {
        if let hex = countries.first(where: { $0.countryCode == code })?.color {
            return Color(hex: hex)
        }
        if let hex = CountryCatalog.option(for: code)?.defaultColorHex {
            return Color(hex: hex)
        }
        return .gray
    }
}
