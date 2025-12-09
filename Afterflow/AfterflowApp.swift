import SwiftData
import SwiftUI
import UIKit

@main
struct AfterflowApp: App {
    private static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TherapeuticSession.self
        ])
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

    private let sessionStore: SessionStore = .init(modelContext: Self.sharedModelContainer.mainContext)
    private let isUITesting: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing")

    init() {
        if ProcessInfo.processInfo.arguments.contains("-ui-musiclink-fixtures") {
            self.seedMusicLinkFixtures()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(Self.sharedModelContainer)
                .environment(self.sessionStore)
        }
    }

    private func seedMusicLinkFixtures() {
        guard self.isUITesting else { return }
        let descriptor = FetchDescriptor<TherapeuticSession>()
        let existingSessions = (try? Self.sharedModelContainer.mainContext.fetch(descriptor)) ?? []
        guard existingSessions.isEmpty else { return }
        SeedDataFactory.makeSeedSessions().forEach { try? self.sessionStore.create($0) }
    }
}
