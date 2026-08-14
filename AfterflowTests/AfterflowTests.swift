@testable import Afterflow
import Testing

struct AfterflowSmokeTests {
    @Test("TherapeuticSession instances have unique identifiers") func therapeuticSessionIdentity() {
        let firstSession = TherapeuticSession()
        let secondSession = TherapeuticSession()

        #expect(firstSession.id != secondSession.id)
    }

    @Test("TherapeuticSession defaults honor therapeutic tone") func defaultIntentionIsEmpty() {
        let session = TherapeuticSession()

        #expect(session.intention.isEmpty)
        #expect(session.moodBefore == 5)
        #expect(session.moodAfter == nil)
    }
}
