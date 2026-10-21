@testable import Afterflow
import Foundation
import SwiftData

/// A throwaway `UserDefaults` suite; call `cleanUp()` (usually via `defer`) when done.
struct IsolatedDefaults {
    let defaults: UserDefaults
    let suiteName: String

    init() throws {
        let suiteName = "afterflow.tests.backup.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else { throw TestError.setupFailed }
        self.suiteName = suiteName
        self.defaults = defaults
    }

    func cleanUp() {
        self.defaults.removePersistentDomain(forName: self.suiteName)
    }
}

enum BackupTestHelpers {
    /// Dates carry fractional seconds so tests catch any precision loss.
    @MainActor static func makeFullSession(index: Int = 0) -> TherapeuticSession {
        let base = 780_000_000.0 + Double(index) * 1000
        let session = TherapeuticSession(
            sessionDate: Date(timeIntervalSinceReferenceDate: base + 0.123_456),
            treatmentType: .lsd,
            administration: .intramuscular,
            intention: "Intention \(index) with \"quotes\", emoji 🌈 and\nnewlines",
            moodBefore: 4,
            moodAfter: 8,
            reflections: "Reflection \(index) / with slash",
            reminderDate: Date(timeIntervalSinceReferenceDate: base + 3600.987_654)
        )
        session.createdAt = Date(timeIntervalSinceReferenceDate: base + 0.000_001)
        session.updatedAt = Date(timeIntervalSinceReferenceDate: base + 60.314_159_265)
        session.musicLinkURL = "https://open.spotify.com/playlist/abc\(index)"
        session.musicLinkWebURL = "https://open.spotify.com/playlist/web\(index)"
        session.musicLinkTitle = "Playlist \(index)"
        session.musicLinkAuthorName = "Author \(index)"
        session.musicLinkArtworkURL = "https://example.com/art\(index).jpg"
        session.musicLinkDurationSeconds = 3600 + index
        session.musicLinkProviderRawValue = MusicLinkProvider.spotify.rawValue
        return session
    }

    /// Every optional left `nil`, so absent keys must round-trip as `nil`.
    @MainActor static func makeMinimalSession() -> TherapeuticSession {
        let session = TherapeuticSession(
            sessionDate: Date(timeIntervalSinceReferenceDate: 790_000_000.5),
            intention: "Minimal",
            moodAfter: nil
        )
        session.createdAt = Date(timeIntervalSinceReferenceDate: 790_000_001.25)
        session.updatedAt = Date(timeIntervalSinceReferenceDate: 790_000_002.75)
        return session
    }

    @MainActor static func records(in container: ModelContainer) throws -> [SessionBackupRecord] {
        let sessions = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        return sessions.map { SessionBackupRecord(session: $0) }.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    @MainActor static func sortedRecords(of sessions: [TherapeuticSession]) -> [SessionBackupRecord] {
        sessions.map { SessionBackupRecord(session: $0) }.sorted { $0.id.uuidString < $1.id.uuidString }
    }

    @MainActor static func sessionCount(in container: ModelContainer) throws -> Int {
        try container.mainContext.fetchCount(FetchDescriptor<TherapeuticSession>())
    }

    static func writeTemporaryFile(_ data: Data, name: String = "backup-test") throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString).json")
        try data.write(to: url)
        return url
    }
}
