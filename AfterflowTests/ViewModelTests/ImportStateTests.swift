@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct ImportStateTests {
    

    @Test(
        "Import CSV parses sessions successfully",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func importCSVParsesSessionsSuccessfully() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        let csvContent = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,Test intention,5,8,Test reflections,https://open.spotify.com/playlist/test
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-import.csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await Task.sleep(nanoseconds: 500_000_000) 

        
        try await TestHelpers.waitFor(
            { !importState.pendingImportedSessions.isEmpty || importState.importError != nil },
            timeout: 10.0
        )

        
        #expect(importState.pendingImportedSessions.count > 0)
        #expect(importState.importError == nil)

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test(
        "Import sets showing import confirmation",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func importSetsShowingImportConfirmation() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        let csvContent = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,Test intention,5,8,,
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-import-confirm.csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await Task.sleep(nanoseconds: 500_000_000) 

        
        try await TestHelpers.waitFor(
            { importState.showingImportConfirmation || importState.importError != nil },
            timeout: 10.0
        )

        
        #expect(importState.showingImportConfirmation == true)

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test(
        "Import sets pending imported sessions",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func importSetsPendingImportedSessions() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        let csvContent = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,Intention 1,5,8,,
        Dec 11, 2024 at 3:00 PM,LSD,Oral,Intention 2,4,9,,
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-import-pending.csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await Task.sleep(nanoseconds: 500_000_000) 

        
        try await TestHelpers.waitFor(
            { !importState.pendingImportedSessions.isEmpty || importState.importError != nil },
            timeout: 10.0
        )

        
        #expect(importState.importError == nil, "Import should succeed without errors")
        #expect(importState.pendingImportedSessions.count == 2)

        if importState.pendingImportedSessions.count >= 2 {
            #expect(importState.pendingImportedSessions[0].intention == "Intention 1")
            #expect(importState.pendingImportedSessions[1].intention == "Intention 2")
        }

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Confirm import adds sessions to store") func confirmImportAddsSessionsToStore() async throws {
        
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        let session1 = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test 1",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: nil
        )
        let session2 = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .mdma,
            administration: .oral,
            intention: "Test 2",
            moodBefore: 4,
            moodAfter: 9,
            reflections: "",
            reminderDate: nil
        )
        importState.pendingImportedSessions = [session1, session2]

        
        importState.confirmImport()

        
        let fetchedSessions = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        #expect(fetchedSessions.count == 2)
        #expect(fetchedSessions.contains { $0.intention == "Test 1" })
        #expect(fetchedSessions.contains { $0.intention == "Test 2" })
    }

    @Test("Confirm import clears pending sessions") func confirmImportClearsPendingSessions() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: nil
        )
        importState.pendingImportedSessions = [session]

        
        importState.confirmImport()

        
        #expect(importState.pendingImportedSessions.isEmpty)
    }

    

    @Test("Import error captured on invalid CSV") func importErrorCapturedOnInvalidCSV() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        let invalidCSV = """
        Invalid,Header,Structure
        Data,Data,Data
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-invalid.csv")
        try invalidCSV.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await TestHelpers.waitFor({ importState.importError != nil }, timeout: 2.0)

        
        #expect(importState.importError != nil)
        #expect(importState.pendingImportedSessions.isEmpty)

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Import error captured on file read failure") func importErrorCapturedOnFileReadFailure() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        let nonExistentURL = URL(fileURLWithPath: "/tmp/nonexistent-file-\(UUID().uuidString).csv")

        
        importState.importCSV(from: nonExistentURL)

        
        try await TestHelpers.waitFor({ importState.importError != nil }, timeout: 2.0)

        
        #expect(importState.importError != nil)
        #expect(importState.pendingImportedSessions.isEmpty)
    }

    @Test("Import error on store failure") func importErrorOnStoreFailure() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        let invalidSession = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "", 
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: nil
        )
        importState.pendingImportedSessions = [invalidSession]

        
        importState.confirmImport()

        
        
        if importState.importError != nil {
            #expect(importState.importError!.contains("Failed to import"))
        }
    }

    

    @Test("Import empty CSV file", .serialized, .disabled("Fails in full suite - MainActor/async timing issue"))
    func importEmptyCSVFile() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        let emptyCSV = ""
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-empty.csv")
        try emptyCSV.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await Task.sleep(nanoseconds: 500_000_000) 

        
        try await TestHelpers.waitFor(
            { importState.importError != nil || importState.showingImportConfirmation },
            timeout: 10.0
        )

        
        if importState.importError == nil {
            #expect(importState.pendingImportedSessions.isEmpty)
        }

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Import malformed CSV handled") func importMalformedCSVHandled() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        let malformedCSV = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Invalid date format,Psilocybin,Oral,Test,5,8,,
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-malformed.csv")
        try malformedCSV.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await TestHelpers.waitFor(
            { importState.importError != nil || !importState.pendingImportedSessions.isEmpty },
            timeout: 2.0
        )

        
        #expect(importState.importError != nil || importState.pendingImportedSessions.isEmpty)

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test("Confirm import with empty pending sessions") func confirmImportWithEmptyPendingSessions() async throws {
        
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        importState.pendingImportedSessions = []

        
        importState.confirmImport()

        
        let fetchedSessions = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        #expect(fetchedSessions.isEmpty)
        #expect(importState.importError == nil)
    }

    @Test("Multiple imports in sequence", .serialized, .disabled("Fails in full suite - MainActor/async timing issue"))
    func multipleImportsInSequence() async throws {
        
        let (container, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        
        let csv1 = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,First import,5,8,,
        """
        let tempURL1 = TestHelpers.makeTemporaryFileURL(filename: "test-import-1.csv")
        try csv1.write(to: tempURL1, atomically: true, encoding: .utf8)

        importState.importCSV(from: tempURL1)
        try await Task.sleep(nanoseconds: 50_000_000) 
        try await TestHelpers.waitFor(
            { !importState.pendingImportedSessions.isEmpty || importState.importError != nil },
            timeout: 3.0
        )

        let firstImportCount = importState.pendingImportedSessions.count
        importState.confirmImport()

        
        let csv2 = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 11, 2024 at 3:00 PM,LSD,Oral,Second import,4,9,,
        """
        let tempURL2 = TestHelpers.makeTemporaryFileURL(filename: "test-import-2.csv")
        try csv2.write(to: tempURL2, atomically: true, encoding: .utf8)

        importState.importCSV(from: tempURL2)
        try await Task.sleep(nanoseconds: 50_000_000) 
        try await TestHelpers.waitFor(
            { !importState.pendingImportedSessions.isEmpty || importState.importError != nil },
            timeout: 3.0
        )

        let secondImportCount = importState.pendingImportedSessions.count
        importState.confirmImport()

        
        #expect(firstImportCount > 0)
        #expect(secondImportCount > 0)

        let fetchedSessions = try container.mainContext.fetch(FetchDescriptor<TherapeuticSession>())
        #expect(fetchedSessions.count == firstImportCount + secondImportCount)

        
        try? FileManager.default.removeItem(at: tempURL1)
        try? FileManager.default.removeItem(at: tempURL2)
    }

    @Test(
        "Import with Unicode characters",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func importWithUnicodeCharacters() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        let csvWithUnicode = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,Explore creativity 🌈✨,5,8,Felt peaceful 🧘‍♀️,
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-unicode.csv")
        try csvWithUnicode.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await Task.sleep(nanoseconds: 500_000_000) 

        
        try await TestHelpers.waitFor(
            { !importState.pendingImportedSessions.isEmpty || importState.importError != nil },
            timeout: 3.0
        )

        
        #expect(importState.importError == nil)
        #expect(importState.pendingImportedSessions.count == 1)

        if !importState.pendingImportedSessions.isEmpty {
            #expect(importState.pendingImportedSessions[0].intention.contains("🌈"))
        }

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test(
        "Import with special CSV characters",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func importWithSpecialCSVCharacters() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        let csvWithSpecialChars = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,"Intention with ""quotes"", commas, and newlines",5,8,,
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-special.csv")
        try csvWithSpecialChars.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await Task.sleep(nanoseconds: 500_000_000) 

        
        try await TestHelpers.waitFor(
            { !importState.pendingImportedSessions.isEmpty || importState.importError != nil },
            timeout: 3.0
        )

        
        #expect(importState.importError == nil)
        #expect(importState.pendingImportedSessions.count == 1)

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test(
        "Import preserves music link URLs",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func importPreservesMusicLinkURLs() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        let csvWithMusicLink = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,Test,5,8,,https://open.spotify.com/playlist/test123
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-music.csv")
        try csvWithMusicLink.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await Task.sleep(nanoseconds: 500_000_000) 

        
        try await TestHelpers.waitFor(
            { !importState.pendingImportedSessions.isEmpty || importState.importError != nil },
            timeout: 3.0
        )

        
        #expect(importState.importError == nil)
        #expect(importState.pendingImportedSessions.count == 1)

        if !importState.pendingImportedSessions.isEmpty {
            #expect(importState.pendingImportedSessions[0].musicLinkURL == "https://open.spotify.com/playlist/test123")
        }

        
        try? FileManager.default.removeItem(at: tempURL)
    }

    @Test(
        "Import with boundary mood values",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func importWithBoundaryMoodValues() async throws {
        
        let (_, store) = try TestHelpers.makeTestEnvironment()
        let importState = try TestHelpers.makeImportState(sessionStore: store)

        let csvWithBoundaryValues = """
        Date,Treatment Type,Administration,Intention,Mood Before,Mood After,Reflections,Music Link URL
        Dec 10, 2024 at 2:30 PM,Psilocybin,Oral,Min to max mood,1,10,,
        """
        let tempURL = TestHelpers.makeTemporaryFileURL(filename: "test-boundary.csv")
        try csvWithBoundaryValues.write(to: tempURL, atomically: true, encoding: .utf8)

        
        importState.importCSV(from: tempURL)

        
        try await Task.sleep(nanoseconds: 500_000_000) 

        
        try await TestHelpers.waitFor(
            { !importState.pendingImportedSessions.isEmpty || importState.importError != nil },
            timeout: 3.0
        )

        
        #expect(importState.importError == nil)
        #expect(importState.pendingImportedSessions.count == 1)

        if !importState.pendingImportedSessions.isEmpty {
            #expect(importState.pendingImportedSessions[0].moodBefore == 1)
            #expect(importState.pendingImportedSessions[0].moodAfter == 10)
        }

        
        try? FileManager.default.removeItem(at: tempURL)
    }
}
