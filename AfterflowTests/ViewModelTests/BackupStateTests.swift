@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct BackupStateTests {
    private let service = BackupService()

    private func writeBackupFile(of sessions: [TherapeuticSession]) throws -> URL {
        try BackupTestHelpers.writeTemporaryFile(self.service.encode(sessions: sessions))
    }

    // MARK: - Last backup status

    @Test("No backup date until a backup is saved") func noBackupDateInitially() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }

        let state = BackupState(defaults: isolated.defaults)

        #expect(state.lastBackupDate == nil)
        #expect(BackupState.lastBackupText(for: state.lastBackupDate) == "Not backed up yet")
    }

    @Test("Generating the backup file does not record a backup date") func generatingDoesNotRecord() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)

        state.startBackup(sessions: SessionFixtureFactory.makeSessions(count: 3))

        #expect(state.showingBackupExporter == true)
        #expect(state.backupDocument != nil)
        #expect(state.backupFilename.hasPrefix("Afterflow-Backup-"))
        #expect(state.backupError == nil)
        #expect(state.lastBackupDate == nil)
        #expect(isolated.defaults.object(forKey: BackupState.lastBackupDateKey) == nil)
    }

    @Test("Generated document decodes back to every session") func generatedDocumentContainsAllSessions() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)
        let sessions = SessionFixtureFactory.makeSessions(count: 4)

        state.startBackup(sessions: sessions)

        let document = try #require(state.backupDocument)
        let backup = try self.service.decode(document.data)
        #expect(Set(backup.sessions.map(\.id)) == Set(sessions.map(\.id)))
    }

    @Test("A successful save records the date and persists it") func successfulSaveRecordsDate() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)
        let savedAt = Date(timeIntervalSinceReferenceDate: 800_000_000.5)

        state.startBackup(sessions: [])
        state.handleBackupExport(.success(URL(fileURLWithPath: "/tmp/Afterflow-Backup.json")), at: savedAt)

        #expect(state.lastBackupDate == savedAt)
        #expect(state.backupDocument == nil)
        #expect(state.backupError == nil)
        #expect(BackupState(defaults: isolated.defaults).lastBackupDate == savedAt)
    }

    @Test("A failed save is surfaced and not recorded") func failedSaveIsNotRecorded() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)

        state.handleBackupExport(.failure(CocoaError(.fileWriteOutOfSpace)))

        #expect(state.lastBackupDate == nil)
        #expect(state.backupError != nil)
        #expect(isolated.defaults.object(forKey: BackupState.lastBackupDateKey) == nil)
    }

    @Test("Cancelling the save records nothing and shows no error") func cancelledSaveIsSilent() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)

        state.handleBackupExport(.failure(CocoaError(.userCancelled)))

        #expect(state.lastBackupDate == nil)
        #expect(state.backupError == nil)
        #expect(isolated.defaults.object(forKey: BackupState.lastBackupDateKey) == nil)
    }

    @Test("Status text describes how long ago the last backup was") func statusText() {
        let now = Date(timeIntervalSinceReferenceDate: 800_000_000)

        let justNow = BackupState.lastBackupText(for: now.addingTimeInterval(-5), now: now)
        let daysAgo = BackupState.lastBackupText(for: now.addingTimeInterval(-3 * 86400), now: now)

        #expect(justNow == "Last backup: just now")
        #expect(daysAgo.hasPrefix("Last backup: "))
        #expect(daysAgo != justNow)
    }

    // MARK: - Restore

    @Test("Loading a valid backup asks for confirmation") func loadValidBackupShowsConfirmation() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)
        let url = try self.writeBackupFile(of: SessionFixtureFactory.makeSessions(count: 3))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadBackup(from: url)

        #expect(state.pendingBackup?.sessions.count == 3)
        #expect(state.showingRestoreConfirmation == true)
        #expect(state.restoreError == nil)
        #expect(state.restoreConfirmationMessage.hasPrefix("Restore 3 sessions from "))
        #expect(state.restoreConfirmationMessage.contains("updated only if the backup is newer"))
    }

    @Test("Garbage files are rejected, store untouched") func garbageFileLeavesStoreUntouched() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(BackupTestHelpers.makeFullSession())
        let before = try BackupTestHelpers.records(in: container)
        let state = BackupState(defaults: isolated.defaults)
        let url = try BackupTestHelpers.writeTemporaryFile(Data("definitely not a backup".utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadBackup(from: url)
        state.confirmRestore(into: store)

        #expect(state.restoreError == BackupError.invalidFile.errorDescription)
        #expect(state.pendingBackup == nil)
        #expect(state.showingRestoreConfirmation == false)
        #expect(state.showingRestoreResult == false)
        #expect(try BackupTestHelpers.records(in: container) == before)
    }

    @Test("Newer-version backups are rejected, store untouched") func newerVersionLeavesStoreUntouched() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(BackupTestHelpers.makeFullSession())
        let before = try BackupTestHelpers.records(in: container)
        let state = BackupState(defaults: isolated.defaults)
        let future = AfterflowBackup(
            formatVersion: AfterflowBackup.currentFormatVersion + 1,
            exportedAt: Date(),
            appVersion: nil,
            sessions: before
        )
        let url = try BackupTestHelpers.writeTemporaryFile(self.service.encode(future))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadBackup(from: url)
        state.confirmRestore(into: store)

        #expect(state.restoreError == BackupError.unsupportedVersion(2).errorDescription)
        #expect(state.pendingBackup == nil)
        #expect(state.showingRestoreResult == false)
        #expect(try BackupTestHelpers.records(in: container) == before)
    }

    @Test("A backup with no sessions is reported, not confirmed") func emptyBackupIsReported() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)
        let url = try self.writeBackupFile(of: [])
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadBackup(from: url)

        #expect(state.restoreError != nil)
        #expect(state.showingRestoreConfirmation == false)
    }

    @Test("A missing file surfaces an error") func missingFileSurfacesError() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).json")

        await state.loadBackup(from: url)

        #expect(state.restoreError != nil)
        #expect(state.pendingBackup == nil)
    }

    @Test("Confirming restores sessions and reports the summary") func confirmRestoreInsertsAndReports() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = BackupState(defaults: isolated.defaults)
        let url = try self.writeBackupFile(of: SessionFixtureFactory.makeSessions(count: 3))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadBackup(from: url)
        state.confirmRestore(into: store)

        #expect(state.restoreSummary == RestoreSummary(inserted: 3, updated: 0, skipped: 0))
        #expect(state.showingRestoreResult == true)
        #expect(state.pendingBackup == nil)
        #expect(state.restoreError == nil)
        #expect(state.restoreResultMessage == "3 added, 0 updated, 0 already up to date.")
        #expect(try BackupTestHelpers.sessionCount(in: container) == 3)

        await state.loadBackup(from: url)
        state.confirmRestore(into: store)

        #expect(state.restoreSummary == RestoreSummary(inserted: 0, updated: 0, skipped: 3))
        #expect(try BackupTestHelpers.sessionCount(in: container) == 3)
    }

    @Test("Cancelling a restore discards the loaded backup") func cancelRestoreClearsPending() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = BackupState(defaults: isolated.defaults)
        let url = try self.writeBackupFile(of: SessionFixtureFactory.makeSessions(count: 2))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadBackup(from: url)
        state.cancelRestore()
        state.confirmRestore(into: store)

        #expect(state.pendingBackup == nil)
        #expect(state.restoreSummary == nil)
        #expect(try BackupTestHelpers.sessionCount(in: container) == 0)
    }

    @Test("A failed file pick surfaces an error") func failedPickSurfacesError() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = BackupState(defaults: isolated.defaults)

        state.handleRestorePick(.failure(CocoaError(.fileReadNoPermission)))

        #expect(state.restoreError != nil)
    }
}
