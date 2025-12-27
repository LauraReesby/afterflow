@testable import Afterflow
import XCTest

final class CSVImportServiceTests: XCTestCase {
    func testRoundTripExportImport() throws {
        let exportService = CSVExportService()
        let importService = CSVImportService()

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
        session.musicLinkURL = "https://open.spotify.com/playlist/abc123"

        let url = try exportService.export(sessions: [session])
        let imported = try importService.import(from: url)

        XCTAssertEqual(imported.count, 1)
        let restored = imported[0]
        XCTAssertEqual(restored.intention, "Grounding")
        XCTAssertEqual(restored.reflections, "Deep breath")
        XCTAssertEqual(restored.treatmentType, .psilocybin)
        XCTAssertEqual(restored.administration, .oral)
        XCTAssertEqual(restored.moodBefore, 4)
        XCTAssertEqual(restored.moodAfter, 7)
        XCTAssertEqual(restored.musicLinkURL, "https://open.spotify.com/playlist/abc123")
        XCTAssertEqual(restored.musicLinkProvider, .spotify)
    }

    func testParsesQuotedAndEscapedFields() throws {
        let exportService = CSVExportService()
        let importService = CSVImportService()

        let session = TherapeuticSession(
            sessionDate: date("2024-12-01T10:30:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Hello, \"World\"",
            moodBefore: 3,
            moodAfter: 4,
            reflections: "Line1\nLine2"
        )
        session.musicLinkURL = "https://soundcloud.com/artist/track"

        let url = try exportService.export(sessions: [session])
        let imported = try importService.import(from: url)

        XCTAssertEqual(imported.count, 1)
        let restored = imported[0]
        XCTAssertEqual(restored.intention, "Hello, \"World\"")
        XCTAssertEqual(restored.reflections, "Line1\nLine2")
        XCTAssertEqual(restored.musicLinkProvider, .soundcloud)
    }

    func testInvalidHeaderThrows() {
        let csv = """
        Bad,Header
        1,2
        """
        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case CSVImportService.CSVImportError.invalidHeader = error else {
                return XCTFail("Expected invalidHeader, got \(error)")
            }
        }
    }

