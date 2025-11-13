//  Constitutional Compliance: Test-Driven Quality, Privacy-First

import Testing
import Foundation
@testable import Afterflow

struct TherapeuticSessionTests {
    
    // MARK: - Initialization Tests
    
    @Test("TherapeuticSession initialization with default values")
    func testTherapeuticSessionDefaultInitialization() async throws {
        let session = TherapeuticSession()
        
        #expect(session.id != UUID()) // Should have a unique ID
        #expect(session.treatmentType == .psilocybin) // Default value
        #expect(session.administration == .oral) // Default value
        #expect(session.dosage == "")
        #expect(session.intention == "")
        #expect(session.environmentNotes == "")
        #expect(session.musicNotes == "")
        #expect(session.moodBefore == 5)
        #expect(session.moodAfter == 5)
        #expect(session.reflections == "")
        #expect(session.spotifyPlaylistURI == nil)
        #expect(session.spotifyPlaylistName == nil)
        #expect(session.spotifyPlaylistImageURL == nil)
        
        // Dates should be recent (within 1 second)
        let now = Date()
        #expect(session.sessionDate.timeIntervalSince(now) < 1.0)
        #expect(session.createdAt.timeIntervalSince(now) < 1.0)
        #expect(session.updatedAt.timeIntervalSince(now) < 1.0)
    }
    
    @Test("TherapeuticSession initialization with custom values")
    func testTherapeuticSessionCustomInitialization() async throws {
        let customDate = Date(timeIntervalSinceNow: -3600) // 1 hour ago
        let session = TherapeuticSession(
            sessionDate: customDate,
            treatmentType: .psilocybin,
            dosage: "3.5g dried",
            administration: .oral,
            intention: "Healing trauma",
            environmentNotes: "Peaceful garden",
            musicNotes: "Nature sounds",
            moodBefore: 3,
            moodAfter: 8,
            reflections: "Profound insights"
        )
        
        #expect(session.sessionDate == customDate)
        #expect(session.treatmentType == .psilocybin)
        #expect(session.administration == .oral)
        #expect(session.dosage == "3.5g dried")
        #expect(session.intention == "Healing trauma")
        #expect(session.environmentNotes == "Peaceful garden")
        #expect(session.musicNotes == "Nature sounds")
        #expect(session.moodBefore == 3)
        #expect(session.moodAfter == 8)
        #expect(session.reflections == "Profound insights")
    }
    
    // MARK: - Computed Properties Tests
    
    @Test("Display title without treatment type")
    func testDisplayTitleEmptyTreatmentType() async throws {
        let session = TherapeuticSession(treatmentType: .psilocybin)
        let expectedFormat = session.sessionDate.formatted(date: .abbreviated, time: .omitted)
        
        #expect(session.displayTitle == "Psilocybin • \(expectedFormat)")
    }
    
    @Test("Display title with treatment type")
    func testDisplayTitleWithTreatmentType() async throws {
        let session = TherapeuticSession(treatmentType: .mdma)
        let expectedFormat = session.sessionDate.formatted(date: .abbreviated, time: .omitted)
        
        #expect(session.displayTitle == "MDMA • \(expectedFormat)")
    }
    
    @Test("Mood change calculation")
    func testMoodChange() async throws {
        let sessionImproved = TherapeuticSession(moodBefore: 4, moodAfter: 8)
        #expect(sessionImproved.moodChange == 4)
        
        let sessionDeclined = TherapeuticSession(moodBefore: 7, moodAfter: 5)
        #expect(sessionDeclined.moodChange == -2)
        
        let sessionUnchanged = TherapeuticSession(moodBefore: 6, moodAfter: 6)
        #expect(sessionUnchanged.moodChange == 0)
    }
    
    @Test("Spotify playlist detection")
    func testHasSpotifyPlaylist() async throws {
        let sessionWithoutPlaylist = TherapeuticSession()
        #expect(sessionWithoutPlaylist.hasSpotifyPlaylist == false)
        
        let sessionWithEmptyURI = TherapeuticSession()
        sessionWithEmptyURI.spotifyPlaylistURI = ""
        #expect(sessionWithEmptyURI.hasSpotifyPlaylist == false)
        
        let sessionWithPlaylist = TherapeuticSession()
        sessionWithPlaylist.spotifyPlaylistURI = "spotify:playlist:37i9dQZF1DXcBWIGoYBM5M"
        #expect(sessionWithPlaylist.hasSpotifyPlaylist == true)
    }
    
    // MARK: - Validation Tests
    
    @Test("Valid session validation")
    func testValidSessionValidation() async throws {
        let validSession = TherapeuticSession(
            treatmentType: .psilocybin,
            dosage: "3.5g",
            administration: .oral,
            intention: "Connect with inner wisdom",
            moodBefore: 5,
            moodAfter: 7
        )
        
        #expect(validSession.isValid == true)
    }
    
