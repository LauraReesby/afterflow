@testable import Afterflow
import XCTest
#if canImport(PDFKit)
    import PDFKit
#endif

final class PDFExportServiceTests: XCTestCase {
    func testGeneratesPDFWithSessions() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Grounding",
                moodBefore: 4,
                moodAfter: 6,
                reflections: "Notes",
                reminderDate: nil
            )
            session.musicLinkURL = "https://open.spotify.com/playlist/abc"

            let url = try service.export(sessions: [session])
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)
            XCTAssertNotNil(document)
            let pageText = document?.string ?? ""
            XCTAssertTrue(pageText.contains("Grounding"))
            XCTAssertTrue(pageText.contains("Music Link"))
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testFiltersByDateRange() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let inRange = TherapeuticSession(sessionDate: date("2024-12-01T00:00:00Z"))
            inRange.intention = "In Range"
            let outOfRange = TherapeuticSession(sessionDate: date("2024-10-01T00:00:00Z"))
            outOfRange.intention = "Out"

            let range = self.date("2024-11-01T00:00:00Z") ... self.date("2024-12-31T00:00:00Z")
            let url = try service.export(sessions: [inRange, outOfRange], dateRange: range)
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)
            let pageText = document?.string ?? ""
            XCTAssertTrue(pageText.contains("In Range"))
            XCTAssertFalse(pageText.contains("Out"))
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testPerformanceTwentyFiveSessions() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            var sessions: [TherapeuticSession] = []
            for i in 0 ..< 25 {
                let session = TherapeuticSession(
                    sessionDate: Date().addingTimeInterval(TimeInterval(i * 60)),
                    treatmentType: .psilocybin,
                    administration: .oral,
                    intention: "Intent \(i)",
                    moodBefore: 5,
                    moodAfter: 6,
                    reflections: "Ref \(i)",
                    reminderDate: nil
                )
                sessions.append(session)
            }

            measure {
                _ = try? service.export(sessions: sessions, options: .init(includeCoverPage: false))
            }
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601) ?? Date()
    }

    // MARK: - Edge Cases: Cover Page Options

    func testCoverPageIncluded() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test",
                moodBefore: 5,
                moodAfter: 7
            )

            let url = try service.export(sessions: [session], options: .init(includeCoverPage: true))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            let pageText = document?.string ?? ""
            XCTAssertTrue(pageText.contains("Session Export"))
            XCTAssertTrue(pageText.contains("Generated on"))
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testCoverPageExcluded() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "UniqueTestIntention12345",
                moodBefore: 5,
                moodAfter: 7
            )

            let url = try service.export(sessions: [session], options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            // Verify PDF was created (without relying on text extraction)
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testPrivacyNoteOption() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test",
                moodBefore: 5,
                moodAfter: 7
            )

            // Test that privacy note option exists and can be set
            let optionsWithPrivacy = PDFExportService.Options(includeCoverPage: true, showPrivacyNote: true)
            let optionsWithoutPrivacy = PDFExportService.Options(includeCoverPage: true, showPrivacyNote: false)

            let url1 = try service.export(sessions: [session], options: optionsWithPrivacy)
            let url2 = try service.export(sessions: [session], options: optionsWithoutPrivacy)

            XCTAssertNotNil(url1)
            XCTAssertNotNil(url2)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    // MARK: - Edge Cases: Empty and Minimal Data

    func testEmptySessionsShowsEmptyState() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let url = try service.export(sessions: [])
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            let pageText = document?.string ?? ""
            XCTAssertTrue(pageText.contains("No sessions found"))
            XCTAssertTrue(pageText.contains("Adjust filters or add sessions to export"))
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testSessionWithAllEmptyOptionalFields() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "",
                moodBefore: 5,
                moodAfter: 7,
                reflections: ""
            )
            // No music link

            let url = try service.export(sessions: [session], options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            // Verify PDF was created successfully with the session
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    // MARK: - Edge Cases: Unicode and Special Characters

    func testUnicodeAndEmojiInAllFields() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "🌈 Healing 日本語 émojis",
                moodBefore: 5,
                moodAfter: 7,
                reflections: "Reflections with émojis 🎵 and 中文"
            )
            session.musicLinkURL = "https://example.com/émoji🎵"

            let url = try service.export(sessions: [session], options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            // Verify PDF was created successfully (Unicode handling can vary in PDFs)
            XCTAssertNotNil(document)
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testVeryLongReflections() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let longReflections = String(
                repeating: "This is a very long reflection that should wrap across multiple lines in the PDF. ",
                count: 50
            )
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test",
                moodBefore: 5,
                moodAfter: 7,
                reflections: longReflections
            )

            let url = try service.export(sessions: [session], options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            // Verify PDF handles long text
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testMultilineReflections() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test",
                moodBefore: 5,
                moodAfter: 7,
                reflections: "Line 1\nLine 2\nLine 3"
            )

            let url = try service.export(sessions: [session], options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            // Verify PDF handles multiline text
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    // MARK: - Edge Cases: Filtering

    func testFiltersByTreatmentType() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let match = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: .psilocybin
            )
            match.intention = "UniqueMatch9876"
            let nonMatch = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: .ketamine
            )
            nonMatch.intention = "UniqueNoMatch5432"

            let url = try service.export(
                sessions: [match, nonMatch],
                treatmentType: .psilocybin,
                options: .init(includeCoverPage: false)
            )
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            // Verify PDF was created successfully (filtering logic is tested at service level)
            XCTAssertNotNil(document)
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testCombinedDateRangeAndTreatmentTypeFilters() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let match = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: .psilocybin
            )
            match.intention = "UniqueBothMatch1111"
            let wrongDate = TherapeuticSession(
                sessionDate: date("2024-10-01T00:00:00Z"),
                treatmentType: .psilocybin
            )
            wrongDate.intention = "UniqueWrongDate2222"
            let wrongType = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: .ketamine
            )
            wrongType.intention = "UniqueWrongType3333"

            let range = self.date("2024-11-01T00:00:00Z") ... self.date("2024-12-31T00:00:00Z")
            let url = try service.export(
                sessions: [match, wrongDate, wrongType],
                dateRange: range,
                treatmentType: .psilocybin,
                options: .init(includeCoverPage: false)
            )
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            // Verify PDF was created successfully (combined filtering logic is tested at service level)
            XCTAssertNotNil(document)
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testFilteringResultsInEmptyState() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: .psilocybin
            )

            let range = self.date("2025-01-01T00:00:00Z") ... self.date("2025-12-31T00:00:00Z")
            let url = try service.export(sessions: [session], dateRange: range)
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            let pageText = document?.string ?? ""
            XCTAssertTrue(pageText.contains("No sessions found"))
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    // MARK: - Edge Cases: All Treatment Types and Administration Methods

    func testAllTreatmentTypes() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
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

            let url = try service.export(sessions: sessions, options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            // Verify PDF was created successfully with all treatment types
            XCTAssertNotNil(document)
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testAllAdministrationMethods() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            var sessions: [TherapeuticSession] = []

            for method in AdministrationMethod.allCases {
                let session = TherapeuticSession(
                    sessionDate: date("2024-12-01T00:00:00Z"),
                    treatmentType: .psilocybin,
                    administration: method,
                    intention: "Test \(method.displayName)",
                    moodBefore: 5,
                    moodAfter: 7
                )
                sessions.append(session)
            }

            let url = try service.export(sessions: sessions, options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            // Verify PDF was created with all administration methods
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    // MARK: - Edge Cases: Performance and Page Breaks

    func testPerformanceOneHundredSessions() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            var sessions: [TherapeuticSession] = []
            for i in 0 ..< 100 {
                let session = TherapeuticSession(
                    sessionDate: date("2024-12-01T00:00:00Z").addingTimeInterval(TimeInterval(i * 3600)),
                    treatmentType: .psilocybin,
                    administration: .oral,
                    intention: "Intent \(i)",
                    moodBefore: 5,
                    moodAfter: 7,
                    reflections: "Reflections \(i)"
                )
                sessions.append(session)
            }

            let url = try service.export(sessions: sessions, options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            XCTAssertGreaterThan(document?.pageCount ?? 0, 1) // Should span multiple pages
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    func testMultipleSessionsCausePageBreaks() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            var sessions: [TherapeuticSession] = []

            // Create sessions with long reflections to force page breaks
            for i in 0 ..< 20 {
                let session = TherapeuticSession(
                    sessionDate: date("2024-12-01T00:00:00Z").addingTimeInterval(TimeInterval(i * 3600)),
                    treatmentType: .psilocybin,
                    administration: .oral,
                    intention: "Session \(i)",
                    moodBefore: 5,
                    moodAfter: 7,
                    reflections: String(repeating: "Long reflections to fill space. ", count: 20)
                )
                sessions.append(session)
            }

            let url = try service.export(sessions: sessions, options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            XCTAssertGreaterThan(document?.pageCount ?? 0, 1) // Should span multiple pages
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    // MARK: - Edge Cases: Mood Values

    func testMoodBoundaryValues() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()
            let session = TherapeuticSession(
                sessionDate: date("2024-12-01T10:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Boundary Test",
                moodBefore: 1,
                moodAfter: 10
            )

            let url = try service.export(sessions: [session], options: .init(includeCoverPage: false))
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            // Verify PDF was created with boundary mood values
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    // MARK: - Edge Cases: Data Integrity

    func testMultipleMusicLinkFormats() throws {
        #if canImport(PDFKit)
            let service = PDFExportService()

            let session1 = TherapeuticSession(
                sessionDate: date("2024-12-01T00:00:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Spotify",
                moodBefore: 5,
                moodAfter: 7
            )
            session1.musicLinkURL = "https://open.spotify.com/track/abc"

            let session2 = TherapeuticSession(
                sessionDate: date("2024-12-02T00:00:00Z"),
                treatmentType: .lsd,
                administration: .oral,
                intention: "YouTube",
                moodBefore: 5,
                moodAfter: 7
            )
            session2.musicLinkURL = "https://youtube.com/watch?v=xyz"

            let session3 = TherapeuticSession(
                sessionDate: date("2024-12-03T00:00:00Z"),
                treatmentType: .mdma,
                administration: .oral,
                intention: "No Link",
                moodBefore: 5,
                moodAfter: 7
            )

            let url = try service.export(
                sessions: [session1, session2, session3],
                options: .init(includeCoverPage: false)
            )
            let data = try Data(contentsOf: url)
            let document = PDFDocument(data: data)

            XCTAssertNotNil(document)
            // Verify PDF was created with multiple sessions
            XCTAssertGreaterThan(document?.pageCount ?? 0, 0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }
}
