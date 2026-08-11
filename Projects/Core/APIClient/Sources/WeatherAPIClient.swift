import ComposableArchitecture
import Foundation
import Models

public enum WeatherAPIError: Error, Equatable {
    case requestFailed
    case noData
}

/// Open-Meteo를 직접 호출한다(무료 공개 API라 인증/서버 프록시 불필요).
/// `travel_map.html`의 `fetchWeatherRange`를 이식: 오늘부터 15일 이내면 예보(forecast) API,
/// 그 밖이면 최근 3년(2022~2024) 같은 날짜의 평균(archive API)을 쓴다. 같은 위치(도시)에 머무는
/// 날짜들은 하루하루 따로 부르지 않고 시작~끝 날짜를 한 번의 range 요청으로 묶어서 부른다 —
/// Open-Meteo는 `start_date`/`end_date`로 여러 날짜를 한 응답에 배열로 돌려준다.
@DependencyClient
public struct WeatherAPIClient: Sendable {
    /// `dates`는 같은 좌표(도시)에 머무는 연속된 날짜들. 결과는 "yyyy-MM-dd" 문자열을 키로 하는
    /// 딕셔너리로 돌아온다.
    public var fetchWeatherRange: @Sendable (_ lat: Double, _ lng: Double, _ dates: [Date]) async throws -> [String: DayWeather]
}

extension WeatherAPIClient: DependencyKey {
    public static let liveValue: WeatherAPIClient = {
        WeatherAPIClient(
            fetchWeatherRange: { lat, lng, dates in
                let sorted = dates.sorted()
                guard !sorted.isEmpty else { return [:] }

                let today = Calendar.current.startOfDay(for: .now)
                let forecastDates = sorted.filter { date in
                    let diff = Calendar.current.dateComponents([.day], from: today, to: Calendar.current.startOfDay(for: date)).day ?? 0
                    return (0 ... 15).contains(diff)
                }
                let historicalDates = sorted.filter { date in !forecastDates.contains(date) }

                var result: [String: DayWeather] = [:]
                if !forecastDates.isEmpty, let forecastResult = try? await Self.fetchForecastRange(lat: lat, lng: lng, dates: forecastDates) {
                    result.merge(forecastResult) { _, new in new }
                }
                if !historicalDates.isEmpty, let historicalResult = try? await Self.fetchHistoricalAverageRange(lat: lat, lng: lng, dates: historicalDates) {
                    result.merge(historicalResult) { _, new in new }
                }
                return result
            }
        )
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func fetchForecastRange(lat: Double, lng: Double, dates: [Date]) async throws -> [String: DayWeather] {
        guard let first = dates.first, let last = dates.last else { return [:] }
        guard let url = URL(
            string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lng)"
                + "&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum"
                + "&timezone=auto&start_date=\(dateFormatter.string(from: first))&end_date=\(dateFormatter.string(from: last))"
        ) else {
            throw WeatherAPIError.requestFailed
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode) else {
            throw WeatherAPIError.requestFailed
        }

        let decoded = try JSONDecoder().decode(RangeResponse.self, from: data)
        var result: [String: DayWeather] = [:]
        for (index, dateString) in decoded.daily.time.enumerated() {
            guard
                let tmax = decoded.daily.temperature_2m_max[safe: index].flatMap({ $0 }), tmax.isFinite,
                let tmin = decoded.daily.temperature_2m_min[safe: index].flatMap({ $0 }), tmin.isFinite
            else { continue }
            let pop = decoded.daily.precipitation_probability_max?[safe: index].flatMap { $0 } ?? 0
            let precip = decoded.daily.precipitation_sum[safe: index].flatMap { $0 } ?? 0
            result[dateString] = DayWeather(tmax: Int(tmax.rounded()), tmin: Int(tmin.rounded()), pop: Int(pop.rounded()), precip: precip, historical: false)
        }
        return result
    }

    private static func fetchHistoricalAverageRange(lat: Double, lng: Double, dates: [Date]) async throws -> [String: DayWeather] {
        guard let first = dates.first, let last = dates.last else { return [:] }
        let calendar = Calendar(identifier: .gregorian)
        let dayCount = calendar.dateComponents([.day], from: first, to: last).day ?? 0
        let years = [2022, 2023, 2024]

        let perYearResponses: [RangeResponse] = await withTaskGroup(of: RangeResponse?.self) { group in
            for year in years {
                group.addTask {
                    guard
                        let startInYear = Self.remapped(date: first, toYear: year, calendar: calendar),
                        let endInYear = calendar.date(byAdding: .day, value: dayCount, to: startInYear)
                    else { return nil }
                    guard let url = URL(
                        string: "https://archive-api.open-meteo.com/v1/archive?latitude=\(lat)&longitude=\(lng)"
                            + "&start_date=\(dateFormatter.string(from: startInYear))&end_date=\(dateFormatter.string(from: endInYear))"
                            + "&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto"
                    ) else { return nil }
                    guard let (data, response) = try? await URLSession.shared.data(from: url),
                          let httpResponse = response as? HTTPURLResponse, (200 ..< 300).contains(httpResponse.statusCode)
                    else { return nil }
                    return try? JSONDecoder().decode(RangeResponse.self, from: data)
                }
            }
            var results: [RangeResponse] = []
            for await result in group {
                if let result { results.append(result) }
            }
            return results
        }

        guard !perYearResponses.isEmpty else { throw WeatherAPIError.noData }

        var result: [String: DayWeather] = [:]
        for (offset, date) in dates.sorted().enumerated() {
            var tmaxes: [Double] = []
            var tmins: [Double] = []
            var precs: [Double] = []
            for response in perYearResponses {
                guard
                    let tmax = response.daily.temperature_2m_max[safe: offset].flatMap({ $0 }), tmax.isFinite,
                    let tmin = response.daily.temperature_2m_min[safe: offset].flatMap({ $0 }), tmin.isFinite
                else { continue }
                tmaxes.append(tmax)
                tmins.append(tmin)
                if let prec = response.daily.precipitation_sum[safe: offset].flatMap({ $0 }), prec.isFinite {
                    precs.append(prec)
                }
            }
            guard !tmaxes.isEmpty, !tmins.isEmpty else { continue }
            let avgMax = tmaxes.reduce(0, +) / Double(tmaxes.count)
            let avgMin = tmins.reduce(0, +) / Double(tmins.count)
            let avgPrecip = precs.isEmpty ? 0 : precs.reduce(0, +) / Double(precs.count)
            result[dateFormatter.string(from: date)] = DayWeather(
                tmax: Int(avgMax.rounded()),
                tmin: Int(avgMin.rounded()),
                pop: avgPrecip > 0.5 ? 50 : 0,
                precip: (avgPrecip * 10).rounded() / 10,
                historical: true
            )
        }
        return result
    }

    /// 월/일은 유지하고 연도만 `year`로 바꾼다. 2/29처럼 그 해에 없는 날짜면 nil.
    private static func remapped(date: Date, toYear year: Int, calendar: Calendar) -> Date? {
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = year
        return calendar.date(from: components)
    }
}

private struct RangeResponse: Decodable {
    struct Daily: Decodable {
        let time: [String]
        let temperature_2m_max: [Double?]
        let temperature_2m_min: [Double?]
        let precipitation_probability_max: [Double?]?
        let precipitation_sum: [Double?]
    }
    let daily: Daily
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension DependencyValues {
    public var weatherAPIClient: WeatherAPIClient {
        get { self[WeatherAPIClient.self] }
        set { self[WeatherAPIClient.self] = newValue }
    }
}
