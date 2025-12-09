@testable import Afterflow
import Foundation
import Testing

@MainActor
struct TherapeuticSessionTests {
    @Test("TherapeuticSession initialization with default values")
    func therapeuticSessionDefaultInitialization() async throws {
        let session = TherapeuticSession()

        #expect(session.id != UUID()) // Should have a unique ID
        #expect(session.treatmentType == .psilocybin) // Default value
        #expect(session.administration == .oral) // Default value
        #expect(session.intention == "")
        #expect(session.moodBefore == 5)
        #expect(session.moodAfter == 5)
        #expect(session.reflections == "")
        #expect(session.status == .draft)
        #expect(session.reminderDate == nil)
        #expect(session.musicLinkURL == nil)
        #expect(session.musicLinkWebURL == nil)
        #expect(session.musicLinkTitle == nil)
        #expect(session.musicLinkAuthorName == nil)
        #expect(session.musicLinkArtworkURL == nil)

        let now = Date()
        #expect(session.sessionDate.timeIntervalSince(now) < 1.0)
        #expect(session.createdAt.timeIntervalSince(now) < 1.0)
        #expect(session.updatedAt.timeIntervalSince(now) < 1.0)
    }

    @Test("TherapeuticSession initialization with custom values")
    func therapeuticSessionCustomInitialization() async throws {
        let customDate = Date(timeIntervalSinceNow: -3600) // 1 hour ago
        let reminderDate = Date().addingTimeInterval(3600)
        let session = TherapeuticSession(
            sessionDate: customDate,
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Healing trauma",
            moodBefore: 3,
            moodAfter: 8,
            reflections: "Profound insights",
            reminderDate: reminderDate
        )

        #expect(session.sessionDate == customDate)
        #expect(session.treatmentType == .psilocybin)
        #expect(session.administration == .oral)
        #expect(session.intention == "Healing trauma")
        #expect(session.moodBefore == 3)
        #expect(session.moodAfter == 8)
        #expect(session.reflections == "Profound insights")
        #expect(session.status == .complete)
        #expect(session.reminderDate == reminderDate)
    }

    @Test("Display title without treatment type") func displayTitleEmptyTreatmentType() async throws {
        let session = TherapeuticSession(treatmentType: .psilocybin)
        let expectedFormat = session.sessionDate.formatted(date: .abbreviated, time: .omitted)

        #expect(session.displayTitle == "Psilocybin • \(expectedFormat)")
    }

    @Test("Display title with treatment type") func displayTitleWithTreatmentType() async throws {
        let session = TherapeuticSession(treatmentType: .mdma)
        let expectedFormat = session.sessionDate.formatted(date: .abbreviated, time: .omitted)

        #expect(session.displayTitle == "MDMA • \(expectedFormat)")
    }

    @Test("Mood change calculation") func testMoodChange() async throws {
        let sessionImproved = TherapeuticSession(moodBefore: 4, moodAfter: 8)
        #expect(sessionImproved.moodChange == 4)

        let sessionDeclined = TherapeuticSession(moodBefore: 7, moodAfter: 5)
        #expect(sessionDeclined.moodChange == -2)

        let sessionUnchanged = TherapeuticSession(moodBefore: 6, moodAfter: 6)
        #expect(sessionUnchanged.moodChange == 0)
    }

    @Test("Music link detection") func testHasMusicLink() async throws {
        let sessionWithoutPlaylist = TherapeuticSession()
        #expect(sessionWithoutPlaylist.hasMusicLink == false)

        let sessionWithEmptyURI = TherapeuticSession()
        sessionWithEmptyURI.musicLinkURL = ""
        #expect(sessionWithEmptyURI.hasMusicLink == false)

        let sessionWithPlaylist = TherapeuticSession()
        sessionWithPlaylist.musicLinkURL = "https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M"
        #expect(sessionWithPlaylist.hasMusicLink == true)
    }

    @Test("Valid session validation") func validSessionValidation() async throws {
        let validSession = TherapeuticSession(
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Connect with inner wisdom",
            moodBefore: 5,
            moodAfter: 7
        )

        #expect(validSession.isValid == true)
    }

    @Test("Invalid session validation - empty intention") func invalidSessionEmptyIntention() async throws {
        let invalidSession = TherapeuticSession(
            treatmentType: .lsd,
            intention: "",
            moodBefore: 5,
            moodAfter: 7
        )

        #expect(invalidSession.isValid == false)
    }

    @Test("Invalid session validation - mood range") func invalidSessionMoodRange() async throws {
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

    @Test("Mark as updated changes timestamp") func testMarkAsUpdated() async throws {
        let session = TherapeuticSession()
        let originalUpdatedAt = session.updatedAt

        // Wait a tiny bit to ensure timestamp difference
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms

        session.markAsUpdated()

        #expect(session.updatedAt > originalUpdatedAt)
    }

    @Test("Clear music link data") func testClearMusicLinkData() async throws {
        let session = TherapeuticSession()
        session.musicLinkURL = "spotify:playlist:test"
        session.musicLinkWebURL = "https://open.spotify.com/playlist/test"
        session.musicLinkTitle = "Test Playlist"
        session.musicLinkAuthorName = "Afterflow"
        session.musicLinkArtworkURL = "https://example.com/image.jpg"
        session.musicLinkProvider = .spotify

        let originalUpdatedAt = session.updatedAt
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms

        session.clearMusicLinkData()

        #expect(session.musicLinkURL == nil)
        #expect(session.musicLinkWebURL == nil)
        #expect(session.musicLinkTitle == nil)
        #expect(session.musicLinkAuthorName == nil)
        #expect(session.musicLinkArtworkURL == nil)
        #expect(session.musicLinkProviderRawValue == nil)
        #expect(session.updatedAt > originalUpdatedAt)
    }

    @Test("Administration method enum values") func administrationMethodValues() async throws {
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

    @Test("Extreme mood values") func extremeMoodValues() async throws {
        let session = TherapeuticSession(moodBefore: 1, moodAfter: 10)

        #expect(session.moodBefore == 1)
        #expect(session.moodAfter == 10)
        #expect(session.moodChange == 9)
    }

    @Test("Long text fields") func longTextFields() async throws {
        let longText = String(repeating: "A", count: 1000)
        let session = TherapeuticSession(
            treatmentType: .psilocybin,
            administration: .oral,
            intention: longText,
            reflections: longText
        )

        #expect(session.treatmentType == .psilocybin)
        #expect(session.administration == .oral)
        #expect(session.intention.count == 1000)
        #expect(session.reflections.count == 1000)
        #expect(session.isValid == true) // Should still be valid
    }

    @Test("Unicode and special characters") func unicodeSupport() async throws {
        let session = TherapeuticSession(
            treatmentType: .mdma,
            administration: .oral,
            intention: "Найти покой и мудрость 🕉️",
            reflections: "Felt deep connection to the universe ✨"
        )

        #expect(session.isValid == true)
        #expect(session.treatmentType == .mdma)
        #expect(session.administration == .oral)
        #expect(session.intention.contains("🕉️"))
    }
}
