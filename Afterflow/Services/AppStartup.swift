import Foundation
import Observation
import SwiftData
import UserNotifications

/// Decides at launch whether the app has a usable store. Services that touch the store
/// (`SessionStore`, `NotificationHandler`, the sentinel migration) exist only after it opens,
/// whether that happens at launch or after a recovery action.
@MainActor
@Observable
final class AppStartup {
    struct Services {
        let container: ModelContainer
        let sessionStore: SessionStore
        let notificationHandler: NotificationHandler
    }

    enum State {
        case ready(Services)
        case needsRecovery(Error)
    }

    private(set) var state: State
    let persistence: PersistenceController

    /// `nil` means the launch configuration. It's resolved here rather than as a default argument because
    /// default arguments are evaluated outside the main actor, and `forLaunch()` is main-actor isolated.
    init(persistence: PersistenceController? = nil) {
        let persistence = persistence ?? .forLaunch()
        self.persistence = persistence
        self.state = Self.openStore(with: persistence)
    }

    var services: Services? {
        guard case let .ready(services) = self.state else { return nil }
        return services
    }

    /// Re-attempts opening the existing store; moves to `.ready` on success.
    func retry() {
        self.state = Self.openStore(with: self.persistence)
    }

    /// Moves the existing store files aside (kept on device, never deleted) and opens a new
    /// empty store. Throws only if the files could not be moved; an open failure is reflected
    /// in `state` like any other.
    func startFresh() throws {
        try self.persistence.quarantineStoreFiles()
        self.state = Self.openStore(with: self.persistence)
    }

    /// `-ui-musiclink-fixtures`: seeds sample sessions into an empty store.
    func seedMusicLinkFixturesIfNeeded() {
        guard let services = self.services else { return }
        let descriptor = FetchDescriptor<TherapeuticSession>()
        let existingSessions = (try? services.container.mainContext.fetch(descriptor)) ?? []
        guard existingSessions.isEmpty else { return }
        SeedDataFactory.makeSeedSessions().forEach { try? services.sessionStore.create($0) }
    }

    private static func openStore(with persistence: PersistenceController) -> State {
        switch persistence.open() {
        case let .success(container):
            persistence.removeExportCopy()
            return .ready(self.makeServices(for: container))
        case let .failure(error):
            return .needsRecovery(error)
        }
    }

    private static func makeServices(for container: ModelContainer) -> Services {
        let context = container.mainContext
        let services = Services(
            container: container,
            sessionStore: SessionStore(modelContext: context, owningContainer: container),
            notificationHandler: NotificationHandler(modelContext: context)
        )

        if !ProcessInfo.processInfo.arguments.contains("-disable-notifications") {
            UNUserNotificationCenter.current().delegate = services.notificationHandler
        }
        MoodAfterSentinelMigration.runIfNeeded(context: context)

        return services
    }
}