    @Test("Invalid session validation - empty intention")
    func testInvalidSessionEmptyIntention() async throws {
        let invalidSession = TherapeuticSession(
            treatmentType: .lsd,
            intention: "",
            moodBefore: 5,
            moodAfter: 7
        )
        
        #expect(invalidSession.isValid == false)
    }
    
    @Test("Invalid session validation - mood range")
    func testInvalidSessionMoodRange() async throws {
        let invalidMoodBefore = TherapeuticSession(
            treatmentType: .ketamine,
            intention: "Valid intention",
            moodBefore: 0, // Below valid range
            moodAfter: 7
        )
        #expect(invalidMoodBefore.isValid == false)
        
        let invalidMoodAfter = TherapeuticSession(
            treatmentType: .cannabis,
            intention: "Valid intention",
            moodBefore: 5,
            moodAfter: 11 // Above valid range
        )
        #expect(invalidMoodAfter.isValid == false)
    }
    
    // MARK: - Data Management Tests
    
    @Test("Mark as updated changes timestamp")
    func testMarkAsUpdated() async throws {
        let session = TherapeuticSession()
        let originalUpdatedAt = session.updatedAt
        
        // Wait a tiny bit to ensure timestamp difference
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        session.markAsUpdated()
        
        #expect(session.updatedAt > originalUpdatedAt)
    }
    
    @Test("Clear Spotify data")
    func testClearSpotifyData() async throws {
        let session = TherapeuticSession()
        session.spotifyPlaylistURI = "spotify:playlist:test"
        session.spotifyPlaylistName = "Test Playlist"
        session.spotifyPlaylistImageURL = "https://example.com/image.jpg"
        
        let originalUpdatedAt = session.updatedAt
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        session.clearSpotifyData()
        
        #expect(session.spotifyPlaylistURI == nil)
        #expect(session.spotifyPlaylistName == nil)
        #expect(session.spotifyPlaylistImageURL == nil)
        #expect(session.updatedAt > originalUpdatedAt)
    }
    
    // MARK: - Administration Method Tests
    
    @Test("Administration method enum values")
    func testAdministrationMethodValues() async throws {
        let sessionIV = TherapeuticSession(treatmentType: .ketamine, administration: .intravenous)
        #expect(sessionIV.administration == .intravenous)
        
        let sessionIM = TherapeuticSession(treatmentType: .ketamine, administration: .intramuscular)
        #expect(sessionIM.administration == .intramuscular)
        
        let sessionOral = TherapeuticSession(treatmentType: .psilocybin, administration: .oral)
        #expect(sessionOral.administration == .oral)
        
        let sessionNasal = TherapeuticSession(treatmentType: .ketamine, administration: .nasal)
        #expect(sessionNasal.administration == .nasal)
        
        let sessionOther = TherapeuticSession(treatmentType: .dmt, administration: .other)
        #expect(sessionOther.administration == .other)
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Extreme mood values")
    func testExtremeMoodValues() async throws {
        let session = TherapeuticSession(moodBefore: 1, moodAfter: 10)
        
        #expect(session.moodBefore == 1)
        #expect(session.moodAfter == 10)
        #expect(session.moodChange == 9)
    }
    
    @Test("Long text fields")
    func testLongTextFields() async throws {
        let longText = String(repeating: "A", count: 1000)
        let session = TherapeuticSession(
            treatmentType: .psilocybin, // Use valid psychedelic
            dosage: "3.5g",
            administration: .oral,
            intention: longText,
            environmentNotes: longText,
            musicNotes: longText,
            reflections: longText
        )
        
        #expect(session.treatmentType == .psilocybin)
        #expect(session.administration == .oral)
        #expect(session.intention.count == 1000)
        #expect(session.environmentNotes.count == 1000)
        #expect(session.musicNotes.count == 1000)
        #expect(session.reflections.count == 1000)
        #expect(session.isValid == true) // Should still be valid
    }
    
    @Test("Unicode and special characters")
    func testUnicodeSupport() async throws {
        let session = TherapeuticSession(
            treatmentType: .mdma,
            dosage: "120mg",
            administration: .oral,
            intention: "Найти покой и мудрость 🕉️",
            environmentNotes: "Beautiful zen garden with 🌸 sakura trees",
            musicNotes: "Tibetan singing bowls 🎵",
            reflections: "Felt deep connection to the universe ✨"
        )
        
        #expect(session.isValid == true)
        #expect(session.treatmentType == .mdma)
        #expect(session.administration == .oral)
        #expect(session.intention.contains("🕉️"))
    }
}