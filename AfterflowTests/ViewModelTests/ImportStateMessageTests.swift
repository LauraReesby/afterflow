@testable import Afterflow
import Foundation
import Testing

@MainActor
struct ImportStateMessageTests {
    private typealias Support = CSVImportTestSupport

    private static let skipReason = "date not recognised"
    private static let otherTail = "saved as Other with the original name added to the reflections."
    private static let alreadyHereLine = "Sessions already in Afterflow will be skipped."

    private func makeResult(
        sessions: Int = 3,
        skippedLines: [Int] = [],
        defaultedMood: Int = 0,
        unrecognisedTreatments: Int = 0,
        unrecognisedAdministrations: Int = 0
    ) -> CSVImportResult {
        CSVImportResult(
            sessions: SessionFixtureFactory.makeSessions(count: sessions),
            skippedRows: skippedLines.map { CSVImportSkippedRow(line: $0, reason: Self.skipReason) },
            defaultedMoodBeforeCount: defaultedMood,
            unrecognisedTreatmentCount: unrecognisedTreatments,
            unrecognisedAdministrationCount: unrecognisedAdministrations
        )
    }

    private func lines(of result: CSVImportResult) -> [String] {
        ImportState.confirmationMessage(for: result).components(separatedBy: "\n")
    }

    // MARK: - Confirmation message

    @Test("A clean file gets only the question and the duplicate note") func cleanFile() {
        let lines = self.lines(of: self.makeResult(sessions: 3))

        #expect(lines == ["Import 3 sessions from this file?", Self.alreadyHereLine])
    }

    @Test("One session reads in the singular") func singularSession() {
        let lines = self.lines(of: self.makeResult(sessions: 1))

        #expect(lines.first == "Import 1 session from this file?")
    }

    @Test("Skipped rows list their line numbers") func skippedRowNumbers() {
        let lines = self.lines(of: self.makeResult(skippedLines: [4, 9, 12]))

        #expect(lines[1] == "3 rows couldn't be read and will be skipped (rows 4, 9, 12).")
    }

    @Test("A single skipped row reads in the singular") func singleSkippedRow() {
        let lines = self.lines(of: self.makeResult(skippedLines: [4]))

        #expect(lines[1] == "1 row couldn't be read and will be skipped (row 4).")
    }

    @Test("Exactly five skipped rows are all listed") func fiveSkippedRows() {
        let lines = self.lines(of: self.makeResult(skippedLines: [2, 3, 4, 5, 6]))

        #expect(lines[1] == "5 rows couldn't be read and will be skipped (rows 2, 3, 4, 5, 6).")
    }

    @Test("More than five skipped rows are capped with a count of the rest") func skippedRowsCapped() {
        let lines = self.lines(of: self.makeResult(skippedLines: [2, 3, 4, 5, 6, 7, 8, 9]))

        #expect(lines[1] == "8 rows couldn't be read and will be skipped (rows 2, 3, 4, 5, 6 and 3 more).")
    }

    @Test("Six skipped rows leave one more") func sixSkippedRows() {
        let lines = self.lines(of: self.makeResult(skippedLines: [2, 3, 4, 5, 6, 7]))

        #expect(lines[1] == "6 rows couldn't be read and will be skipped (rows 2, 3, 4, 5, 6 and 1 more).")
    }

    @Test("Skip reasons never appear in the message") func reasonsOmitted() {
        let message = ImportState.confirmationMessage(for: self.makeResult(skippedLines: [4]))

        #expect(!message.contains(Self.skipReason))
    }

    @Test("The defaulted-mood line appears only when some moods were defaulted") func defaultedMoodLine() {
        let none = ImportState.confirmationMessage(for: self.makeResult(defaultedMood: 0))
        let one = self.lines(of: self.makeResult(defaultedMood: 1))
        let several = self.lines(of: self.makeResult(defaultedMood: 4))

        #expect(!none.contains("mood before"))
        #expect(one[1] == "1 session had no mood before; it will be set to 5.")
        #expect(several[1] == "4 sessions had no mood before; it will be set to 5.")
    }

