@testable import Afterflow
import Foundation
import SwiftData
import Testing
import UserNotifications

@MainActor
struct SessionStoreTests {
    @Test("Create and delete go through store and refresh list")
    func createAndDelete() async throws {
        let (store, _) = try makeStore()
        let session = TherapeuticSession(intention: "Test", moodBefore: 5)

        try store.create(session)
        #expect(store.sessions.count == 1)

        try store.delete(session)
        #expect(store.sessions.isEmpty)
    }

    @Test("Draft save, recover, and clear")
    func draftLifecycle() async throws {
        let (store, _) = try makeStore()
        let draft = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Draft intention",
            moodBefore: 6,
            moodAfter: 5
        )

        store.saveDraft(draft)
        let recovered = store.recoverDraft()
        #expect(recovered?.intention == "Draft intention")

        store.clearDraft()
        #expect(store.recoverDraft() == nil)
    }

    @Test("Setting reminder applies date and schedules notification")
    func setReminderSchedulesNotification() async throws {
        let (store, mockCenter) = try makeStore()
        let session = TherapeuticSession(intention: "Needs reflection", moodBefore: 5)
        try store.create(session)

        try await store.setReminder(for: session, option: .threeHours)
        #expect(session.reminderDate != nil)
        #expect(mockCenter.addedRequests.count == 1)
    }

    // MARK: - Helpers

    private func makeStore() throws -> (SessionStore, MockNotificationCenter) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let mockCenter = MockNotificationCenter()
        mockCenter.authorizationStatus = .authorized
        let scheduler = ReminderScheduler(notificationCenter: mockCenter)
        let defaults = UserDefaults(suiteName: "SessionStoreTests-\(UUID().uuidString)")!
        let store = SessionStore(
            modelContext: container.mainContext,
            owningContainer: container,
            reminderScheduler: scheduler,
            draftDefaults: defaults
        )
        return (store, mockCenter)
    }
}

private final class MockNotificationCenter: NotificationCentering {
    var addedRequests: [UNNotificationRequest] = []
    var canceledIdentifiers: [String] = []
    var authorizationStatus: UNAuthorizationStatus = .authorized

    func authorizationStatus() async -> UNAuthorizationStatus { authorizationStatus }

    func add(_ request: UNNotificationRequest) async throws {
        self.addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        self.canceledIdentifiers.append(contentsOf: identifiers)
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
}
