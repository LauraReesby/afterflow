import Foundation
import UIKit
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
final class ReminderScheduler {
    enum ReminderError: Error, LocalizedError {
        case permissionDenied
        case schedulingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                "Notification permission denied. Enable in Settings to receive reminders."
            case let .schedulingFailed(error):
                "Failed to schedule reminder: \(error.localizedDescription)"
            }
        }
    }

    private let notificationCenter: NotificationCentering

    init(notificationCenter: NotificationCentering = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
        Task {
            await self.registerNotificationCategories()
        }
    }

    private func registerNotificationCategories() async {
        guard let realCenter = notificationCenter as? UNUserNotificationCenter else {
            return
        }

        let reflectionAction = UNTextInputNotificationAction(
            identifier: "QUICK_REFLECTION_ACTION",
            title: "Add Reflection",
            options: [.authenticationRequired],
            textInputButtonTitle: "Save",
            textInputPlaceholder: "Share your thoughts"
        )

        let reminderCategory = UNNotificationCategory(
            identifier: "THERAPEUTIC_SESSION_REMINDER",
            actions: [reflectionAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        realCenter.setNotificationCategories([reminderCategory])
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
            content.title = "Time to Reflect"
            content.body = "Add thoughts about your recent session."
            content.sound = .default
            content.categoryIdentifier = "THERAPEUTIC_SESSION_REMINDER"
            content.userInfo = ["sessionID": session.id.uuidString]

            content.accessibilityLabel = "Reflection reminder"
            content.accessibilityHint = "Double-tap to open session, or use Add Reflection to quickly save thoughts"

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

    // Schedules an immediate test notification for debugging purposes.
    // The notification will fire 5 seconds after calling this method.
    //
    // - Parameter session: The session to associate with the test notification
    // - Returns: The scheduled notification date
    func scheduleImmediateTestNotification(for session: TherapeuticSession) async throws -> Date {
        await self.requestPermissionIfNeeded()
        let authStatus = await notificationCenter.authorizationStatus()
        guard authStatus == .authorized || authStatus == .provisional else {
            throw ReminderError.permissionDenied
        }

        let scheduledDate = Date().addingTimeInterval(5)
        let identifier = "test_\(session.id.uuidString)_\(UUID().uuidString)"

        let content = UNMutableNotificationContent()
        content.title = "🧪 Test Notification"
        content.body = "Tap to open session or use 'Add Reflection' to test quick actions."
        content.sound = .default
        content.categoryIdentifier = "THERAPEUTIC_SESSION_REMINDER"
        content.userInfo = ["sessionID": session.id.uuidString]
        content.accessibilityLabel = "Test reflection reminder"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await self.notificationCenter.add(request)
            return scheduledDate
        } catch {
            throw ReminderError.schedulingFailed(error)
        }
    }
}
