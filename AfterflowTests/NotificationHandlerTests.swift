@testable import Afterflow
import SwiftData
import UserNotifications
import XCTest

@MainActor
final class NotificationHandlerTests: XCTestCase {
    func testProcessDeepLinkOpenSessionSucceeds() async throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Navigate to me",
            moodBefore: 5,
            moodAfter: 5
        )
        try store.create(session)

        let handler = NotificationHandler(modelContext: container.mainContext, skipQueueReplay: true)
        do {
            try await handler.processDeepLink(.openSession(session.id))
        } catch {
            XCTFail("Expected openSession to succeed, got \(error)")
        }
    }

    func testProcessDeepLinkAddReflectionPersistsText() async throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Add reflection",
            moodBefore: 5,
            moodAfter: 6
        )
        try store.create(session)

        let handler = NotificationHandler(modelContext: container.mainContext, skipQueueReplay: true)
        try await handler.processDeepLink(.addReflection(sessionID: session.id, text: "Noted from notification"))

        let refreshed = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>()).first
        XCTAssertEqual(refreshed?.id, session.id)
        XCTAssertTrue(refreshed?.reflections.contains("Noted from notification") ?? false)
    }

    // MARK: - Session Validation Tests

    func testValidateSessionThrowsForMissingSession() throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let handler = NotificationHandler(modelContext: container.mainContext, skipQueueReplay: true)

        let nonExistentID = UUID()

        do {
            _ = try handler.validateSession(nonExistentID)
            XCTFail("Should throw sessionNotFound error")
        } catch let error as NotificationHandler.NotificationError {
            switch error {
            case let .sessionNotFound(id):
                XCTAssertEqual(id, nonExistentID, "Error should contain the missing session ID")
            default:
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Accessor Tests

    func testConfirmationsAccessorReturnsReflectionQueue() throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let handler = NotificationHandler(modelContext: container.mainContext, skipQueueReplay: true)

        XCTAssertNotNil(handler.confirmations, "Should provide access to reflection queue")
    }

    // MARK: - Error Description Tests

    func testNotificationErrorDescriptions() {
        let sessionID = UUID()
        let sessionNotFoundError = NotificationHandler.NotificationError.sessionNotFound(sessionID)
        XCTAssertTrue(
            sessionNotFoundError.errorDescription?.contains(sessionID.uuidString) ?? false,
            "Error description should include session ID"
        )

        let invalidPayloadError = NotificationHandler.NotificationError.invalidPayload
        XCTAssertNotNil(invalidPayloadError.errorDescription, "Should have error description")

        let routingFailedError = NotificationHandler.NotificationError.routingFailed("test reason")
        XCTAssertTrue(
            routingFailedError.errorDescription?.contains("test reason") ?? false,
            "Error description should include failure reason"
        )
    }

    // MARK: - Deep Link Action Tests

    func testDeepLinkActionEquality() {
        let sessionID = UUID()
        let action1 = NotificationHandler.DeepLinkAction.openSession(sessionID)
        let action2 = NotificationHandler.DeepLinkAction.openSession(sessionID)
        let action3 = NotificationHandler.DeepLinkAction.openSession(UUID())

        XCTAssertEqual(action1, action2, "Same session IDs should be equal")
        XCTAssertNotEqual(action1, action3, "Different session IDs should not be equal")

        let reflectionAction1 = NotificationHandler.DeepLinkAction.addReflection(sessionID: sessionID, text: "test")
        let reflectionAction2 = NotificationHandler.DeepLinkAction.addReflection(sessionID: sessionID, text: "test")
        let reflectionAction3 = NotificationHandler.DeepLinkAction.addReflection(
            sessionID: sessionID,
            text: "different"
        )

        XCTAssertEqual(reflectionAction1, reflectionAction2, "Same reflection details should be equal")
        XCTAssertNotEqual(reflectionAction1, reflectionAction3, "Different reflection text should not be equal")
        XCTAssertNotEqual(action1, reflectionAction1, "Different action types should not be equal")
    }

    func testProcessDeepLinkAddReflectionQueuesWhenSessionMissing() async throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let handler = NotificationHandler(modelContext: container.mainContext, skipQueueReplay: true)

        // Adding reflection to missing session should queue it instead of throwing
        do {
            try await handler.processDeepLink(.addReflection(sessionID: UUID(), text: "test"))
            // Should succeed by queuing the reflection
        } catch {
            XCTFail("Should queue reflection instead of throwing: \(error)")
        }

        // Verify it was queued
        XCTAssertGreaterThan(handler.confirmations.queuedCount, 0, "Should have queued the reflection")
    }
}
