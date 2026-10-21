@testable import Afterflow
import Foundation
import SwiftData
import Testing

/// `CSVExportService` prefixes `'` to text starting with `=`, `+`, `-` or `@`; import must remove exactly that.
@MainActor
@Suite("CSV injection guard round trip")
struct CSVInjectionGuardRoundTripTests {
    private typealias Support = CSVImportTestSupport

    private static let guardedStarts = ["-", "=", "+", "@"]

    private func makeGuardedSessions() -> [TherapeuticSession] {
        Self.guardedStarts.enumerated().map { index, start in
            TherapeuticSession(
                sessionDate: Support.localDate(2024, 12, 1 + index, 9, 15),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "\(start)intention \(index)",
                moodBefore: 4,
                moodAfter: 7,
                reflections: "\(start)reflection \(index)"
            )
        }
    }

    private func exportedResult(of sessions: [TherapeuticSession]) throws -> CSVImportResult {
        let url = try CSVExportService().export(sessions: sessions)
        defer { try? FileManager.default.removeItem(at: url) }
        return try Support.service().importDetailed(from: url)
    }

    @Test("Intention and reflections starting with a formula character restore exactly") func restoresExactly() throws {
        let originals = self.makeGuardedSessions()

        let result = try self.exportedResult(of: originals)

        #expect(result.skippedRows.isEmpty)
        #expect(result.sessions.map(\.intention) == originals.map(\.intention))
        #expect(result.sessions.map(\.reflections) == originals.map(\.reflections))
        #expect(result.sessions.allSatisfy { !$0.intention.hasPrefix("'") && !$0.reflections.hasPrefix("'") })
    }

    @Test("The export really does guard these fields") func exportAddsGuard() throws {
        let url = try CSVExportService().export(sessions: self.makeGuardedSessions())
        defer { try? FileManager.default.removeItem(at: url) }
        let text = try String(contentsOf: url, encoding: .utf8)

        #expect(text.contains("'-intention 0"))
        #expect(text.contains("'=reflection 1"))
    }

    @Test("An apostrophe the user typed is kept") func ordinaryApostropheKept() throws {
        let session = TherapeuticSession(
            sessionDate: Support.localDate(2024, 12, 1, 9, 15),
            intention: "'tis the season",
            moodAfter: nil,
            reflections: "'Quoted' start"
        )

        let result = try self.exportedResult(of: [session])

        #expect(result.sessions.first?.intention == "'tis the season")
        #expect(result.sessions.first?.reflections == "'Quoted' start")
    }

    @Test("Re-importing the live store's export skips every session as a duplicate") func reimportIsDuplicate() throws {
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let originals = self.makeGuardedSessions()
        for session in originals {
            try store.create(session)
        }
        let stored = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())

        let result = try self.exportedResult(of: stored)
        let summary = try store.importSessions(result.sessions)

        #expect(result.sessions.count == originals.count)
        #expect(summary == CSVImportSummary(insertedCount: 0, skippedDuplicateCount: originals.count))
        #expect(try BackupTestHelpers.sessionCount(in: container) == originals.count)
    }

    @Test("A guard on treatment or administration text is removed before noting it") func labelGuard() throws {
        let csv = Support.csv(
            header: "Date,Treatment,Route,Intention",
            rows: [
                "2024-12-01 10:00,'-mystery,'=odd,First",
                "2024-12-02 10:00,Psilocybin,Oral,Second"
            ]
        )

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.sessions.count == 2)
        #expect(result.sessions[0].treatmentType == .other)
        #expect(result.sessions[0].administration == .other)
        #expect(result.sessions[0].reflections == "Imported treatment: -mystery\n\nImported administration: =odd")
        #expect(result.unrecognisedTreatmentCount == 1)
        #expect(result.unrecognisedAdministrationCount == 1)
        #expect(result.sessions[1].treatmentType == .psilocybin)
    }
}
