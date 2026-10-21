@testable import Afterflow
import Foundation
import Testing

/// Header matching, delimiters, encodings and line endings.
@MainActor
struct CSVImportFormatTests {
    private typealias Support = CSVImportTestSupport

    // MARK: - Round trip

    @Test("Afterflow export imports with nothing skipped, defaulted or reworded") func exportRoundTrip() throws {
        let session = TherapeuticSession(
            sessionDate: Support.localDate(2024, 12, 1, 10, 30),
            treatmentType: .mdma,
            administration: .intramuscular,
            intention: "Grounding, \"quoted\"",
            moodBefore: 4,
            moodAfter: 9,
            reflections: "Line1\nLine2"
        )
        session.musicLinkURL = "https://open.spotify.com/playlist/abc123"
        let url = try CSVExportService().export(sessions: [session])
        defer { try? FileManager.default.removeItem(at: url) }

        let result = try Support.service().importDetailed(from: url)

        #expect(result.skippedRows.isEmpty)
        #expect(result.defaultedMoodBeforeCount == 0)
        #expect(result.unrecognisedTreatmentCount == 0)
        #expect(result.unrecognisedAdministrationCount == 0)
        let restored = try #require(result.sessions.first)
        #expect(result.sessions.count == 1)
        #expect(restored.sessionDate == session.sessionDate)
        #expect(restored.treatmentType == .mdma)
        #expect(restored.administration == .intramuscular)
        #expect(restored.intention == "Grounding, \"quoted\"")
        #expect(restored.moodBefore == 4)
        #expect(restored.moodAfter == 9)
        #expect(restored.reflections == "Line1\nLine2")
        #expect(restored.musicLinkURL == "https://open.spotify.com/playlist/abc123")
    }

    // MARK: - Headers

    @Test("Columns can appear in any order and unknown columns are ignored") func reorderedAndExtraColumns() throws {
        let csv = Support.csv(
            header: "Notes,Extra,Mood Before,Date,Intention,Treatment Type",
            rows: ["Calm evening,ignored,6,2024-12-01 10:30,Be present,LSD"]
        )

        let result = try Support.service().importDetailed(from: csv)

        let session = try #require(result.sessions.first)
        #expect(session.reflections == "Calm evening")
        #expect(session.moodBefore == 6)
        #expect(session.intention == "Be present")
        #expect(session.treatmentType == .lsd)
        #expect(session.sessionDate == Support.localDate(2024, 12, 1, 10, 30))
    }

    @Test("Headers match regardless of case, spacing, underscores and hyphens") func headerSpellings() throws {
        let headers = [
            "DATE,TREATMENT TYPE,ADMINISTRATION,INTENTION,MOOD BEFORE,MOOD AFTER,REFLECTIONS,MUSIC LINK URL",
            "date,treatment_type,administration,intention,mood_before,mood_after,reflections,music_link_url",
            "date,treatment-type,administration,intention,mood-before,mood-after,reflections,music-link-url",
            " Date , Treatment Type ,Administration, Intention ,Mood  Before,Mood After,Reflections,Music Link URL "
        ]

        for header in headers {
            let csv = Support.csv(header: header, rows: ["2024-12-01,Ketamine,IV,Intent,3,8,Notes,https://youtu.be/x"])
            let session = try #require(Support.service().importDetailed(from: csv).sessions.first)
            #expect(session.treatmentType == .ketamine)
            #expect(session.administration == .intravenous)
            #expect(session.intention == "Intent")
            #expect(session.moodBefore == 3)
            #expect(session.moodAfter == 8)
            #expect(session.reflections == "Notes")
            #expect(session.musicLinkProvider == .youtube)
        }
    }

