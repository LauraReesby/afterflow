@testable import Afterflow
import Foundation
import SwiftData
import Testing
import UserNotifications

@MainActor
struct SessionStoreTests {
    @Test("Create and delete go through store and refresh list") func createAndDelete() async throws {
        let (store, container, _) = try makeStore()
        let session = TherapeuticSession(intention: "Test", moodBefore: 5)

        try store.create(session)
        let sessionsAfterCreate = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        #expect(sessionsAfterCreate.count == 1)

        try store.delete(session)
        let sessionsAfterDelete = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        #expect(sessionsAfterDelete.isEmpty)
    }

    @Test("Draft save, recover, and clear") func draftLifecycle() async throws {
        let (store, _, _) = try makeStore()
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
        let (store, _, mockCenter) = try makeStore()
        let session = TherapeuticSession(intention: "Needs reflection", moodBefore: 5)
        try store.create(session)

        try await store.setReminder(for: session, option: .threeHours)
        #expect(session.reminderDate != nil)
        #expect(mockCenter.addedRequests.count == 1)
    }

    @Test("Updating a session cancels needs-reflection reminders when complete") func updateCancelsReminder(
    ) async throws {
        let (store, _, mockCenter) = try makeStore()
        let session = TherapeuticSession(intention: "Reflection pending", moodBefore: 5)
        try store.create(session)
        session.reminderDate = Date().addingTimeInterval(3600)

        session.reflections = "All done"
        try store.update(session)

        #expect(mockCenter.canceledIdentifiers.count == 2)
    }

    @Test("Set reminder respects .none and clears pending request") func setReminderNoneClears() async throws {
        let (store, _, mockCenter) = try makeStore()
        let session = TherapeuticSession(intention: "Reminder test", moodBefore: 7)
        try store.create(session)

        try await store.setReminder(for: session, option: .threeHours)
        #expect(mockCenter.addedRequests.count == 1)

        try await store.setReminder(for: session, option: .none)
        #expect(mockCenter.canceledIdentifiers.count == 3)
        #expect(session.reminderDate == nil)
    }

    private func makeStore() throws -> (SessionStore, ModelContainer, MockNotificationCenter) {
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
        return (store, container, mockCenter)
    }
}

private final class MockNotificationCenter: NotificationCentering {
    var addedRequests: [UNNotificationRequest] = []
    var canceledIdentifiers: [String] = []
    var authorizationStatus: UNAuthorizationStatus = .authorized

    func authorizationStatus() async -> UNAuthorizationStatus { self.authorizationStatus }

    func add(_ request: UNNotificationRequest) async throws {
        self.addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        self.canceledIdentifiers.append(contentsOf: identifiers)
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool { true }
}
