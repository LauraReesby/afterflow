import SwiftData
import SwiftUI
import UIKit
import UserNotifications

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {
    lazy var sharedModelContainer: ModelContainer = {
        let schema = Schema([TherapeuticSession.self])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-ui-testing")
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isUITesting)

        if isUITesting, let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    lazy var sessionStore: SessionStore = .init(
        modelContext: self.sharedModelContainer.mainContext,
        owningContainer: self.sharedModelContainer
    )

    lazy var notificationHandler: NotificationHandler = .init(modelContext: self.sharedModelContainer.mainContext)

    override init() {
        super.init()
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let disableNotifications = ProcessInfo.processInfo.arguments.contains("-disable-notifications")

        if !disableNotifications {
            UNUserNotificationCenter.current().delegate = self.notificationHandler
        }

        self.migrateSentinelMoodAfterIfNeeded()

        return true
    }

    /// One-time disambiguation for data written before `moodAfter` became optional:
    /// the old schema defaulted it to 5, so 5-with-no-reflections meant "not
    /// recorded". Applies that reading once, then the sentinel never matters again.
    /// (A legacy genuine after-mood of exactly 5 with no reflection text is
    /// indistinguishable from the default and is reset — unrecoverable by design.)
    private func migrateSentinelMoodAfterIfNeeded() {
        let migrationKey = "afterflow.migration.moodAfterSentinelCleared"
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }

        let context = self.sharedModelContainer.mainContext
        do {
            let sessions = try context.fetch(FetchDescriptor<TherapeuticSession>())
            for session in sessions where session.moodAfter == 5
                && session.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                session.moodAfter = nil
            }
            if context.hasChanges {
                try context.save()
            }
            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            // Leave the flag unset so the cleanup retries on next launch.
        }
    }
}

@main
struct AfterflowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    init() {
        FontRegistrar.registerBundledFonts()
        if ProcessInfo.processInfo.arguments.contains("-ui-musiclink-fixtures") {
            let delegate = self.appDelegate
            DispatchQueue.main.async {
                let descriptor = FetchDescriptor<TherapeuticSession>()
                let existingSessions = (try? delegate.sharedModelContainer.mainContext.fetch(descriptor)) ?? []
                guard existingSessions.isEmpty else { return }
                SeedDataFactory.makeSeedSessions().forEach { try? delegate.sessionStore.create($0) }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(self.appDelegate.sharedModelContainer)
                .environment(self.appDelegate.sessionStore)
                .environmentObject(self.appDelegate.notificationHandler)
        }
    }
}
