@testable import Afterflow
import Foundation
import Testing

/// Treatment, administration, mood and bad-row handling.
@MainActor
struct CSVImportValueTests {
    private typealias Support = CSVImportTestSupport

    private func importRow(_ row: String) throws -> CSVImportResult {
        try Support.service().importDetailed(from: Support.csv(header: Support.exportHeader, rows: [row]))
    }

    // MARK: - Treatment

    @Test("Treatment matches display names and raw values case-insensitively") func treatmentCaseInsensitive() throws {
        let inputs: [(text: String, expected: PsychedelicTreatmentType)] = [
            ("psilocybin", .psilocybin), ("PSILOCYBIN", .psilocybin), (" Lsd ", .lsd), ("mdma", .mdma),
            ("KETAMINE", .ketamine), ("ayahuasca", .ayahuasca), ("Mescaline", .mescaline),
            ("cannabis", .cannabis), ("DMT", .dmt), ("other", .other)
        ]

        for input in inputs {
            let result = try self.importRow("2024-12-01,\(input.text),Oral,x,5,6,,")

            #expect(result.sessions.first?.treatmentType == input.expected)
            #expect(result.unrecognisedTreatmentCount == 0)
        }
    }

    @Test("Common treatment synonyms are recognised") func treatmentSynonyms() throws {
        let inputs: [(text: String, expected: PsychedelicTreatmentType)] = [
            ("Mushrooms", .psilocybin), ("magic mushrooms", .psilocybin), ("Shrooms", .psilocybin),
            ("Acid", .lsd), ("Molly", .mdma), ("ECSTASY", .mdma),
            ("Esketamine", .ketamine), ("Spravato", .ketamine)
        ]

        for input in inputs {
            let result = try self.importRow("2024-12-01,\(input.text),Oral,x,5,6,,")

            #expect(result.sessions.first?.treatmentType == input.expected)
            #expect(result.sessions.first?.reflections == "")
            #expect(result.unrecognisedTreatmentCount == 0)
        }
    }

    @Test("A blank treatment is Other and is not counted as unrecognised") func blankTreatment() throws {
        let result = try self.importRow("2024-12-01,,Oral,x,5,6,Kept,")

        #expect(result.sessions.first?.treatmentType == .other)
        #expect(result.sessions.first?.reflections == "Kept")
        #expect(result.unrecognisedTreatmentCount == 0)
    }

    @Test("An unrecognised treatment becomes Other and is kept in reflections") func unrecognisedTreatment() throws {
        let result = try self.importRow("2024-12-01,San Pedro,Oral,x,5,6,Felt open,")

        let session = try #require(result.sessions.first)
        #expect(session.treatmentType == .other)
        #expect(session.treatmentTypeRawValue == PsychedelicTreatmentType.other.rawValue)
        #expect(session.reflections == "Felt open\n\nImported treatment: San Pedro")
        #expect(result.unrecognisedTreatmentCount == 1)
    }

    @Test("Appended notes have no leading newlines when reflections are empty") func noteWithoutReflections() throws {
        let result = try self.importRow("2024-12-01,San Pedro,Sublingual,x,5,6,,")

        let session = try #require(result.sessions.first)
        #expect(session.reflections == "Imported treatment: San Pedro\n\nImported administration: Sublingual")
        #expect(result.unrecognisedTreatmentCount == 1)
        #expect(result.unrecognisedAdministrationCount == 1)
    }

    // MARK: - Administration

    @Test("Administration matches names and synonyms case-insensitively") func administrationMatching() throws {
        let inputs: [(text: String, expected: AdministrationMethod)] = [
            ("Intravenous (IV)", .intravenous), ("iv", .intravenous), ("IV", .intravenous),
            ("intravenous", .intravenous), ("Intramuscular (IM)", .intramuscular), ("im", .intramuscular),
            ("Intranasal", .nasal), ("nasal", .nasal), ("ORAL", .oral), ("by mouth", .oral),
            ("By  Mouth", .oral), ("other", .other)
        ]

        for input in inputs {
            let result = try self.importRow("2024-12-01,LSD,\(input.text),x,5,6,,")

            #expect(result.sessions.first?.administration == input.expected)
            #expect(result.unrecognisedAdministrationCount == 0)
        }
    }

    @Test("A blank administration is Other") func blankAdministration() throws {
        let result = try self.importRow("2024-12-01,LSD,,x,5,6,,")

        #expect(result.sessions.first?.administration == .other)
        #expect(result.unrecognisedAdministrationCount == 0)
    }

    @Test("An unrecognised administration becomes Other, kept in reflections") func unrecognisedAdmin() throws {
        let result = try self.importRow("2024-12-01,LSD,Under the tongue,x,5,6,Notes,")

        let session = try #require(result.sessions.first)
        #expect(session.administration == .other)
        #expect(session.reflections == "Notes\n\nImported administration: Under the tongue")
        #expect(result.unrecognisedAdministrationCount == 1)
        #expect(result.unrecognisedTreatmentCount == 0)
    }

    // MARK: - Moods

    @Test("Mood Before accepts plain, padded, fraction-of-ten and decimal values") func acceptedMoods() throws {
        let inputs: [(text: String, expected: Int)] = [
            ("7", 7), (" 7 ", 7), ("7/10", 7), ("7 / 10", 7), ("7.0", 7), ("6.5", 7), ("6.4", 6),
            ("1", 1), ("10", 10), ("10/10", 10), ("9.5", 10)
        ]

        for input in inputs {
            let result = try self.importRow("2024-12-01,LSD,Oral,x,\(input.text),\(input.text),,")

            #expect(result.sessions.first?.moodBefore == input.expected)
            #expect(result.sessions.first?.moodAfter == input.expected)
            #expect(result.skippedRows.isEmpty)
            #expect(result.defaultedMoodBeforeCount == 0)
        }
    }

