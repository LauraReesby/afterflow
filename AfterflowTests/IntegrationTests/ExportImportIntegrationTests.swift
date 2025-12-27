import Testing
import Foundation
@testable import Afterflow

@Suite("Export/Import Integration Tests")
struct ExportImportIntegrationTests {
    

    @Test("CSV round trip preserves all session data") func csvRoundTripPreservesData() async throws {
        
        let originalSessions = [
            TherapeuticSession(
                sessionDate: date("2024-12-01T14:30:00Z"),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Explore inner wisdom",
                moodBefore: 4,
                moodAfter: 8,
                reflections: "Deep insights about life patterns",
                reminderDate: date("2024-12-08T14:30:00Z")
            ),
            TherapeuticSession(
                sessionDate: date("2024-11-15T10:00:00Z"),
                treatmentType: .lsd,
                administration: .intramuscular,
                intention: "Creative breakthrough",
                moodBefore: 5,
                moodAfter: 9,
                reflections: "Enhanced creativity and flow state",
                reminderDate: nil
            )
        ]
        originalSessions[0].musicLinkURL = "https://open.spotify.com/playlist/123"
        originalSessions[1].musicLinkURL = "https://youtube.com/watch?v=abc"

        
        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: originalSessions)

        
        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        
        try? FileManager.default.removeItem(at: csvURL)

        
        #expect(importedSessions.count == 2)

        let first = importedSessions[0]
        #expect(first.treatmentType == PsychedelicTreatmentType.psilocybin)
        #expect(first.administration == AdministrationMethod.oral)
        #expect(first.intention == "Explore inner wisdom")
        #expect(first.moodBefore == 4)
        #expect(first.moodAfter == 8)
        #expect(first.reflections == "Deep insights about life patterns")
        #expect(first.musicLinkURL == "https://open.spotify.com/playlist/123")

