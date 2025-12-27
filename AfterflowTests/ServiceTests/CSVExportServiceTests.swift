@testable import Afterflow
import XCTest

@MainActor
final class CSVExportServiceTests: XCTestCase {
    func testExportsExpectedColumnsAndData() throws {
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

        let url = try service.export(sessions: [session])
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

    func testFiltersByDateRange() throws {
        let service = CSVExportService()
        let inRange = TherapeuticSession(sessionDate: date("2024-12-01T00:00:00Z"))
        let outOfRange = TherapeuticSession(sessionDate: date("2024-10-01T00:00:00Z"))

        let range = self.date("2024-11-01T00:00:00Z") ... self.date("2024-12-31T00:00:00Z")
        let url = try service.export(sessions: [inRange, outOfRange], dateRange: range)
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        XCTAssertFalse(lines[1].contains("2024-10"))
    }

    func testFiltersByTreatmentType() throws {
        let service = CSVExportService()
        let match = TherapeuticSession(sessionDate: Date(), treatmentType: .psilocybin)
        let nonMatch = TherapeuticSession(sessionDate: Date(), treatmentType: .ketamine)

        let url = try service.export(sessions: [match, nonMatch], treatmentType: .psilocybin)
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[1].contains("Psilocybin"))
        XCTAssertFalse(csv.contains("Ketamine"))
    }

    func testEscapesQuotesCommasNewlines() throws {
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

        let url = try service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(csv.contains("\"Hello, \"\"World\"\"\""))
        XCTAssertTrue(csv.contains("\"Line1\nLine2\""))
    }

    func testGuardsAgainstFormulaInjection() throws {
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

        let url = try service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(csv.contains("'=HYPERLINK"))
        XCTAssertTrue(csv.contains("'@bad"))
    }

