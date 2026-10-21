@testable import Afterflow
import Foundation
import Testing
import UniformTypeIdentifiers

@MainActor
struct ExportStateBackupTests {
    private let savedURL = URL(fileURLWithPath: "/tmp/Afterflow-Backup.json")
    private let savedAt = Date(timeIntervalSinceReferenceDate: 800_000_000)

    private func export(
        _ state: ExportState,
        format: ExportFormat,
        sessions: [TherapeuticSession] = SessionFixtureFactory.makeSessions(count: 3),
        dateRange: ClosedRange<Date>? = nil,
        treatmentType: PsychedelicTreatmentType? = nil
    ) async throws {
        let request = ExportRequest(format: format, dateRange: dateRange, treatmentType: treatmentType)
        state.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !state.isExporting }, timeout: 5.0)
    }

    // MARK: - Producing the backup document

    @Test("Backup export includes every session even when the request has filters")
    func backupIgnoresFilters() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)
        let sessions = SessionFixtureFactory.makeSessions(count: 6)
        let rangeStart = TestHelpers.dateComponents(year: 2000, month: 1, day: 1)
        let rangeEnd = TestHelpers.dateComponents(year: 2000, month: 12, day: 31)

        try await self.export(
            state,
            format: .backup,
            sessions: sessions,
            dateRange: rangeStart ... rangeEnd,
            treatmentType: .mdma
        )

        let document = try #require(state.exportDocument)
        let backup = try BackupService().decode(document.data)
        #expect(backup.sessions.count == sessions.count)
        #expect(Set(backup.sessions.map(\.id)) == Set(sessions.map(\.id)))
        #expect(state.exportError == nil)
    }

    @Test("Backup export is JSON with a dated backup filename") func backupContentTypeAndFilename() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)

        try await self.export(state, format: .backup)

        #expect(state.exportContentType == .json)
        #expect(state.exportDocument?.contentType == .json)
        #expect(state.exportFilename.hasPrefix("Afterflow-Backup-"))
        #expect(state.showingFileExporter == true)
    }

    @Test("Preparing a backup does not record a backup date") func preparingDoesNotRecord() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)

        try await self.export(state, format: .backup)

        #expect(state.lastBackupDate == nil)
        #expect(isolated.defaults.object(forKey: ExportState.lastBackupDateKey) == nil)
    }

    // MARK: - Recording the last backup date

    @Test("A saved backup records the date and persists it") func savedBackupRecordsDate() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)
        try await self.export(state, format: .backup)

        state.handleFileExporterResult(.success(self.savedURL), at: self.savedAt)

        #expect(state.lastBackupDate == self.savedAt)
        #expect(state.exportDocument == nil)
        #expect(state.isExporting == false)
        #expect(state.exportError == nil)
        #expect(ExportState(defaults: isolated.defaults).lastBackupDate == self.savedAt)
    }

    @Test("The date key matches the one recorded by the previous build") func dateKeyIsUnchanged() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        isolated.defaults.set(self.savedAt, forKey: "afterflow.backup.lastBackupDate")

        let state = ExportState(defaults: isolated.defaults)

        #expect(ExportState.lastBackupDateKey == "afterflow.backup.lastBackupDate")
        #expect(state.lastBackupDate == self.savedAt)
    }

    @Test("No backup date until a backup is saved") func noBackupDateInitially() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }

        #expect(ExportState(defaults: isolated.defaults).lastBackupDate == nil)
    }

    @Test("A saved CSV export does not record a backup date") func savedCSVDoesNotRecord() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)
        try await self.export(state, format: .csv)

        state.handleFileExporterResult(.success(self.savedURL), at: self.savedAt)

        #expect(state.lastBackupDate == nil)
        #expect(isolated.defaults.object(forKey: ExportState.lastBackupDateKey) == nil)
    }

    @Test("A saved PDF export does not record a backup date") func savedPDFDoesNotRecord() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)
        try await self.export(state, format: .pdf)

        state.handleFileExporterResult(.success(self.savedURL), at: self.savedAt)

        #expect(state.lastBackupDate == nil)
        #expect(isolated.defaults.object(forKey: ExportState.lastBackupDateKey) == nil)
    }

    @Test("A document that didn't come from an export records nothing") func unrelatedDocumentDoesNotRecord() throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)

        state.handleFileExporterResult(.success(self.savedURL), at: self.savedAt)

        #expect(state.lastBackupDate == nil)
        #expect(isolated.defaults.object(forKey: ExportState.lastBackupDateKey) == nil)
    }

    @Test("Cancelling the save records nothing and shows no error") func cancelledSaveIsSilent() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)
        try await self.export(state, format: .backup)

        state.handleFileExporterResult(.failure(CocoaError(.userCancelled)), at: self.savedAt)

        #expect(state.lastBackupDate == nil)
        #expect(state.exportError == nil)
        #expect(state.exportDocument == nil)
        #expect(isolated.defaults.object(forKey: ExportState.lastBackupDateKey) == nil)
    }

    @Test("A failed save is surfaced and not recorded") func failedSaveIsNotRecorded() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)
        try await self.export(state, format: .backup)

        state.handleFileExporterResult(.failure(CocoaError(.fileWriteOutOfSpace)), at: self.savedAt)

        #expect(state.lastBackupDate == nil)
        #expect(state.exportError != nil)
        #expect(state.exportDocument == nil)
        #expect(isolated.defaults.object(forKey: ExportState.lastBackupDateKey) == nil)
    }

    @Test("One prepared backup is recorded at most once") func backupIsRecordedOnce() async throws {
        let isolated = try IsolatedDefaults()
        defer { isolated.cleanUp() }
        let state = ExportState(defaults: isolated.defaults)
        try await self.export(state, format: .backup)

        state.handleFileExporterResult(.success(self.savedURL), at: self.savedAt)
        state.handleFileExporterResult(.success(self.savedURL), at: self.savedAt.addingTimeInterval(3600))

        #expect(state.lastBackupDate == self.savedAt)
    }
}
