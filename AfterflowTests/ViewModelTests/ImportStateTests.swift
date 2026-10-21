@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct ImportStateTests {
    private typealias Support = CSVImportTestSupport

    private static let header = Support.exportHeader

    /// Dates are written in the unambiguous `yyyy-MM-dd HH:mm` form, which needs no quoting and no locale.
    private static let firstRow = "2024-12-10 14:30,Psilocybin,Oral,Intention 1,5,8,Reflection 1,"
    private static let secondRow = "2024-12-11 15:00,LSD,Oral,Intention 2,4,9,Reflection 2,"

    private func csv(_ rows: String...) -> String {
        Support.csv(header: Self.header, rows: rows)
    }

    /// Writes `csv` to a temporary file and loads it through the same entry point the file picker uses.
    private func load(_ csv: String, into state: ImportState) async throws {
        let url = TestHelpers.makeTemporaryFileURL(filename: "import-state-\(UUID().uuidString).csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: url) }
        await state.loadFile(from: url)
    }

    // MARK: - Loading

    @Test("A valid CSV becomes a pending result awaiting confirmation") func validCSVIsPending() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        try await self.load(self.csv(Self.firstRow, Self.secondRow), into: state)

        let sessions = try #require(state.pendingImportResult?.sessions)
        #expect(sessions.map(\.intention) == ["Intention 1", "Intention 2"])
        #expect(sessions[0].sessionDate == Support.localDate(2024, 12, 10, 14, 30))
        #expect(state.pendingImportResult?.skippedRows.isEmpty == true)
        #expect(state.showingImportConfirmation == true)
        #expect(state.importError == nil)
    }

    @Test("Quoted cells, emoji, music links and boundary moods survive loading") func cellContents() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let intention = "\"Quotes \"\"here\"\", commas, and 🌈\""
        let row = "2024-12-10 14:30,Psilocybin,Oral,\(intention),1,10,Felt peaceful 🧘‍♀️,"
            + "https://open.spotify.com/playlist/test123"

        try await self.load(self.csv(row), into: state)

        let session = try #require(state.pendingImportResult?.sessions.first)
        #expect(session.intention == "Quotes \"here\", commas, and 🌈")
        #expect(session.reflections == "Felt peaceful 🧘‍♀️")
        #expect(session.musicLinkURL == "https://open.spotify.com/playlist/test123")
        #expect(session.moodBefore == 1)
        #expect(session.moodAfter == 10)
        #expect(state.importError == nil)
    }

    @Test("Unreadable rows are skipped and reported instead of failing the file") func lenientParsing() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let badRow = "Invalid date format,Psilocybin,Oral,Bad,5,8,,"

        try await self.load(self.csv(Self.firstRow, badRow, Self.secondRow), into: state)

        #expect(state.pendingImportResult?.sessions.count == 2)
        #expect(state.pendingImportResult?.skippedRows.map(\.line) == [3])
        #expect(state.showingImportConfirmation == true)
        #expect(state.importError == nil)
    }

    @Test("A file where no row can be read reports an error") func noReadableRows() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        try await self.load(self.csv("Invalid date format,Psilocybin,Oral,Test,5,8,,"), into: state)

        #expect(state.importError == CSVImportService.CSVImportError.noValidRows.errorDescription)
        #expect(state.pendingImportResult == nil)
        #expect(state.showingImportConfirmation == false)
    }

    @Test("A header-only file reports that no sessions were found") func headerOnlyFile() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        try await self.load(Self.header + "\n", into: state)

        #expect(state.importError == "No sessions were found in this file.")
        #expect(state.pendingImportResult == nil)
        #expect(state.showingImportConfirmation == false)
    }

    @Test("A file without a Date column reports an error") func missingDateColumn() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        try await self.load("Invalid,Header,Structure\nData,Data,Data", into: state)

        #expect(state.importError == CSVImportService.CSVImportError.invalidHeader.errorDescription)
        #expect(state.pendingImportResult == nil)
    }

    @Test("An empty file reports an error") func emptyFile() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        try await self.load("", into: state)

        #expect(state.importError == CSVImportService.CSVImportError.emptyFile.errorDescription)
        #expect(state.pendingImportResult == nil)
        #expect(state.showingImportConfirmation == false)
    }

    @Test("An unreadable file reports an error") func fileReadFailure() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let missingURL = URL(fileURLWithPath: "/tmp/nonexistent-file-\(UUID().uuidString).csv")

        state.importFile(from: missingURL)
        try await TestHelpers.waitFor({ state.importError != nil }, timeout: 2.0)

        #expect(state.pendingImportResult == nil)
    }

    @Test("Loading a new file replaces an unconfirmed result") func newFileReplacesPending() async throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        try await self.load(self.csv(Self.firstRow), into: state)
        try await self.load(Self.header + "\n", into: state)

        #expect(state.pendingImportResult == nil)
        #expect(state.importError == "No sessions were found in this file.")
    }

    // MARK: - Confirming and cancelling

    @Test("Confirming imports the sessions and reports the summary") func confirmImportsSessions() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        try await self.load(self.csv(Self.firstRow, Self.secondRow), into: state)

        state.confirmImport()

        #expect(state.importSummary == CSVImportSummary(insertedCount: 2, skippedDuplicateCount: 0))
        #expect(state.showingImportResult == true)
        #expect(state.importResultMessage == "2 added, 0 already in Afterflow.")
        #expect(state.pendingImportResult == nil)
        #expect(state.showingImportConfirmation == false)
        #expect(state.importError == nil)
        let stored = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        #expect(Set(stored.map(\.intention)) == ["Intention 1", "Intention 2"])
    }

    @Test("Importing the same CSV twice adds nothing the second time") func secondImportAddsNothing() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        let content = self.csv(Self.firstRow, Self.secondRow)

        try await self.load(content, into: state)
        state.confirmImport()
        try await self.load(content, into: state)
        state.confirmImport()

        #expect(state.importSummary == CSVImportSummary(insertedCount: 0, skippedDuplicateCount: 2))
        #expect(state.importResultMessage == "0 added, 2 already in Afterflow.")
        #expect(try BackupTestHelpers.sessionCount(in: container) == 2)
    }

    @Test("Imports of different files accumulate") func importsInSequence() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        try await self.load(self.csv(Self.firstRow), into: state)
        state.confirmImport()
        try await self.load(self.csv(Self.secondRow), into: state)
        state.confirmImport()

        #expect(state.importSummary == CSVImportSummary(insertedCount: 1, skippedDuplicateCount: 0))
        #expect(try BackupTestHelpers.sessionCount(in: container) == 2)
    }

    @Test("Cancelling clears the pending result and stores nothing") func cancelClearsPending() async throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        try await self.load(self.csv(Self.firstRow), into: state)

        state.cancelImport()

        #expect(state.pendingImportResult == nil)
        #expect(state.showingImportConfirmation == false)
        #expect(state.showingImportResult == false)
        #expect(try BackupTestHelpers.sessionCount(in: container) == 0)
    }

    @Test("Confirming with nothing pending does nothing") func confirmWithoutPending() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        state.confirmImport()

        #expect(state.importSummary == nil)
        #expect(state.showingImportResult == false)
        #expect(state.importError == nil)
        #expect(try BackupTestHelpers.sessionCount(in: container) == 0)
    }
}
