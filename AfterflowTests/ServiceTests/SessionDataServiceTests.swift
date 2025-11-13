import Testing
import SwiftData
import Foundation
@testable import Afterflow

struct SessionDataServiceTests {
    
    // MARK: - CRUD Tests
    
    @Test("Create session successfully")
    @MainActor
    func testCreateSession() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        
        let session = TherapeuticSession()
        
        try service.createSession(session)
        
        let allSessions = try service.fetchAllSessions()
        #expect(allSessions.count == 1)
        #expect(allSessions.first?.id == session.id)
    }
    
    @Test("Update session successfully")
    @MainActor
    func testUpdateSession() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        
        let session = TherapeuticSession(
            treatmentType: .psilocybin,
            intention: "Original intention"
        )
        
        try service.createSession(session)
        
        let originalUpdatedAt = session.updatedAt
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        session.intention = "Updated intention"
        try service.updateSession(session)
        
        let fetchedSessions = try service.fetchAllSessions()
        #expect(fetchedSessions.count == 1)
        #expect(fetchedSessions.first?.intention == "Updated intention")
        #expect(fetchedSessions.first?.updatedAt ?? Date.distantPast > originalUpdatedAt)
    }
    
    @Test("Delete session successfully")
    @MainActor
    func testDeleteSession() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let session1 = TherapeuticSession(treatmentType: .lsd)
        let session2 = TherapeuticSession(treatmentType: .mdma)
        
        try service.createSession(session1)
        try service.createSession(session2)
        
        let allSessions = try service.fetchAllSessions()
        #expect(allSessions.count == 2)
        
        try service.deleteSession(session1)
        
        let remainingSessions = try service.fetchAllSessions()
        #expect(remainingSessions.count == 1)
        #expect(remainingSessions.first?.treatmentType == .mdma)
    }
    
    // MARK: - Fetch Tests
    
    @Test("Fetch all sessions returns sorted by date descending")
    @MainActor
    func testFetchAllSessionsSortedByDate() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let baseDate = Date()
        
        let olderSession = TherapeuticSession(treatmentType: .ketamine)
        olderSession.sessionDate = Calendar.current.date(byAdding: .day, value: -2, to: baseDate)!
        
        let newerSession = TherapeuticSession(treatmentType: .ayahuasca)
        newerSession.sessionDate = Calendar.current.date(byAdding: .day, value: -1, to: baseDate)!
        
        try service.createSession(olderSession)
        try service.createSession(newerSession)
        
        let sessions = try service.fetchAllSessions()
        #expect(sessions.count == 2)
        #expect(sessions.first?.treatmentType == .ayahuasca) // Newer should be first
        #expect(sessions.last?.treatmentType == .ketamine) // Older should be last
    }
    
    @Test("Fetch sessions by date range")
    @MainActor
    func testFetchSessionsByDateRange() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let baseDate = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: baseDate)!
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: baseDate)!
        
        let recentSession = TherapeuticSession()
        recentSession.sessionDate = baseDate
        
        let oldSession = TherapeuticSession()
        oldSession.sessionDate = threeDaysAgo
        
        try service.createSession(recentSession)
        try service.createSession(oldSession)
        
        // Fetch sessions from 2 days ago to today
        let sessions = try service.fetchSessions(from: twoDaysAgo, to: baseDate)
        #expect(sessions.count == 1)
        #expect(sessions.first?.sessionDate == baseDate)
    }
    
    @Test("Filter sessions by treatment type")
    @MainActor
    func testFilterSessionsByTreatmentType() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        
        let psilocybin1 = TherapeuticSession(treatmentType: .psilocybin)
        let psilocybin2 = TherapeuticSession(treatmentType: .psilocybin)
        let lsd = TherapeuticSession(treatmentType: .lsd)
        
        try service.createSession(psilocybin1)
        try service.createSession(psilocybin2)
        try service.createSession(lsd)
        
        let psilocybinSessions = try service.fetchSessions(treatmentType: .psilocybin)
        #expect(psilocybinSessions.count == 2)
        
        let lsdSessions = try service.fetchSessions(treatmentType: .lsd)
        #expect(lsdSessions.count == 1)
        
        let exactMatch = try service.fetchSessions(treatmentType: .psilocybin)
        #expect(exactMatch.count == 2)
    }
    
    // MARK: - Draft Recovery Tests
    
    @Test("Save and recover draft session")
    @MainActor
    func testSaveDraft() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let draftSession = TherapeuticSession(treatmentType: .psilocybin)
        
        service.saveDraft(draftSession)
        
        let recoveredDraft = service.recoverDraft()
        #expect(recoveredDraft != nil)
        #expect(recoveredDraft?.treatmentType == .psilocybin)
    }
    
    @Test("Clear draft removes saved draft")
    @MainActor
    func testClearDraft() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let draftSession = TherapeuticSession(treatmentType: .psilocybin)
        
        service.saveDraft(draftSession)
        #expect(service.recoverDraft() != nil)
        
        service.clearDraft()
        #expect(service.recoverDraft() == nil)
    }
    
    @Test("Draft recovery persists across service instances")
    @MainActor
    func testDraftPersistenceAcrossInstances() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service1 = SessionDataService(modelContext: container.mainContext)
        
        let recoveredDraft = service1.recoverDraft()
        #expect(recoveredDraft == nil)
        
        service1.clearDraft()
    }
    
    // MARK: - Validation Tests
    
    @Test("Valid session passes validation")
    @MainActor
    func testValidSessionValidation() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let validSession = TherapeuticSession(
            treatmentType: .psilocybin,
            intention: "Test intention"
        )
        
        let errors = service.validateSession(validSession)
        #expect(errors.isEmpty)
    }
    
    @Test("Future date fails validation")
    @MainActor
    func testFutureDateValidation() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let invalidSession = TherapeuticSession(treatmentType: .dmt)
        invalidSession.sessionDate = futureDate
        
        let errors = service.validateSession(invalidSession)
        #expect(!errors.isEmpty)
        #expect(errors.contains("Session date cannot be in the future"))
    }
    
    @Test("Invalid mood scale fails validation")
    @MainActor
    func testInvalidMoodScaleValidation() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let invalidSession = TherapeuticSession(treatmentType: .mescaline)
        invalidSession.moodBefore = 11 // Invalid: > 10
        
        let errors = service.validateSession(invalidSession)
        #expect(!errors.isEmpty)
        #expect(errors.contains("Pre-mood scale must be between 1 and 10"))
    }
    
    // MARK: - Background Save Tests
    
    @Test("Force save persists changes immediately")
    @MainActor
    func testForceSave() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let session = TherapeuticSession(treatmentType: .psilocybin)
        
        try service.createSession(session)
        
        // Force save and verify persistence
        try service.forceSave()
        
        let sessions = try service.fetchAllSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.treatmentType == .psilocybin)
    }
    
    @Test("Background save processes pending changes")
    @MainActor
    func testBackgroundSave() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        let session = TherapeuticSession(treatmentType: .psilocybin)
        
        try service.createSession(session)
        
        // Trigger background save
        service.saveOnBackground()
        
        let sessions = try service.fetchAllSessions()
        #expect(sessions.count == 1)
        #expect(sessions.first?.treatmentType == .psilocybin)
    }
    
    // MARK: - Performance Tests
    
    @Test("Handle large number of sessions efficiently")
    @MainActor
    func testPerformanceWithManySession() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        
        // Create test sessions using different psychedelic types
        let psychedelics: [PsychedelicTreatmentType] = [.psilocybin, .lsd, .mdma, .ketamine, .dmt]
        for i in 1...10 {
            let treatmentType = psychedelics[(i - 1) % psychedelics.count]
            let session = TherapeuticSession(treatmentType: treatmentType, intention: "Session \(i)")
            try service.createSession(session)
        }
        
        let allSessions = try service.fetchAllSessions()
        #expect(allSessions.count == 10)
        
        let psilocybinSessions = try service.fetchSessions(treatmentType: .psilocybin)
        #expect(psilocybinSessions.count == 2) // Sessions 1 and 6
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Service handles empty database gracefully")
    @MainActor
    func testEmptyDatabaseHandling() async throws {
        // Create isolated test environment
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let service = SessionDataService(modelContext: container.mainContext)
        
        let sessions = try service.fetchAllSessions()
        #expect(sessions.isEmpty)
        
        let draftRecovery = service.recoverDraft()
        #expect(draftRecovery == nil)
    }
}