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

        let handler = NotificationHandler(modelContext: container.mainContext)
        do {
            try await handler.processDeepLink(.openSession(session.id))
        } catch {
            XCTFail("Expected openSession to succeed, got \(error)")
        }
    }

    func testValidateSessionThrowsForMissingSession() throws {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let handler = NotificationHandler(modelContext: container.mainContext)

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

    func testDeepLinkActionEquality() {
        let sessionID = UUID()
        let action1 = NotificationHandler.DeepLinkAction.openSession(sessionID)
        let action2 = NotificationHandler.DeepLinkAction.openSession(sessionID)
        let action3 = NotificationHandler.DeepLinkAction.openSession(UUID())

        XCTAssertEqual(action1, action2, "Same session IDs should be equal")
        XCTAssertNotEqual(action1, action3, "Different session IDs should not be equal")
    }
}