        let second = importedSessions[1]
        #expect(second.treatmentType == PsychedelicTreatmentType.lsd)
        #expect(second.administration == AdministrationMethod.intramuscular)
        #expect(second.intention == "Creative breakthrough")
        #expect(second.moodBefore == 5)
        #expect(second.moodAfter == 9)
    }

    @Test("CSV round trip handles empty optional fields") func csvRoundTripWithEmptyFields() async throws {
        let originalSession = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ketamine,
            administration: .nasal,
            intention: "",
            moodBefore: 3,
            moodAfter: 6,
            reflections: "",
            reminderDate: nil
        )

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: [originalSession])

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 1)
        let imported = importedSessions[0]
        #expect(imported.intention.isEmpty)
        #expect(imported.reflections.isEmpty)
        #expect(imported.musicLinkURL == nil)
        #expect(imported.reminderDate == nil)
    }

    @Test("CSV round trip preserves special characters") func csvRoundTripWithSpecialCharacters() async throws {
        let originalSession = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .mdma,
            administration: .oral,
            intention: "Intention with \"quotes\", commas, and\nnewlines",
            moodBefore: 4,
            moodAfter: 8,
            reflections: "Reflection with special chars: <>&'\"",
            reminderDate: nil
        )

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: [originalSession])

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 1)
        let imported = importedSessions[0]
        #expect(imported.intention.contains("quotes"))
        #expect(imported.intention.contains("commas"))
        #expect(imported.intention.contains("newlines"))
        #expect(imported.reflections.contains("<>&'\""))
    }

    @Test("CSV round trip preserves Unicode and emoji") func csvRoundTripWithUnicode() async throws {
        let originalSession = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Explore creativity 🌈✨ with émotions françaises and 日本語",
            moodBefore: 5,
            moodAfter: 9,
            reflections: "Felt peaceful 🧘‍♀️ and connected 🌍",
            reminderDate: nil
        )

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: [originalSession])

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 1)
        let imported = importedSessions[0]
        #expect(imported.intention.contains("🌈"))
        #expect(imported.intention.contains("émotions"))
        #expect(imported.intention.contains("日本語"))
        #expect(imported.reflections.contains("🧘‍♀️"))
    }

    @Test("CSV round trip with large dataset") func csvRoundTripLargeDataset() async throws {
        
        let originalSessions = SessionFixtureFactory.makeSessions(count: 100)

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: originalSessions)

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 100)
        
        #expect(importedSessions[0].treatmentType == originalSessions[0].treatmentType)
        #expect(importedSessions[99].treatmentType == originalSessions[99].treatmentType)
    }

    

    @Test("Filtered export by date range then import") func filteredExportByDateRange() async throws {
        let inRange = TherapeuticSession(
            sessionDate: date("2024-12-01T00:00:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "In Range",
            moodBefore: 5,
            moodAfter: 8
        )
        let outOfRange = TherapeuticSession(
            sessionDate: date("2024-10-01T00:00:00Z"),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Out of Range",
            moodBefore: 4,
            moodAfter: 7
        )

        let exportService = CSVExportService()
        let range = date("2024-11-01T00:00:00Z") ... date("2024-12-31T00:00:00Z")
        let csvURL = try exportService.export(
            sessions: [inRange, outOfRange],
            dateRange: range
        )

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        
        #expect(importedSessions.count == 1)
        #expect(importedSessions[0].intention == "In Range")
    }

    @Test("Filtered export by treatment type then import") func filteredExportByTreatmentType() async throws {
        let psilocybin = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Psilocybin Session",
            moodBefore: 5,
            moodAfter: 8
        )
        let lsd = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .lsd,
            administration: .oral,
            intention: "LSD Session",
            moodBefore: 4,
            moodAfter: 7
        )

        let exportService = CSVExportService()
        let csvURL = try exportService.export(
            sessions: [psilocybin, lsd],
            treatmentType: .psilocybin
        )

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 1)
        #expect(importedSessions[0].treatmentType == .psilocybin)
        #expect(importedSessions[0].intention == "Psilocybin Session")
    }

    

    @Test("CSV round trip preserves all music link providers") func csvRoundTripMusicLinks() async throws {
        var spotify = SessionFixtureFactory.makeSessionWithMusicLink(provider: "spotify")
        var youtube = SessionFixtureFactory.makeSessionWithMusicLink(provider: "youtube")
        var apple = SessionFixtureFactory.makeSessionWithMusicLink(provider: "apple")

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: [spotify, youtube, apple])

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 3)
        #expect(importedSessions[0].musicLinkURL?.contains("spotify") == true)
        #expect(importedSessions[1].musicLinkURL?.contains("youtube") == true)
        #expect(importedSessions[2].musicLinkURL?.contains("apple") == true)
    }

    

    @Test("CSV round trip with mood boundary values") func csvRoundTripMoodBoundaries() async throws {
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ayahuasca,
            administration: .oral,
            intention: "Boundary test",
            moodBefore: 1,
            moodAfter: 10,
            reflections: "",
            reminderDate: nil
        )

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: [session])

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 1)
        #expect(importedSessions[0].moodBefore == 1)
        #expect(importedSessions[0].moodAfter == 10)
    }

    @Test("CSV round trip with all treatment types") func csvRoundTripAllTreatmentTypes() async throws {
        var sessions: [TherapeuticSession] = []
        for treatmentType in PsychedelicTreatmentType.allCases {
            sessions.append(TherapeuticSession(
                sessionDate: Date(),
                treatmentType: treatmentType,
                administration: .oral,
                intention: "Test \(treatmentType.displayName)",
                moodBefore: 5,
                moodAfter: 8
            ))
        }

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: sessions)

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == PsychedelicTreatmentType.allCases.count)
        
        for treatmentType in PsychedelicTreatmentType.allCases {
            #expect(importedSessions.contains { $0.treatmentType == treatmentType })
        }
    }

    @Test("CSV round trip with all administration methods") func csvRoundTripAllAdministrationMethods() async throws {
        var sessions: [TherapeuticSession] = []
        for method in AdministrationMethod.allCases {
            sessions.append(TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .psilocybin,
                administration: method,
                intention: "Test \(method.displayName)",
                moodBefore: 5,
                moodAfter: 8
            ))
        }

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: sessions)

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == AdministrationMethod.allCases.count)
        
        for method in AdministrationMethod.allCases {
            #expect(importedSessions.contains { $0.administration == method })
        }
    }

    

    private func date(_ iso8601: String) -> Date {
        ISO8601DateFormatter().date(from: iso8601) ?? Date()
    }
}