    @Test("Synonym headers map to the right columns") func synonymHeaders() throws {
        let synonymSets: [[String]] = [
            ["Session Date", "Substance", "Route", "Intent", "Before Mood", "After Mood", "Notes", "Music"],
            ["DateTime", "Medicine", "Method", "Goal", "Pre Mood", "Post Mood", "Journal", "Playlist"],
            ["When", "Treatment", "Administration", "Intention", "Mood Pre", "Mood Post", "Reflection", "Music Link"],
            ["Date Time", "Treatment", "Route", "Intention", "Mood Before", "Mood After", "Reflections", "Music Link"]
        ]

        for headers in synonymSets {
            let csv = Support.csv(
                header: headers.joined(separator: ","),
                rows: ["2024-12-01,Psilocybin,Oral,Open heart,4,7,Soft,https://soundcloud.com/a/b"]
            )
            let session = try #require(Support.service().importDetailed(from: csv).sessions.first)
            #expect(session.treatmentType == .psilocybin)
            #expect(session.administration == .oral)
            #expect(session.intention == "Open heart")
            #expect(session.moodBefore == 4)
            #expect(session.moodAfter == 7)
            #expect(session.reflections == "Soft")
            #expect(session.musicLinkProvider == .soundcloud)
        }
    }

    @Test("Only the Date column is required") func dateOnly() throws {
        let csv = Support.csv(header: "Date", rows: ["2024-12-01", "2024-12-02"])

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.sessions.count == 2)
        #expect(result.sessions[0].treatmentType == .other)
        #expect(result.sessions[0].administration == .other)
        #expect(result.sessions[0].moodBefore == 5)
        #expect(result.sessions[0].moodAfter == nil)
        #expect(result.sessions[0].intention.isEmpty)
        #expect(result.sessions[0].reflections.isEmpty)
        #expect(result.defaultedMoodBeforeCount == 2)
        #expect(result.unrecognisedTreatmentCount == 0)
        #expect(result.unrecognisedAdministrationCount == 0)
    }

    @Test("A missing Date column is an invalid header that names the column") func missingDateColumn() {
        let csv = Support.csv(header: "Treatment Type,Intention", rows: ["LSD,Secret intention"])

        let error = Support.thrownError(from: csv)

        guard case .invalidHeader? = error else {
            Issue.record("Expected invalidHeader, got \(String(describing: error))")
            return
        }
        #expect(error?.errorDescription?.contains("Date") == true)
        #expect(error?.errorDescription?.contains("Secret") == false)
    }

    // MARK: - Delimiters

    @Test("Semicolon-delimited files import") func semicolonDelimiter() throws {
        let csv = Support.csv(
            header: "Date;Treatment Type;Administration;Intention;Mood Before;Mood After",
            rows: ["2024-12-01 10:30;LSD;Oral;\"Quiet; still\";6,5;8"]
        )

        let session = try #require(Support.service().importDetailed(from: csv).sessions.first)

        #expect(session.treatmentType == .lsd)
        #expect(session.intention == "Quiet; still")
        #expect(session.moodBefore == 7)
        #expect(session.moodAfter == 8)
    }

    @Test("Tab-delimited files import") func tabDelimiter() throws {
        let csv = Support.csv(
            header: "Date\tTreatment\tIntention\tMood Before",
            rows: ["2024-12-01\tMDMA\tRelease, gently\t4"]
        )

        let session = try #require(Support.service().importDetailed(from: csv).sessions.first)

        #expect(session.treatmentType == .mdma)
        #expect(session.intention == "Release, gently")
        #expect(session.moodBefore == 4)
    }

    @Test("Delimiters inside quotes do not influence detection") func quotedDelimitersIgnored() throws {
        let csv = Support.csv(header: "\"Date\";\"Intention, with, commas\"", rows: ["2024-12-01;x"])

        let session = try #require(Support.service().importDetailed(from: csv).sessions.first)

        #expect(session.intention.isEmpty)
        #expect(session.sessionDate == Support.localDate(2024, 12, 1))
    }

    // MARK: - Encodings and line endings

    @Test("A UTF-8 byte order mark is stripped") func utf8ByteOrderMark() throws {
        let csv = Support.csv(header: "Date,Intention", rows: ["2024-12-01,Hello"])
        let data = Data([0xEF, 0xBB, 0xBF]) + Data(csv.utf8)

        let session = try #require(Support.service().importDetailed(from: data).sessions.first)

        #expect(session.intention == "Hello")
    }

    @Test("A byte order mark inside a string is stripped") func byteOrderMarkInString() throws {
        let csv = "\u{FEFF}" + Support.csv(header: "Date,Intention", rows: ["2024-12-01,Hello"])

        let session = try #require(Support.service().importDetailed(from: csv).sessions.first)

        #expect(session.intention == "Hello")
    }

    @Test("Windows-1252 files with accented characters import") func windows1252() throws {
        let csv = Support.csv(header: "Date;Intention;Reflections", rows: ["2024-12-01;Café;Zürich"])
        let data = try #require(csv.data(using: .windowsCP1252))
        #expect(String(data: data, encoding: .utf8) == nil)

        let session = try #require(Support.service().importDetailed(from: data).sessions.first)

        #expect(session.intention == "Café")
        #expect(session.reflections == "Zürich")
    }

    @Test("Binary data is rejected as an unreadable encoding") func unreadableEncoding() {
        let data = Data([0xFF, 0xFE, 0x00, 0x00])

        do {
            _ = try Support.service().importDetailed(from: data)
            Issue.record("Expected a parse failure")
        } catch let CSVImportService.CSVImportError.parseFailure(reason) {
            #expect(reason.contains("UTF-8"))
        } catch {
            Issue.record("Expected parseFailure, got \(error)")
        }
    }

    @Test("CRLF, CR and LF line endings all work") func lineEndings() throws {
        let endings = ["\r\n", "\r", "\n"]
        for ending in endings {
            let csv = ["Date,Intention", "2024-12-01,One", "2024-12-02,Two"].joined(separator: ending) + ending

            let result = try Support.service().importDetailed(from: csv)

            #expect(result.sessions.map(\.intention) == ["One", "Two"])
        }
    }

    @Test("Quoted cells keep embedded CRLF line breaks as newlines") func quotedLineBreaks() throws {
        let csv = "Date,Reflections\r\n2024-12-01,\"First\r\nSecond\"\r\n"

        let session = try #require(Support.service().importDetailed(from: csv).sessions.first)

        #expect(session.reflections == "First\nSecond")
    }

    // MARK: - Whole-file problems and row shape

    @Test("An empty or whitespace-only file throws emptyFile") func emptyFile() {
        for csv in ["", "\n\n", "  \r\n ,,\n"] {
            let error = Support.thrownError(from: csv)
            guard case .emptyFile? = error else {
                Issue.record("Expected emptyFile, got \(String(describing: error))")
                return
            }
        }
    }

    @Test("A header-only file imports nothing without throwing") func headerOnly() throws {
        let result = try Support.service().importDetailed(from: Support.exportHeader + "\n")

        #expect(result.sessions.isEmpty)
        #expect(result.skippedRows.isEmpty)
    }

    @Test("Blank rows are ignored silently and short rows are padded") func blankAndShortRows() throws {
        let csv = Support.csv(
            header: Support.exportHeader,
            rows: ["", "2024-12-01,LSD,Oral,Short row", ",,,,,,,", "   ", "2024-12-02,MDMA,Oral,Full,5,6,Notes,"]
        )

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.skippedRows.isEmpty)
        #expect(result.sessions.count == 2)
        #expect(result.sessions[0].intention == "Short row")
        #expect(result.sessions[0].moodBefore == 5)
        #expect(result.sessions[0].moodAfter == nil)
        #expect(result.sessions[0].musicLinkURL == nil)
        #expect(result.defaultedMoodBeforeCount == 1)
    }

    @Test("Leading blank lines before the header are tolerated") func leadingBlankLines() throws {
        let csv = "\n\nDate,Intention\n2024-12-01,Hello\n"

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.sessions.count == 1)
    }

    @Test("The legacy API still returns plain sessions") func legacyAPI() throws {
        let csv = Support.csv(header: "Date,Intention", rows: ["2024-12-01,Hello", "nonsense,Skipped"])
        let service = Support.service()

        let fromString = try service.import(from: csv)
        let fromData = try service.import(from: Data(csv.utf8))

        #expect(fromString.map(\.intention) == ["Hello"])
        #expect(fromData.map(\.intention) == ["Hello"])
    }
}
