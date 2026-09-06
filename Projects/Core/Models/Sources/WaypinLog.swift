import Foundation
import os

public enum WaypinLogCategory: String {
    case app
    case auth
    case tripList
    case tripEdit
    case itinerary
    case route
    case weather
    case addItem
    case budget
    case share
    case network
}

public enum WaypinLog {
    #if DEBUG
    private static let subsystem = "com.baci.waypin"
    private static var loggers: [String: Logger] = [:]
    private static let lock = NSLock()

    private static func logger(for category: WaypinLogCategory) -> Logger {
        lock.lock()
        defer { lock.unlock() }
        if let existing = loggers[category.rawValue] {
            return existing
        }
        let logger = Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category.rawValue] = logger
        return logger
    }
    #endif

    public static func debug(
        _ message: @autoclosure () -> String,
        category: WaypinLogCategory = .app,
        file: String = #fileID,
        line: Int = #line
    ) {
        #if DEBUG
        let resolved = message()
        logger(for: category).debug("[\(file, privacy: .public):\(line, privacy: .public)] \(resolved, privacy: .public)")
        #endif
    }

    public static func info(
        _ message: @autoclosure () -> String,
        category: WaypinLogCategory = .app
    ) {
        #if DEBUG
        let resolved = message()
        logger(for: category).info("\(resolved, privacy: .public)")
        #endif
    }

    public static func warning(
        _ message: @autoclosure () -> String,
        category: WaypinLogCategory = .app
    ) {
        #if DEBUG
        let resolved = message()
        logger(for: category).warning("\(resolved, privacy: .public)")
        #endif
    }

    public static func error(
        _ message: @autoclosure () -> String,
        category: WaypinLogCategory = .app
    ) {
        #if DEBUG
        let resolved = message()
        logger(for: category).error("\(resolved, privacy: .public)")
        #endif
    }
}
