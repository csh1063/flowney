import ComposableArchitecture
import DesignSystem
import Models
import SwiftUI

/// 날짜탭 위에 국가 이름을 여러 날짜에 걸친 띠로 표시한다.
///
/// `TripDay.countryCode`(여행 생성 시 한 번 찍히고 그 뒤엔 못 바꾸는 값)는 더 이상 신뢰하지
/// 않는다 — 대신 `ItineraryFeature.dayCountryCodes(_:)`가 그날 등록된 항목들의 좌표를 실제
/// 계산해서 돌려준 "그날이 걸친, 여행에 등록된 나라 코드" 목록을 받는다. 하루가 나라를 N개
/// 걸치면 그 날짜 칸을 N등분해서 각각 칠하고, 걸치는 나라가 없는(아직 항목이 없거나 계산 전인)
/// 날짜는 바로 이전 나라를 그대로 이어서 칠한다(빈 칸이 안 생기도록). 이렇게 만들어진 조각들을
/// 인접한 것끼리(나라가 같으면) 합쳐서 하나의 이어진 띠로 그린다.
struct CountryDayHeaderView: View {
    let days: [TripDay]
    let countries: IdentifiedArrayOf<TripCountry>
    let dayColumnWidth: CGFloat
    /// 날짜 id → 그날이 순서대로 걸친(여행에 등록된) 국가 코드들. 걸친 나라가 없으면 빈 배열.
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
                        .font(.caption2.weight(.semibold))
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

    /// 날짜별로 N등분한 조각들 — 아직 인접 병합은 안 한 원자 단위.
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

    /// 인접한 같은 나라 조각을 하나로 합쳐서 시각적으로 이어진 띠처럼 보이게 한다.
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
