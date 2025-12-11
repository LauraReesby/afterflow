import Combine
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationHandler: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    enum DeepLinkAction: Equatable {
        case openSession(UUID)
        case addReflection(sessionID: UUID, text: String)
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
    private let reflectionQueue: ReflectionQueue

    init(modelContext: ModelContext, skipQueueReplay: Bool = false) {
        self.modelContext = modelContext
        self.reflectionQueue = ReflectionQueue(modelContext: modelContext)
        super.init()

        guard !skipQueueReplay else { return }

        Task {
            await self.reflectionQueue.replayQueuedReflections()
        }
    }

    // MARK: - Notification Routing

    func handleNotificationResponse(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo

        guard let sessionIDString = userInfo["sessionID"] as? String,
              let sessionID = UUID(uuidString: sessionIDString)
        else {
            return
        }

        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            self.pendingDeepLink = .openSession(sessionID)
        case "QUICK_REFLECTION_ACTION":
            if let textResponse = response as? UNTextInputNotificationResponse {
                self.pendingDeepLink = .addReflection(sessionID: sessionID, text: textResponse.userText)
            }
        default:
            break
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

    var confirmations: ReflectionQueue { self.reflectionQueue }

    func processDeepLink(_ action: DeepLinkAction) async throws {
        switch action {
        case let .openSession(sessionID):
            _ = try self.validateSession(sessionID)
        case let .addReflection(sessionID, text):
            try await self.reflectionQueue.addReflection(sessionID: sessionID, text: text)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

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
