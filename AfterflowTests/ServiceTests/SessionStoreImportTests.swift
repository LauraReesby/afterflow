@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct SessionStoreImportTests {
    private typealias Support = CSVImportTestSupport

    private let baseDate = CSVImportTestSupport.localDate(2024, 12, 1, 10, 30)

    private func makeSession(
        date: Date? = nil,
        treatment: PsychedelicTreatmentType = .psilocybin,
        intention: String = "Grounding"
    ) -> TherapeuticSession {
        TherapeuticSession(
            sessionDate: date ?? self.baseDate,
            treatmentType: treatment,
            administration: .oral,
            intention: intention,
            moodBefore: 5,
            moodAfter: 7
        )
    }

    private func storedSessions(in container: ModelContainer) throws -> [TherapeuticSession] {
        try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
    }

    @Test("Importing into an empty store inserts everything") func insertsAllIntoEmptyStore() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let sessions = [
            self.makeSession(intention: "One"),
            self.makeSession(intention: "Two"),
            self.makeSession(date: self.baseDate.addingTimeInterval(86400), intention: "One")
        ]

        let summary = try store.importSessions(sessions)

        #expect(summary == CSVImportSummary(insertedCount: 3, skippedDuplicateCount: 0))
        #expect(try self.storedSessions(in: container).count == 3)
    }

    @Test("Importing the same set again adds nothing") func reimportAddsNothing() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let first = [self.makeSession(intention: "One"), self.makeSession(intention: "Two")]
        let second = [self.makeSession(intention: "One"), self.makeSession(intention: "Two")]

        try store.importSessions(first)
        let summary = try store.importSessions(second)

        #expect(summary == CSVImportSummary(insertedCount: 0, skippedDuplicateCount: 2))
        #expect(try self.storedSessions(in: container).count == 2)
    }

    @Test("Duplicates within one import are collapsed") func collapsesDuplicatesWithinImport() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let sessions = [self.makeSession(), self.makeSession(), self.makeSession(intention: "Other")]

        let summary = try store.importSessions(sessions)

        #expect(summary == CSVImportSummary(insertedCount: 2, skippedDuplicateCount: 1))
        #expect(try self.storedSessions(in: container).count == 2)
    }

    @Test("Sessions that differ only in seconds are duplicates") func secondsAreIgnored() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(self.makeSession())

        let summary = try store.importSessions([self.makeSession(date: self.baseDate.addingTimeInterval(45))])

        #expect(summary == CSVImportSummary(insertedCount: 0, skippedDuplicateCount: 1))
        #expect(try self.storedSessions(in: container).count == 1)
    }

    @Test("A different minute is not a duplicate") func differentMinute() throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        try store.create(self.makeSession())

        let summary = try store.importSessions([self.makeSession(date: self.baseDate.addingTimeInterval(60))])

        #expect(summary.insertedCount == 1)
    }

    @Test("A different intention is not a duplicate") func differentIntention() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(self.makeSession(intention: "Grounding"))

        let summary = try store.importSessions([self.makeSession(intention: "Release")])

        #expect(summary == CSVImportSummary(insertedCount: 1, skippedDuplicateCount: 0))
        #expect(try self.storedSessions(in: container).count == 2)
    }

    @Test("A different treatment is not a duplicate") func differentTreatment() throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        try store.create(self.makeSession(treatment: .psilocybin))

        let summary = try store.importSessions([self.makeSession(treatment: .lsd)])

        #expect(summary.insertedCount == 1)
    }

    @Test("Surrounding whitespace in the intention is ignored") func intentionWhitespaceTrimmed() throws {
        let (_, store) = try TestHelpers.makeTestEnvironment()
        try store.create(self.makeSession(intention: "Grounding"))

        let summary = try store.importSessions([self.makeSession(intention: "  Grounding \n")])

        #expect(summary == CSVImportSummary(insertedCount: 0, skippedDuplicateCount: 1))
    }

    @Test("Importing nothing is a no-op") func emptyImport() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()

        let summary = try store.importSessions([])

        #expect(summary == CSVImportSummary(insertedCount: 0, skippedDuplicateCount: 0))
        #expect(try self.storedSessions(in: container).isEmpty)
    }

    @Test("Importing an exported CSV twice adds nothing the second time") func exportedCSVReimport() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let original = [
            self.makeSession(intention: "One"),
            self.makeSession(date: self.baseDate.addingTimeInterval(86400), treatment: .lsd, intention: "Two")
        ]
        let url = try CSVExportService().export(sessions: original)
        defer { try? FileManager.default.removeItem(at: url) }
        let service = Support.service()

        let first = try store.importSessions(service.importDetailed(from: url).sessions)
        let second = try store.importSessions(service.importDetailed(from: url).sessions)

        #expect(first == CSVImportSummary(insertedCount: 2, skippedDuplicateCount: 0))
        #expect(second == CSVImportSummary(insertedCount: 0, skippedDuplicateCount: 2))
        #expect(try self.storedSessions(in: container).count == 2)
    }

    @Test("Importing a spreadsheet over matching existing sessions skips them") func spreadsheetOverExisting() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        try store.create(self.makeSession(intention: "Grounding"))
        let csv = Support.csv(
            header: "When;Substance;Goal",
            rows: ["2024-12-01 10:30;Mushrooms;Grounding", "2024-12-02 10:30;Mushrooms;Grounding"]
        )

        let sessions = try Support.service().importDetailed(from: csv).sessions
        let summary = try store.importSessions(sessions)

        #expect(summary == CSVImportSummary(insertedCount: 1, skippedDuplicateCount: 1))
        #expect(try self.storedSessions(in: container).count == 2)
    }
}
