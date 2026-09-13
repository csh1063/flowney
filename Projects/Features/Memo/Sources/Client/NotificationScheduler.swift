import ComposableArchitecture
import Foundation
import UserNotifications

@DependencyClient
public struct NotificationScheduler: Sendable {
    public var requestAuthorization: @Sendable () async -> Bool = { false }
    public var scheduleReminder: @Sendable (_ id: UUID, _ title: String, _ date: Date) async -> Void
    public var cancelReminder: @Sendable (_ id: UUID) async -> Void
}

extension NotificationScheduler: DependencyKey {
    public static let liveValue: NotificationScheduler = {
        let center = UNUserNotificationCenter.current()
        return NotificationScheduler(
            requestAuthorization: {
                (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            },
            scheduleReminder: { id, title, date in
                guard date > .now else { return }
                let content = UNMutableNotificationContent()
                content.title = "메모 알림"
                content.body = title
                content.sound = .default

                let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: id.uuidString, content: content, trigger: trigger)
                await withCheckedContinuation { continuation in
                    center.add(request) { _ in continuation.resume() }
                }
            },
            cancelReminder: { id in
                center.removePendingNotificationRequests(withIdentifiers: [id.uuidString])
            }
        )
    }()
}

extension DependencyValues {
    public var notificationScheduler: NotificationScheduler {
        get { self[NotificationScheduler.self] }
        set { self[NotificationScheduler.self] = newValue }
    }
}
