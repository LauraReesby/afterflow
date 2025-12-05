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

    // MARK: - Helpers

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601) ?? Date()
    }
}
