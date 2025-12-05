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
        if self.sessionStore.sessions.contains(where: { $0.intention == "Tier1 Music Session" }) {
            return
        }

        let now = Date()
        var seedSessions: [TherapeuticSession] = []

        let tier1 = TherapeuticSession(
            sessionDate: now,
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Tier1 Music Session",
            moodBefore: 5,
            moodAfter: 6,
            reflections: "Seeded tier1 metadata",
            reminderDate: nil
        )
        tier1.musicLinkURL = "https://open.spotify.com/playlist/37i9dQZF1DX4WYpdgoIcn6"
        tier1.musicLinkWebURL = "https://open.spotify.com/playlist/37i9dQZF1DX4WYpdgoIcn6"
        tier1.musicLinkTitle = "Lo-Fi Focus"
        tier1.musicLinkAuthorName = "Lo-Fi Collective"
        tier1.musicLinkArtworkURL = nil
        tier1.musicLinkDurationSeconds = 3600
        tier1.musicLinkProvider = .spotify

        let linkOnly = TherapeuticSession(
            sessionDate: now.addingTimeInterval(-3600),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Link Only Music Session",
            moodBefore: 5,
            moodAfter: 6,
            reflections: "Seeded link-only metadata",
            reminderDate: nil
        )
        linkOnly.musicLinkURL = "https://music.apple.com/us/playlist/calm/pl.u-123"
        linkOnly.musicLinkWebURL = "https://music.apple.com/us/playlist/calm/pl.u-123"
        linkOnly.musicLinkTitle = "Calm"
        linkOnly.musicLinkAuthorName = "Apple Music"
        linkOnly.musicLinkProvider = .appleMusic

        seedSessions.append(tier1)
        seedSessions.append(linkOnly)

        // Additional sessions (match preview style: daily offsets, more rows)
        for i in 1 ... 18 {
            let session = TherapeuticSession(
                sessionDate: now.addingTimeInterval(TimeInterval(-i * 86400)),
                treatmentType: PsychedelicTreatmentType.allCases[i % PsychedelicTreatmentType.allCases.count],
                administration: .oral,
                intention: "Seeded Session \(i)",
                moodBefore: (i % 10) + 1,
                moodAfter: ((i + 2) % 10) + 1,
                reflections: "Reflection note \(i)",
                reminderDate: nil
            )
            if i % 3 == 0 {
                session.reminderDate = now.addingTimeInterval(TimeInterval(i * 600))
            }
            seedSessions.append(session)
        }

        seedSessions.forEach { try? self.sessionStore.create($0) }
    }
}
