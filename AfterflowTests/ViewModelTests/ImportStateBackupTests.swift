@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct ImportStateBackupTests {
    private let service = BackupService()

    private func writeBackupFile(of sessions: [TherapeuticSession]) throws -> URL {
        try BackupTestHelpers.writeTemporaryFile(self.service.encode(sessions: sessions))
    }

    // MARK: - Routing

    @Test("A .json backup goes to restore confirmation") func jsonBackupShowsRestoreConfirmation() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let url = try self.writeBackupFile(of: SessionFixtureFactory.makeSessions(count: 3))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)

        #expect(state.pendingBackup?.sessions.count == 3)
        #expect(state.showingRestoreConfirmation == true)
        #expect(state.showingImportConfirmation == false)
        #expect(state.pendingImportResult == nil)
        #expect(state.importError == nil)
        #expect(state.restoreConfirmationMessage.hasPrefix("Restore 3 sessions from a backup made on "))
        #expect(state.restoreConfirmationMessage.hasSuffix(
            "Sessions already here are kept; matching ones are updated only if the backup is newer."
        ))
    }

    @Test("JSON content is recognised without a .json extension") func jsonContentIsSniffed() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let json = try self.service.encode(sessions: SessionFixtureFactory.makeSessions(count: 2))
        let url = TestHelpers.makeTemporaryFileURL(filename: "sniffed-\(UUID().uuidString).txt")
        try (Data("\n \t".utf8) + json).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)

        #expect(state.pendingBackup?.sessions.count == 2)
        #expect(state.showingRestoreConfirmation == true)
        #expect(state.showingImportConfirmation == false)
    }

    @Test("A CSV file still goes through the CSV path") func csvFileStillUsesCSVPath() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let url = try CSVExportService().export(sessions: SessionFixtureFactory.makeSessions(count: 2))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)

        #expect(state.pendingImportResult?.sessions.count == 2)
        #expect(state.showingImportConfirmation == true)
        #expect(state.pendingBackup == nil)
        #expect(state.showingRestoreConfirmation == false)
        #expect(state.importError == nil)
    }

    @Test("Picking a file routes it, and a failed pick surfaces an error") func filePickHandling() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let url = try self.writeBackupFile(of: SessionFixtureFactory.makeSessions(count: 1))
        defer { try? FileManager.default.removeItem(at: url) }

        state.handleFilePick(.success(url))
        try await TestHelpers.waitFor({ state.showingRestoreConfirmation }, timeout: 2.0)
        #expect(state.pendingBackup?.sessions.count == 1)

        state.handleFilePick(.failure(CocoaError(.fileReadNoPermission)))
        #expect(state.importError != nil)
    }

    // MARK: - Restoring

    @Test("Confirming a restore inserts sessions and reports the summary") func confirmInserts() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let url = try self.writeBackupFile(of: SessionFixtureFactory.makeSessions(count: 3))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)
        state.confirmRestore()

        #expect(state.restoreSummary == RestoreSummary(inserted: 3, updated: 0, skipped: 0))
        #expect(state.showingRestoreResult == true)
        #expect(state.restoreResultMessage == "3 added, 0 updated, 0 already up to date.")
        #expect(state.pendingBackup == nil)
        #expect(state.importError == nil)
        #expect(try BackupTestHelpers.sessionCount(in: container) == 3)
    }

    @Test("Importing the same backup twice adds nothing the second time") func secondAddsNothing() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let url = try self.writeBackupFile(of: SessionFixtureFactory.makeSessions(count: 3))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)
        state.confirmRestore()
        await state.loadFile(from: url)
        state.confirmRestore()

        #expect(state.restoreSummary == RestoreSummary(inserted: 0, updated: 0, skipped: 3))
        #expect(state.restoreResultMessage == "0 added, 0 updated, 3 already up to date.")
        #expect(try BackupTestHelpers.sessionCount(in: container) == 3)
    }

    @Test("Cancelling a restore discards the loaded backup") func cancelRestoreDiscardsBackup() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let url = try self.writeBackupFile(of: SessionFixtureFactory.makeSessions(count: 2))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)
        state.cancelRestore()
        state.confirmRestore()

        #expect(state.pendingBackup == nil)
        #expect(state.restoreSummary == nil)
        #expect(state.showingRestoreResult == false)
        #expect(try BackupTestHelpers.sessionCount(in: container) == 0)
    }

    // MARK: - Rejected files

    @Test("A garbage .json file errors, store untouched") func garbageJSONIsRejected() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(BackupTestHelpers.makeFullSession())
        let before = try BackupTestHelpers.records(in: container)
        let state = ImportState(sessionStore: store)
        let url = try BackupTestHelpers.writeTemporaryFile(Data("definitely not a backup".utf8))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)
        state.confirmRestore()

        #expect(state.importError == BackupError.invalidFile.errorDescription)
        #expect(state.pendingBackup == nil)
        #expect(state.showingRestoreConfirmation == false)
        #expect(state.showingRestoreResult == false)
        #expect(state.pendingImportResult == nil)
        #expect(try BackupTestHelpers.records(in: container) == before)
    }

    @Test("A newer-format backup gets the newer-version error") func newerFormatIsRejected() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(BackupTestHelpers.makeFullSession())
        let before = try BackupTestHelpers.records(in: container)
        let state = ImportState(sessionStore: store)
        let future = AfterflowBackup(
            formatVersion: AfterflowBackup.currentFormatVersion + 1,
            exportedAt: Date(),
            appVersion: nil,
            sessions: before
        )
        let url = try BackupTestHelpers.writeTemporaryFile(self.service.encode(future))
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)
        state.confirmRestore()

        let newerVersion = AfterflowBackup.currentFormatVersion + 1
        #expect(state.importError == BackupError.unsupportedVersion(newerVersion).errorDescription)
        #expect(state.importError?.contains("newer version") == true)
        #expect(state.pendingBackup == nil)
        #expect(state.showingRestoreResult == false)
        #expect(try BackupTestHelpers.records(in: container) == before)
    }

    @Test("A backup with no sessions is reported, not confirmed") func emptyBackupIsReported() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let url = try self.writeBackupFile(of: [])
        defer { try? FileManager.default.removeItem(at: url) }

        await state.loadFile(from: url)

        #expect(state.importError != nil)
        #expect(state.showingRestoreConfirmation == false)
        #expect(state.pendingBackup == nil)
    }

    @Test("A missing .json file surfaces an error") func missingJSONFileSurfacesError() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("missing-\(UUID().uuidString).json")

        await state.loadFile(from: url)

        #expect(state.importError != nil)
        #expect(state.pendingBackup == nil)
    }
}