    func testInvalidRowThrows() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Grounding,5,5,Missing URL"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case CSVImportService.CSVImportError.invalidRow = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
        }
    }

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601) ?? Date()
    }

    func testEmptyFileReturnsEmptyArray() throws {
        let csv = ""
        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 0)
    }

    func testHeaderOnlyFileReturnsEmptyArray() throws {
        let csv = "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL"
        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 0)
    }

    func testHeaderOnlyFileWithTrailingNewlineReturnsEmptyArray() throws {
        let csv = "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n"
        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 0)
    }

    func testFileWithSingleTrailingNewline() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Grounding,5,7,Reflections,\n"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].intention, "Grounding")
    }

    func testMixedLineEndingsAreNormalized() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\r\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test1,5,7,Reflections1,\n" +
            "\"Dec 2, 2024 at 10:30 AM\",LSD,Oral,Test2,5,8,Reflections2,\r" +
            "\"Dec 3, 2024 at 10:30 AM\",MDMA,Oral,Test3,6,9,Reflections3,"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 3)
        XCTAssertEqual(imported[0].intention, "Test1")
        XCTAssertEqual(imported[1].intention, "Test2")
        XCTAssertEqual(imported[2].intention, "Test3")
    }

    func testMoodValueZeroIsAccepted() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,0,10,Reflections,"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].moodBefore, 0)
        XCTAssertEqual(imported[0].moodAfter, 10)
    }

    func testMoodValueOutOfRangeIsAccepted() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,15,20,Reflections,"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].moodBefore, 15)
        XCTAssertEqual(imported[0].moodAfter, 20)
    }

    func testNegativeMoodValueIsAccepted() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,-5,10,Reflections,"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].moodBefore, -5)
    }

    func testNonNumericMoodValueThrows() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,abc,7,Reflections,"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case let CSVImportService.CSVImportError.invalidRow(index) = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
            XCTAssertEqual(index, 1)
        }
    }

    func testDecimalMoodValueThrows() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,5.5,7,Reflections,"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case CSVImportService.CSVImportError.invalidRow = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
        }
    }

    func testUnknownMusicProviderSetsLinkOnly() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,5,7,Reflections,https://example.com/music"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].musicLinkProvider, .linkOnly)
        XCTAssertEqual(imported[0].musicLinkURL, "https://example.com/music")
    }

    func testEmptyMusicLinkIsHandled() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,5,7,Reflections,"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertNil(imported[0].musicLinkURL)
        XCTAssertNil(imported[0].musicLinkWebURL)
    }

    func testMusicLinkWithoutProtocolIsNormalized() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,5,7,Reflections,open.spotify.com/track/abc"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].musicLinkProvider, .spotify)
        XCTAssertTrue(imported[0].musicLinkURL?.contains("spotify") ?? false)
    }

    func testInjectionGuardIsStripped() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test,5,7,Reflections,'https://open.spotify.com/track/abc"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].musicLinkProvider, .spotify)
        XCTAssertFalse(imported[0].musicLinkURL?.hasPrefix("'") ?? true)
    }

    func testMultipleMusicProviders() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test1,5,7,Reflections,https://open.spotify.com/track/abc\n" +
            "\"Dec 2, 2024 at 10:30 AM\",LSD,Oral,Test2,5,8,Reflections,https://youtube.com/watch?v=123\n" +
            "\"Dec 3, 2024 at 10:30 AM\",MDMA,Oral,Test3,6,9,Reflections,https://soundcloud.com/artist/track\n" +
            "\"Dec 4, 2024 at 10:30 AM\",Ketamine,Nasal,Test4,4,7,Reflections,https://music.apple.com/us/album/123"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 4)
        XCTAssertEqual(imported[0].musicLinkProvider, .spotify)
        XCTAssertEqual(imported[1].musicLinkProvider, .youtube)
        XCTAssertEqual(imported[2].musicLinkProvider, .soundcloud)
        XCTAssertEqual(imported[3].musicLinkProvider, .appleMusic)
    }

    func testInvalidDateFormatThrows() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "2024-12-01,Psilocybin,Oral,Test,5,7,Reflections,"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case let CSVImportService.CSVImportError.invalidRow(index) = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
            XCTAssertEqual(index, 1)
        }
    }

    func testMalformedDateThrows() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "Not a date,Psilocybin,Oral,Test,5,7,Reflections,"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case CSVImportService.CSVImportError.invalidRow = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
        }
    }

    func testInvalidTreatmentTypeThrows() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",InvalidTreatment,Oral,Test,5,7,Reflections,"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case CSVImportService.CSVImportError.invalidRow = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
        }
    }

    func testInvalidAdministrationMethodThrows() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,InvalidMethod,Test,5,7,Reflections,"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case CSVImportService.CSVImportError.invalidRow = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
        }
    }

    func testUnicodeInIntentionAndReflections() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,🌈 Healing 日本語,5,7,Reflections with émojis 🎵,"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].intention, "🌈 Healing 日本語")
        XCTAssertEqual(imported[0].reflections, "Reflections with émojis 🎵")
    }

    func testVeryLongStringsArePreserved() throws {
        let longIntention = String(repeating: "A", count: 1000)
        let longReflections = String(repeating: "B", count: 2000)

        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,\"\(longIntention)\",5,7,\"\(longReflections)\","

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].intention.count, 1000)
        XCTAssertEqual(imported[0].reflections.count, 2000)
    }

    func testEmptyIntentionAndReflections() throws {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,,5,7,,"

        let imported = try CSVImportService().import(from: csv)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].intention, "")
        XCTAssertEqual(imported[0].reflections, "")
    }

    func testFirstRowErrorReportsCorrectIndex() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "Invalid date,Psilocybin,Oral,Test,5,7,Reflections,\n" +
            "\"Dec 2, 2024 at 10:30 AM\",LSD,Oral,Test,5,8,Reflections,"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case let CSVImportService.CSVImportError.invalidRow(index) = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
            XCTAssertEqual(index, 1)
        }
    }

    func testMiddleRowErrorReportsCorrectIndex() {
        let csv =
            "Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL\n" +
            "\"Dec 1, 2024 at 10:30 AM\",Psilocybin,Oral,Test1,5,7,Reflections,\n" +
            "Invalid date,LSD,Oral,Test2,5,8,Reflections,\n" +
            "\"Dec 3, 2024 at 10:30 AM\",MDMA,Oral,Test3,6,9,Reflections,"

        XCTAssertThrowsError(try CSVImportService().import(from: csv)) { error in
            guard case let CSVImportService.CSVImportError.invalidRow(index) = error else {
                return XCTFail("Expected invalidRow, got \(error)")
            }
            XCTAssertEqual(index, 2)
        }
    }

    func testNonUTF8DataThrows() throws {
        let invalidData = Data([0xFF, 0xFE, 0x00, 0x00])
        let importService = CSVImportService()

        XCTAssertThrowsError(try importService.import(from: invalidData)) { error in
            guard case let CSVImportService.CSVImportError.parseFailure(reason) = error else {
                return XCTFail("Expected parseFailure, got \(error)")
            }
            XCTAssertTrue(reason.contains("UTF-8"))
        }
    }
}
