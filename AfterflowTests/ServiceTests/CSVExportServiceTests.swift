@testable import Afterflow
import XCTest

@MainActor
final class CSVExportServiceTests: XCTestCase {
    func testExportsExpectedColumnsAndData() async throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Grounding",
            moodBefore: 4,
            moodAfter: 7,
            reflections: "Deep breath",
            reminderDate: nil
        )
        session.musicLinkURL = "https://open.spotify.com/playlist/abc"

        let url = try await service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(
            lines[0],
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL"
        )
        XCTAssertTrue(lines[1].contains("Grounding"))
        XCTAssertTrue(lines[1].contains("Deep breath"))
        XCTAssertTrue(lines[1].contains("https://open.spotify.com/playlist/abc"))
    }

    func testFiltersByDateRange() async throws {
        let service = CSVExportService()
        let inRange = TherapeuticSession(sessionDate: date("2024-12-01T00:00:00Z"))
        let outOfRange = TherapeuticSession(sessionDate: date("2024-10-01T00:00:00Z"))

        let range = self.date("2024-11-01T00:00:00Z") ... self.date("2024-12-31T00:00:00Z")
        let url = try await service.export(sessions: [inRange, outOfRange], dateRange: range)
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        XCTAssertFalse(lines[1].contains("2024-10"))
    }

    func testFiltersByTreatmentType() async throws {
        let service = CSVExportService()
        let match = TherapeuticSession(sessionDate: Date(), treatmentType: .psilocybin)
        let nonMatch = TherapeuticSession(sessionDate: Date(), treatmentType: .ketamine)

        let url = try await service.export(sessions: [match, nonMatch], treatmentType: .psilocybin)
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].contains("Psilocybin"))
        XCTAssertFalse(csv.contains("Ketamine"))
    }

    func testEscapesQuotesCommasNewlines() async throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T00:00:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Hello, \"World\"",
            moodBefore: 1,
            moodAfter: 2,
            reflections: "Line1\nLine2",
            reminderDate: nil
        )

        let url = try await service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(csv.contains("\"Hello, \"\"World\"\"\""))
        XCTAssertTrue(csv.contains("\"Line1\nLine2\""))
    }

    func testGuardsAgainstFormulaInjection() async throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T00:00:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "=HYPERLINK(\"evil\")",
            moodBefore: 1,
            moodAfter: 2,
            reflections: "@bad",
            reminderDate: nil
        )

        let url = try await service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(csv.contains("'=HYPERLINK"))
        XCTAssertTrue(csv.contains("'@bad"))
    }

    func testExportsOneThousandSessions() async throws {
        let service = CSVExportService()
        var sessions: [TherapeuticSession] = []
        for i in 0 ..< 1000 {
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z").addingTimeInterval(TimeInterval(i * 60)),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Intention \(i)",
                moodBefore: 3,
                moodAfter: 5,
                reflections: "Reflections \(i)",
                reminderDate: nil
            )
            sessions.append(session)
        }

        let url = try await service.export(sessions: sessions)
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 1001) // header + 1000 rows
    }

    // MARK: - Helpers

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601) ?? Date()
    }
}
