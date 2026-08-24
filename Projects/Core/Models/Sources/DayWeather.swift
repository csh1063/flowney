import Foundation

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

    public var icon: String {
        if pop >= 50 || precip >= 2 { return "🌧️" }
        if pop >= 20 { return "⛅" }
        return "☀️"
    }
}