    @Test("Out-of-range and unparseable moods skip the row") func rejectedMoods() throws {
        let inputs = ["0", "11", "-3", "abc", "5/5", "10.5", "1e1", "nan", "7/", "/10", "7/10/3", "five"]

        for input in inputs {
            let csv = Support.csv(
                header: Support.exportHeader,
                rows: [
                    "2024-12-02,LSD,Oral,Good,5,6,,",
                    "2024-12-01,LSD,Oral,Bad,\(input),6,,"
                ]
            )

            let result = try Support.service().importDetailed(from: csv)

            #expect(result.sessions.map(\.intention) == ["Good"])
            #expect(result.skippedRows == [CSVImportSkippedRow(line: 3, reason: "mood before must be 1–10")])
        }
    }

    @Test("An invalid Mood After skips the row") func invalidMoodAfter() throws {
        let csv = Support.csv(
            header: Support.exportHeader,
            rows: [
                "2024-12-02,LSD,Oral,Good,5,6,,",
                "2024-12-01,LSD,Oral,Bad,5,11,,",
                "2024-12-03,LSD,Oral,Worse,5,soaring,,"
            ]
        )

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.sessions.map(\.intention) == ["Good"])
        #expect(result.skippedRows.map(\.line) == [3, 4])
        #expect(result.skippedRows.allSatisfy { $0.reason == "mood after must be 1–10" })
    }

    @Test("A blank Mood Before defaults to 5 and is counted") func blankMoodBefore() throws {
        let csv = Support.csv(
            header: Support.exportHeader,
            rows: ["2024-12-01,LSD,Oral,A,,7,,", "2024-12-02,LSD,Oral,B, ,,,", "2024-12-03,LSD,Oral,C,3,,,"]
        )

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.sessions.map(\.moodBefore) == [5, 5, 3])
        #expect(result.sessions.map(\.moodAfter) == [7, nil, nil])
        #expect(result.defaultedMoodBeforeCount == 2)
        #expect(result.skippedRows.isEmpty)
    }

    @Test("A skipped row is not counted as defaulted or unrecognised") func skippedRowsDoNotCount() throws {
        let csv = Support.csv(
            header: Support.exportHeader,
            rows: ["2024-12-01,LSD,Oral,Good,5,6,,", "2024-12-02,Weird,Odd,Bad,,99,,"]
        )

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.sessions.count == 1)
        #expect(result.defaultedMoodBeforeCount == 0)
        #expect(result.unrecognisedTreatmentCount == 0)
        #expect(result.unrecognisedAdministrationCount == 0)
    }

    // MARK: - Bad rows

    @Test("A bad row is skipped with its line number while the rest import") func badRowSkipped() throws {
        let csv = Support.csv(
            header: Support.exportHeader,
            rows: [
                "2024-12-01,LSD,Oral,First,5,6,,",
                "not a date,LSD,Oral,Second,5,6,,",
                "",
                "2024-12-03,LSD,Oral,Third,5,6,,",
                "2024-12-04,LSD,Oral,Fourth,0,6,,"
            ]
        )

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.sessions.map(\.intention) == ["First", "Third"])
        #expect(result.skippedRows.map(\.line) == [3, 6])
        #expect(result.skippedRows.map(\.reason) == ["date not recognised", "mood before must be 1–10"])
    }

    @Test("Skip reasons never contain cell contents") func reasonsArePrivate() throws {
        let csv = Support.csv(
            header: Support.exportHeader,
            rows: [
                "2024-12-01,LSD,Oral,Fine,5,6,,",
                "SECRET-DATE,LSD,Oral,SECRET-INTENTION,5,6,SECRET-NOTES,",
                "2024-12-02,LSD,Oral,SECRET-INTENTION,SECRET-MOOD,6,SECRET-NOTES,",
                "2024-12-03,LSD,Oral,SECRET-INTENTION,5,SECRET-MOOD,SECRET-NOTES,"
            ]
        )

        let result = try Support.service().importDetailed(from: csv)

        #expect(result.skippedRows.count == 3)
        for skipped in result.skippedRows {
            #expect(!skipped.reason.contains("SECRET"))
        }
    }

    @Test("When every row is bad the import throws noValidRows without echoing cells") func allRowsBad() {
        let csv = Support.csv(
            header: Support.exportHeader,
            rows: ["SECRET,LSD,Oral,x,5,6,,", "2024-12-01,LSD,Oral,x,SECRET,6,,"]
        )

        let error = Support.thrownError(from: csv)

        guard case .noValidRows? = error else {
            Issue.record("Expected noValidRows, got \(String(describing: error))")
            return
        }
        #expect(error?.errorDescription?.contains("SECRET") == false)
    }

    @Test("Music links are still sanitised and classified") func musicLinks() throws {
        let csv = Support.csv(
            header: Support.exportHeader,
            rows: [
                "2024-12-01,LSD,Oral,A,5,6,,'https://open.spotify.com/track/abc",
                "2024-12-02,LSD,Oral,B,5,6,,https://example.com/mix",
                "2024-12-03,LSD,Oral,C,5,6,,open.spotify.com/track/xyz"
            ]
        )

        let sessions = try Support.service().importDetailed(from: csv).sessions

        #expect(sessions[0].musicLinkURL == "https://open.spotify.com/track/abc")
        #expect(sessions[0].musicLinkProvider == .spotify)
        #expect(sessions[1].musicLinkProvider == .linkOnly)
        #expect(sessions[2].musicLinkProvider == .spotify)
    }
}