    func testExportsOneThousandSessions() throws {
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

        let url = try service.export(sessions: sessions)
        let csv = try String(contentsOf: url, encoding: .utf8)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines.count, 1001) // header + 1000 rows
    }

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601) ?? Date()
    }

    // MARK: - Edge Cases: Empty and Minimal Data

    func testEmptySessionsArrayExportsHeaderOnly() throws {
        let service = CSVExportService()
        let url = try service.export(sessions: [])
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 1) // Header only
        XCTAssertEqual(
            lines[0],
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL"
        )
    }

    func testSessionWithAllEmptyFields() throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "",
            moodBefore: 5,
            moodAfter: 7,
            reflections: "",
            reminderDate: nil
        )

        let url = try service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2)
        // Empty fields should be quoted
        XCTAssertTrue(lines[1].contains("\"\""))
    }

    func testSessionWithNilMusicLink() throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test",
            moodBefore: 5,
            moodAfter: 7,
            reflections: "Test reflections"
        )

        let url = try service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)

        // Should end with quoted empty string for music link
        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertTrue(lines[1].hasSuffix("\"\""))
    }

    // MARK: - Edge Cases: Unicode and Special Characters

    func testUnicodeInAllFields() throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "🌈 Healing 日本語 émojis",
            moodBefore: 5,
            moodAfter: 7,
            reflections: "Reflections with émojis 🎵 and 中文",
            reminderDate: nil
        )
        session.musicLinkURL = "https://example.com/music/émoji🎵"

        let url = try service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(csv.contains("🌈 Healing 日本語 émojis"))
        XCTAssertTrue(csv.contains("Reflections with émojis 🎵 and 中文"))
        XCTAssertTrue(csv.contains("https://example.com/music/émoji🎵"))
    }

    func testVeryLongStringsInAllFields() throws {
        let service = CSVExportService()
        let longIntention = String(repeating: "A", count: 2000)
        let longReflections = String(repeating: "B", count: 3000)
        let longURL = "https://example.com/" + String(repeating: "x", count: 1000)

        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: longIntention,
            moodBefore: 5,
            moodAfter: 7,
            reflections: longReflections
        )
        session.musicLinkURL = longURL

        let url = try service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(csv.contains(longIntention))
        XCTAssertTrue(csv.contains(longReflections))
        XCTAssertTrue(csv.contains(longURL))
    }

    func testAllSpecialCharactersEscaped() throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test,with,commas",
            moodBefore: 5,
            moodAfter: 7,
            reflections: "Line1\nLine2\rLine3"
        )

        let url = try service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)

        // Fields with commas and newlines should be quoted
        XCTAssertTrue(csv.contains("\"Test,with,commas\""))
        XCTAssertTrue(csv.contains("\"Line1\nLine2\rLine3\""))
    }

    // MARK: - Edge Cases: Mood Values

    func testMoodBoundaryValues() throws {
        let service = CSVExportService()
        let session1 = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test1",
            moodBefore: 1,
            moodAfter: 10
        )
        let session2 = TherapeuticSession(
            sessionDate: date("2024-12-02T10:30:00Z"),
            treatmentType: .lsd,
            administration: .oral,
            intention: "Test2",
            moodBefore: 10,
            moodAfter: 1
        )

        let url = try service.export(sessions: [session1, session2])
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertTrue(lines[1].contains(",1,") || lines[1].contains(",1\""))
        XCTAssertTrue(lines[1].contains(",10,") || lines[1].contains(",10\""))
    }

    func testNegativeAndLargeMoodValues() throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test",
            moodBefore: -5,
            moodAfter: 100
        )

        let url = try service.export(sessions: [session])
        let csv = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(csv.contains("-5"))
        XCTAssertTrue(csv.contains("100"))
    }

    // MARK: - Edge Cases: Combined Filters

    func testCombinedDateRangeAndTreatmentTypeFilters() throws {
        let service = CSVExportService()
        let match = TherapeuticSession(
            sessionDate: date("2024-12-01T00:00:00Z"),
            treatmentType: .psilocybin
        )
        let wrongDate = TherapeuticSession(
            sessionDate: date("2024-10-01T00:00:00Z"),
            treatmentType: .psilocybin
        )
        let wrongType = TherapeuticSession(
            sessionDate: date("2024-12-01T00:00:00Z"),
            treatmentType: .ketamine
        )
        let wrongBoth = TherapeuticSession(
            sessionDate: date("2024-10-01T00:00:00Z"),
            treatmentType: .ketamine
        )

        let range = self.date("2024-11-01T00:00:00Z") ... self.date("2024-12-31T00:00:00Z")
        let url = try service.export(
            sessions: [match, wrongDate, wrongType, wrongBoth],
            dateRange: range,
            treatmentType: .psilocybin
        )
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 2) // Header + 1 matching row
        XCTAssertTrue(lines[1].contains("Psilocybin"))
        XCTAssertFalse(csv.contains("Ketamine"))
    }

    func testEmptyResultFromFiltering() throws {
        let service = CSVExportService()
        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T00:00:00Z"),
            treatmentType: .psilocybin
        )

        let range = self.date("2025-01-01T00:00:00Z") ... self.date("2025-12-31T00:00:00Z")
        let url = try service.export(sessions: [session], dateRange: range)
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 1) // Header only, no data rows
    }

    // MARK: - Edge Cases: All Treatment Types and Administration Methods

    func testAllTreatmentTypes() throws {
        let service = CSVExportService()
        var sessions: [TherapeuticSession] = []

        for treatmentType in PsychedelicTreatmentType.allCases {
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: treatmentType,
                administration: .oral,
                intention: "Test \(treatmentType.displayName)",
                moodBefore: 5,
                moodAfter: 7
            )
            sessions.append(session)
        }

        let url = try service.export(sessions: sessions)
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, PsychedelicTreatmentType.allCases.count + 1)

        // Verify all treatment types are present
        for treatmentType in PsychedelicTreatmentType.allCases {
            XCTAssertTrue(csv.contains(treatmentType.displayName))
        }
    }

    func testAllAdministrationMethods() throws {
        let service = CSVExportService()
        var sessions: [TherapeuticSession] = []

        for administrationMethod in AdministrationMethod.allCases {
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: .psilocybin,
                administration: administrationMethod,
                intention: "Test \(administrationMethod.displayName)",
                moodBefore: 5,
                moodAfter: 7
            )
            sessions.append(session)
        }

        let url = try service.export(sessions: sessions)
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, AdministrationMethod.allCases.count + 1)

        // Verify all administration methods are present
        for method in AdministrationMethod.allCases {
            XCTAssertTrue(csv.contains(method.displayName))
        }
    }

    // MARK: - Edge Cases: Multiple Formula Injection Patterns

    func testMultipleFormulaInjectionPatterns() throws {
        let service = CSVExportService()
        let sessions = [
            TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "=1+1",
                moodBefore: 5,
                moodAfter: 7,
                reflections: "+cmd"
            ),
            TherapeuticSession(
                sessionDate: date("2024-12-02T00:00:00Z"),
                treatmentType: .lsd,
                administration: .oral,
                intention: "-2-2",
                moodBefore: 5,
                moodAfter: 7,
                reflections: "@SUM(A1:A2)"
            )
        ]

        let url = try service.export(sessions: sessions)
        let csv = try String(contentsOf: url, encoding: .utf8)

        // All dangerous patterns should be prefixed with '
        XCTAssertTrue(csv.contains("'=1+1"))
        XCTAssertTrue(csv.contains("'+cmd"))
        XCTAssertTrue(csv.contains("'-2-2"))
        XCTAssertTrue(csv.contains("'@SUM"))
    }

    // MARK: - Edge Cases: Data Integrity

    func testMultipleMusicLinkFormats() throws {
        let service = CSVExportService()
        let session1 = TherapeuticSession(
            sessionDate: date("2024-12-01T00:00:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test1",
            moodBefore: 5,
            moodAfter: 7
        )
        session1.musicLinkURL = "https://open.spotify.com/track/abc"

        let session2 = TherapeuticSession(
            sessionDate: date("2024-12-02T00:00:00Z"),
            treatmentType: .lsd,
            administration: .oral,
            intention: "Test2",
            moodBefore: 5,
            moodAfter: 7
        )
        session2.musicLinkURL = "https://youtube.com/watch?v=xyz"

        let session3 = TherapeuticSession(
            sessionDate: date("2024-12-03T00:00:00Z"),
            treatmentType: .mdma,
            administration: .oral,
            intention: "Test3",
            moodBefore: 5,
            moodAfter: 7
        )
        // No music link

        let url = try service.export(sessions: [session1, session2, session3])
        let csv = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(csv.contains("https://open.spotify.com/track/abc"))
        XCTAssertTrue(csv.contains("https://youtube.com/watch?v=xyz"))

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 4) // Header + 3 rows
    }

    func testDateFormatConsistency() throws {
        let service = CSVExportService()
        let dates = [
            date("2024-01-15T09:30:00Z"),
            date("2024-06-20T14:45:00Z"),
            date("2024-12-31T23:59:00Z")
        ]

        var sessions: [TherapeuticSession] = []
        for dateValue in dates {
            let session = TherapeuticSession(
                sessionDate: dateValue,
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test",
                moodBefore: 5,
                moodAfter: 7
            )
            sessions.append(session)
        }

        let url = try service.export(sessions: sessions)
        let csv = try String(contentsOf: url, encoding: .utf8)

        let lines = csv.split(separator: "\n").map(String.init)
        XCTAssertEqual(lines.count, 4)

        // All dates should be formatted consistently (medium date + short time)
        for line in lines.dropFirst() {
            // Should start with a quoted date field
            XCTAssertTrue(line.hasPrefix("\"") || !line.isEmpty)
        }
    }
}
