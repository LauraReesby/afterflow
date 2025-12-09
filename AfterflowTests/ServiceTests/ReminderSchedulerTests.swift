@testable import Afterflow
import Foundation
import Testing
import UserNotifications

@MainActor
struct ReminderSchedulerTests {
    @Test("Scheduler adds request when reminder date in future") func schedulesRequestWhenAuthorized() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .authorized
        let scheduler = ReminderScheduler(notificationCenter: mockCenter)

        let session = TherapeuticSession(intention: "Test", moodBefore: 5)
        let now = Date(timeIntervalSince1970: 0)
        try await scheduler.setReminder(for: session, option: .threeHours, now: now)
        #expect(mockCenter.addedRequests.count == 1)
        #expect(mockCenter.addedRequests.first?.identifier == "reminder_\(session.id.uuidString)")
        #expect(session.reminderDate == now.addingTimeInterval(10800))
    }

    @Test("Scheduler throws when permission denied") func throwsWhenPermissionDenied() async throws {
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .denied
        let scheduler = ReminderScheduler(notificationCenter: mockCenter)

        let session = TherapeuticSession(intention: "Test", moodBefore: 5)
        let now = Date(timeIntervalSince1970: 0)

        await #expect(throws: ReminderScheduler.ReminderError.self) {
            try await scheduler.setReminder(for: session, option: .threeHours, now: now)
        }
        #expect(session.reminderDate == nil)
    }

    @Test("Scheduler cancels request when reminder removed") func cancelReminderRemovesRequest() {
        let mockCenter = MockNotificationCenter()
        let scheduler = ReminderScheduler(notificationCenter: mockCenter)
        let session = TherapeuticSession(intention: "Test")

        scheduler.cancelReminder(for: session)
        #expect(mockCenter.canceledIdentifiers.contains("reminder_\(session.id.uuidString)"))
    }

    private final class MockNotificationCenter: NotificationCentering {
        var addedRequests: [UNNotificationRequest] = []
        var canceledIdentifiers: [String] = []
        var authorizationStatus: UNAuthorizationStatus = .authorized

        func authorizationStatus() async -> UNAuthorizationStatus {
            self.authorizationStatus
        }

        func add(_ request: UNNotificationRequest) async throws {
            self.addedRequests.append(request)
        }

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            self.canceledIdentifiers.append(contentsOf: identifiers)
        }

        func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
            true
        }
    }
}
