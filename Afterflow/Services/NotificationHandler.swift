import Combine
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationHandler: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    enum DeepLinkAction: Equatable {
        case openSession(UUID)
    }

    enum NotificationError: Error, LocalizedError {
        case sessionNotFound(UUID)
        case invalidPayload
        case routingFailed(String)

        var errorDescription: String? {
            switch self {
            case let .sessionNotFound(id):
                "Session not found: \(id)"
            case .invalidPayload:
                "Invalid notification payload"
            case let .routingFailed(reason):
                "Navigation failed: \(reason)"
            }
        }
    }

    @Published var pendingDeepLink: DeepLinkAction?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init()
    }

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        guard let sessionIDString = userInfo["sessionID"] as? String,
              let sessionID = UUID(uuidString: sessionIDString)
        else {
            return
        }

        // Tapping the notification is the only supported interaction; it opens
        // the session (routing into the reflection screen when one is still due).
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            self.pendingDeepLink = .openSession(sessionID)
        }
    }

    func validateSession(_ sessionID: UUID) throws -> TherapeuticSession {
        let descriptor = FetchDescriptor<TherapeuticSession>(predicate: #Predicate { $0.id == sessionID })
        guard let session = try modelContext.fetch(descriptor).first else {
            throw NotificationError.sessionNotFound(sessionID)
        }
        return session
    }

    func clearPendingDeepLink() {
        self.pendingDeepLink = nil
    }

    func processDeepLink(_ action: DeepLinkAction) async throws {
        switch action {
        case let .openSession(sessionID):
            _ = try self.validateSession(sessionID)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        self.handleNotificationResponse(response)
        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
