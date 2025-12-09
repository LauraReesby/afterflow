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

@MainActor
final class ReminderScheduler: Sendable {
    enum ReminderError: Error, LocalizedError {
        case permissionDenied
        case schedulingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                "Notification permission denied. Enable in Settings to receive reminders."
            case .schedulingFailed(let error):
                "Failed to schedule reminder: \(error.localizedDescription)"
            }
        }
    }

    private let notificationCenter: NotificationCentering

    init(notificationCenter: NotificationCentering = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }

    func setReminder(
        for session: TherapeuticSession,
        option: ReminderOption,
        now: Date = Date()
    ) async throws {
        let identifier = self.identifier(for: session)
        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        switch option {
        case .none:
            session.reminderDate = nil
            return
        case .threeHours, .tomorrow:
            guard let targetDate = option.targetDate(from: now), targetDate > now else {
                session.reminderDate = nil
                return
            }

            await self.requestPermissionIfNeeded()
            let authStatus = await notificationCenter.authorizationStatus()
            guard authStatus == .authorized || authStatus == .provisional else {
                session.reminderDate = nil
                throw ReminderError.permissionDenied
            }

            session.reminderDate = targetDate

            let content = UNMutableNotificationContent()
            content.title = "Needs Reflection"
            content.body = "Tap to add reflections for \(session.displayTitle)."
            content.sound = .default
            content.userInfo = ["sessionID": session.id.uuidString]

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: targetDate.timeIntervalSince(now),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            do {
                try await self.notificationCenter.add(request)
            } catch {
                session.reminderDate = nil
                throw ReminderError.schedulingFailed(error)
            }
        }
    }

    func requestPermissionIfNeeded() async {
        let currentStatus = await notificationCenter.authorizationStatus()
        guard currentStatus == .notDetermined else { return }
        _ = try? await self.notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
    }

    private func identifier(for session: TherapeuticSession) -> String {
        "reminder_\(session.id.uuidString)"
    }

    func cancelReminder(for session: TherapeuticSession) {
        self.notificationCenter.removePendingNotificationRequests(withIdentifiers: [self.identifier(for: session)])
    }
}
