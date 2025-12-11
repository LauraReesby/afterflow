import SwiftData
import SwiftUI
import UIKit
import UserNotifications

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {
    // swiftlint:disable:next implicitly_unwrapped_optional
    static var shared: AppDelegate!

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
        AppDelegate.shared = self
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let disableNotifications = ProcessInfo.processInfo.arguments.contains("-disable-notifications")

        if !disableNotifications {
            UNUserNotificationCenter.current().delegate = self.notificationHandler
        }

        return true
    }
}

@main
struct AfterflowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    init() {
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
