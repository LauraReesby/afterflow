@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct SessionStoreRestoreTests {
    private let service = BackupService()

    /// Pushes sessions through the real file format so tests cover encode + decode too.
    private func roundTrippedBackup(of sessions: [TherapeuticSession]) throws -> AfterflowBackup {
        try self.service.decode(self.service.encode(sessions: sessions))
    }

    /// A stand-in for the same stored session edited elsewhere (same id, new timestamp).
    private func makeCopy(of session: TherapeuticSession, intention: String, updatedAt: Date) -> TherapeuticSession {
        let copy = BackupTestHelpers.makeFullSession(index: 0)
        copy.id = session.id
        copy.intention = intention
        copy.updatedAt = updatedAt
        return copy
    }

    @Test("Restore into an empty store inserts every session with its id") func restoreIntoEmptyStoreInserts() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let sources = [
            BackupTestHelpers.makeFullSession(index: 0),
            BackupTestHelpers.makeFullSession(index: 1),
            BackupTestHelpers.makeMinimalSession()
        ]

        let summary = try store.restore(from: self.roundTrippedBackup(of: sources))

        #expect(summary == RestoreSummary(inserted: 3, updated: 0, skipped: 0))
        #expect(try BackupTestHelpers.records(in: container) == BackupTestHelpers.sortedRecords(of: sources))
        #expect(container.mainContext.hasChanges == false)
    }

    @Test("Restoring the same backup twice is a no-op the second time") func restoreTwiceIsIdempotent() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let backup = try self.roundTrippedBackup(of: [
            BackupTestHelpers.makeFullSession(index: 0),
            BackupTestHelpers.makeFullSession(index: 1)
        ])

        _ = try store.restore(from: backup)
        let before = try BackupTestHelpers.records(in: container)
        let second = try store.restore(from: backup)

        #expect(second == RestoreSummary(inserted: 0, updated: 0, skipped: 2))
        #expect(try BackupTestHelpers.sessionCount(in: container) == 2)
        #expect(try BackupTestHelpers.records(in: container) == before)
    }

    @Test("Restoring a backup of the live store skips everything") func restoreOwnBackupSkipsAll() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(BackupTestHelpers.makeFullSession(index: 0))
        try store.create(BackupTestHelpers.makeMinimalSession())
        let live = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())

        let summary = try store.restore(from: self.roundTrippedBackup(of: live))

        #expect(summary == RestoreSummary(inserted: 0, updated: 0, skipped: 2))
    }

    @Test("A newer backup record overwrites the stored session") func newerRecordUpdates() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let existing = BackupTestHelpers.makeFullSession(index: 0)
        try store.create(existing)
        let edited = self.makeCopy(
            of: existing,
            intention: "Edited elsewhere",
            updatedAt: existing.updatedAt.addingTimeInterval(10)
        )
        edited.moodAfter = nil
        edited.musicLinkTitle = nil

        let summary = try store.restore(from: self.roundTrippedBackup(of: [edited]))

        #expect(summary == RestoreSummary(inserted: 0, updated: 1, skipped: 0))
        #expect(try BackupTestHelpers.sessionCount(in: container) == 1)
        #expect(existing.intention == "Edited elsewhere")
        #expect(existing.moodAfter == nil)
        #expect(existing.musicLinkTitle == nil)
        #expect(existing.updatedAt == edited.updatedAt)
        #expect(try BackupTestHelpers.records(in: container) == BackupTestHelpers.sortedRecords(of: [edited]))
    }

    @Test("Older or equal backup records are skipped") func olderOrEqualRecordsAreSkipped() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let existing = BackupTestHelpers.makeFullSession(index: 0)
        try store.create(existing)
        let original = existing.intention
        let olderDate = existing.updatedAt.addingTimeInterval(-10)
        let older = self.makeCopy(of: existing, intention: "Older", updatedAt: olderDate)
        let equal = self.makeCopy(of: existing, intention: "Equal", updatedAt: existing.updatedAt)

        let summary = try store.restore(from: self.roundTrippedBackup(of: [older, equal]))

        #expect(summary == RestoreSummary(inserted: 0, updated: 0, skipped: 2))
        #expect(existing.intention == original)
        #expect(try BackupTestHelpers.sessionCount(in: container) == 1)
    }

    @Test("Mixed backup reports inserted, updated and skipped") func mixedBackupSummary() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let stale = BackupTestHelpers.makeFullSession(index: 0)
        let current = BackupTestHelpers.makeFullSession(index: 1)
        try store.create(stale)
        try store.create(current)
        let newer = BackupTestHelpers.makeFullSession(index: 0)
        newer.id = stale.id
        newer.updatedAt = stale.updatedAt.addingTimeInterval(5)
        let unchanged = BackupTestHelpers.makeFullSession(index: 1)
        unchanged.id = current.id
        let brandNew = BackupTestHelpers.makeMinimalSession()

        let summary = try store.restore(from: self.roundTrippedBackup(of: [newer, unchanged, brandNew]))

        #expect(summary == RestoreSummary(inserted: 1, updated: 1, skipped: 1))
        #expect(try BackupTestHelpers.sessionCount(in: container) == 3)
    }

    @Test("Restore never deletes sessions missing from the backup") func restoreNeverDeletes() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(BackupTestHelpers.makeFullSession(index: 0))
        try store.create(BackupTestHelpers.makeFullSession(index: 1))

        let summary = try store.restore(from: self.service.makeBackup(sessions: []))

        #expect(summary == RestoreSummary())
        #expect(try BackupTestHelpers.sessionCount(in: container) == 2)
    }

    @Test("Duplicate ids inside one backup resolve to the newest record") func duplicateIDsInBackup() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let first = BackupTestHelpers.makeFullSession(index: 0)
        let second = self.makeCopy(of: first, intention: "Newest", updatedAt: first.updatedAt.addingTimeInterval(5))

        let summary = try store.restore(from: self.roundTrippedBackup(of: [first, second]))

        #expect(summary == RestoreSummary(inserted: 1, updated: 1, skipped: 0))
        let sessions = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.intention == "Newest")
    }

    @Test("Unknown enum raw values are restored verbatim") func unknownRawValuesRestored() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let source = BackupTestHelpers.makeFullSession()
        source.treatmentTypeRawValue = "FutureCompound"
        source.administrationRawValue = "Telepathic"

        _ = try store.restore(from: self.roundTrippedBackup(of: [source]))

        let restored = try #require(try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>()).first)
        #expect(restored.treatmentTypeRawValue == "FutureCompound")
        #expect(restored.administrationRawValue == "Telepathic")
    }
}
