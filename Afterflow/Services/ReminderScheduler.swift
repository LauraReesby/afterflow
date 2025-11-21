import Foundation
import UserNotifications

protocol NotificationCentering {
    func authorizationStatus() async -> UNAuthorizationStatus
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
}

extension UNUserNotificationCenter: NotificationCentering {
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await self.notificationSettings()
        return settings.authorizationStatus
    }
}

final class ReminderScheduler {
    private let notificationCenter: NotificationCentering

    init(notificationCenter: NotificationCentering = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }

    func scheduleReminder(for session: TherapeuticSession) async throws {
        guard let reminderDate = session.reminderDate,
              reminderDate > Date()
        else { return }

        let authStatus = await notificationCenter.authorizationStatus()
        guard authStatus == .authorized || authStatus == .provisional else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Needs Reflection"
        content.body = "Tap to add reflections for \(session.displayTitle)."
        content.sound = .default
        content.userInfo = ["sessionID": session.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: reminderDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest(
            identifier: "reminder_\(session.id.uuidString)",
            content: content,
            trigger: trigger
        )
        try await self.notificationCenter.add(request)
    }

    func cancelReminder(for session: TherapeuticSession) {
        self.notificationCenter
            .removePendingNotificationRequests(withIdentifiers: ["reminder_\(session.id.uuidString)"])
    }

    func requestPermissionIfNeeded() async {
        let currentStatus = await notificationCenter.authorizationStatus()
        guard currentStatus == .notDetermined else { return }
        _ = try? await self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }
}