    @Test("The unrecognised-treatment line appears only when needed") func unrecognisedTreatmentLine() {
        let none = ImportState.confirmationMessage(for: self.makeResult())
        let one = self.lines(of: self.makeResult(unrecognisedTreatments: 1))
        let several = self.lines(of: self.makeResult(unrecognisedTreatments: 2))

        #expect(!none.contains("recognised"))
        #expect(one[1] == "1 treatment wasn't recognised; it'll be \(Self.otherTail)")
        #expect(several[1] == "2 treatments weren't recognised; they'll be \(Self.otherTail)")
    }

    @Test("Unrecognised administration methods are handled the same way") func unrecognisedAdministrationLine() {
        let one = self.lines(of: self.makeResult(unrecognisedAdministrations: 1))
        let several = self.lines(of: self.makeResult(unrecognisedAdministrations: 3))

        #expect(one[1] == "1 administration method wasn't recognised; it'll be \(Self.otherTail)")
        #expect(several[1] == "3 administration methods weren't recognised; they'll be \(Self.otherTail)")
    }

    @Test("Every applicable line appears, in a stable order") func allLines() {
        let lines = self.lines(of: self.makeResult(
            sessions: 5,
            skippedLines: [3],
            defaultedMood: 2,
            unrecognisedTreatments: 1,
            unrecognisedAdministrations: 1
        ))

        #expect(lines.count == 6)
        #expect(lines[0].hasPrefix("Import 5 sessions"))
        #expect(lines[1].contains("couldn't be read"))
        #expect(lines[2].contains("no mood before"))
        #expect(lines[3].contains("treatment"))
        #expect(lines[4].contains("administration method"))
        #expect(lines[5] == Self.alreadyHereLine)
    }

    @Test("The message built from a real parse reports counts but never cell contents") func realParse() throws {
        let csv = Support.csv(
            header: "Date,Treatment,Route,Intention,Mood Before",
            rows: [
                "2024-12-01 10:00,Psilocybin,Oral,Secret intention A,6",
                "2024-12-02 10:00,Moonbeam,Swirl,Secret intention B,",
                "not a date,Psilocybin,Oral,Secret intention C,5"
            ]
        )
        let result = try Support.service().importDetailed(from: csv)

        let message = ImportState.confirmationMessage(for: result)

        let expected: [String] = [
            "Import 2 sessions from this file?",
            "1 row couldn't be read and will be skipped (row 4).",
            "1 session had no mood before; it will be set to 5.",
            "1 treatment wasn't recognised; it'll be \(Self.otherTail)",
            "1 administration method wasn't recognised; it'll be \(Self.otherTail)",
            Self.alreadyHereLine
        ]
        #expect(message == expected.joined(separator: "\n"))
        #expect(!message.contains("Moonbeam"))
        #expect(!message.contains("Swirl"))
        #expect(!message.contains("Secret"))
    }

    // MARK: - Button title and result message

    @Test("The confirm button counts sessions with correct wording") func buttonTitle() throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)

        state.pendingImportResult = self.makeResult(sessions: 1)
        #expect(state.importButtonTitle == "Import 1 Session")

        state.pendingImportResult = self.makeResult(sessions: 12)
        #expect(state.importButtonTitle == "Import 12 Sessions")
    }

    @Test("The instance message follows the pending result") func instanceMessage() throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        #expect(state.importConfirmationMessage.isEmpty)

        let result = self.makeResult(sessions: 2, skippedLines: [7])
        state.pendingImportResult = result

        #expect(state.importConfirmationMessage == ImportState.confirmationMessage(for: result))
    }

    @Test("The result message reports added and already-present counts") func resultMessage() throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let state = ImportState(sessionStore: store)
        #expect(state.importResultMessage.isEmpty)

        state.importSummary = CSVImportSummary(insertedCount: 1, skippedDuplicateCount: 0)
        #expect(state.importResultMessage == "1 added, 0 already in Afterflow.")

        state.importSummary = CSVImportSummary(insertedCount: 4, skippedDuplicateCount: 2)
        #expect(state.importResultMessage == "4 added, 2 already in Afterflow.")
    }
}
