import Foundation

/// `travel_map.html`의 날씨 표시(날짜탭 아이콘 + 날씨 바)에 쓰이는 하루치 날씨 요약.
/// `historical`이 true면 예보 범위(오늘부터 15일) 밖이라 최근 3년 같은 날짜 평균으로 대체된 값.
public struct DayWeather: Equatable, Sendable {
    public var tmax: Int
    public var tmin: Int
    public var pop: Int
    public var precip: Double
    public var historical: Bool

    public init(tmax: Int, tmin: Int, pop: Int, precip: Double, historical: Bool) {
        self.tmax = tmax
        self.tmin = tmin
        self.pop = pop
        self.precip = precip
        self.historical = historical
    }

    /// `travel_map.html`의 `weatherIcon()`과 동일한 3단계 기준.
    public var icon: String {
        if pop >= 50 || precip >= 2 { return "🌧️" }
        if pop >= 20 { return "⛅" }
        return "☀️"
    }
}
