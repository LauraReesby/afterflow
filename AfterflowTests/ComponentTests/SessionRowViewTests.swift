@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct SessionRowViewTests {
    

    @Test("Displays treatment type") func displaysTreatmentType() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test intention",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.treatmentType == .psilocybin)
        #expect(rowView.session.treatmentType.displayName == "Psilocybin")
    }

    @Test("Displays date text") func displaysDateText() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .mdma,
            administration: .oral,
            intention: "Test",
            moodBefore: 4,
            moodAfter: 9,
            reflections: "",
            reminderDate: nil
        )
        let dateText = "Yesterday"

        
        let rowView = SessionRowView(session: session, dateText: dateText)

        
        #expect(rowView.dateText == "Yesterday")
    }

    @Test("Displays intention text") func displaysIntention() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .lsd,
            administration: .oral,
            intention: "Explore creativity and connection",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.intention == "Explore creativity and connection")
        #expect(!rowView.session.intention.isEmpty)
    }

    @Test("Empty intention handled gracefully") func emptyIntentionHandled() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ketamine,
            administration: .oral,
            intention: "",
            moodBefore: 3,
            moodAfter: 7,
            reflections: "",
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.intention.isEmpty)
        
    }

    

    @Test("Needs reflection status shown") func needsReflectionStatusShown() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test intention",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "", 
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.status == .needsReflection)
    }

    @Test("Complete status shown") func completeStatusShown() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .mdma,
            administration: .oral,
            intention: "Test intention",
            moodBefore: 4,
            moodAfter: 9,
            reflections: "Session was profound and healing",
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.status == .complete)
        #expect(!rowView.session.reflections.isEmpty)
    }

    @Test("Draft status handled") func draftStatusHandled() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ayahuasca,
            administration: .oral,
            intention: "", 
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.status == .draft)
    }

    

    @Test("Reminder label shown when present") func reminderLabelShownWhenPresent() throws {
        
        let futureDate = Date().addingTimeInterval(3600) 
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test intention",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: futureDate
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.reminderDate != nil)
        #expect(rowView.session.reminderRelativeDescription != nil)
    }

    @Test("Reminder label hidden for past reminders") func reminderLabelHiddenForPastReminders() throws {
        
        let pastDate = Date().addingTimeInterval(-3600) 
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .lsd,
            administration: .oral,
            intention: "Test intention",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: pastDate
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.reminderDate != nil)
        
        #expect(rowView.session.reminderRelativeDescription == nil)
    }

    @Test("Reminder label nil when no reminder") func reminderLabelNilWhenNoReminder() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ketamine,
            administration: .oral,
            intention: "Test intention",
            moodBefore: 3,
            moodAfter: 7,
            reflections: "",
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.reminderDate == nil)
        #expect(rowView.session.reminderRelativeDescription == nil)
    }

    

    @Test("All treatment types display correctly") func allTreatmentTypesDisplayCorrectly() throws {
        
        for treatmentType in PsychedelicTreatmentType.allCases {
            let session = TherapeuticSession(
                sessionDate: Date(),
                treatmentType: treatmentType,
                administration: .oral,
                intention: "Test",
                moodBefore: 5,
                moodAfter: 8,
                reflections: "",
                reminderDate: nil
            )

            let rowView = SessionRowView(session: session, dateText: "Today")

            #expect(rowView.session.treatmentType == treatmentType)
            #expect(!rowView.session.treatmentType.displayName.isEmpty)
        }
    }

    

    @Test("Various date text formats handled") func variousDateTextFormatsHandled() throws {
        
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .cannabis,
            administration: .oral,
            intention: "Test",
            moodBefore: 6,
            moodAfter: 7,
            reflections: "",
            reminderDate: nil
        )

        let dateTexts = ["Today", "Yesterday", "2 days ago", "Dec 25, 2024", "Last week"]

        
        for dateText in dateTexts {
            let rowView = SessionRowView(session: session, dateText: dateText)
            #expect(rowView.dateText == dateText)
        }
    }

    

    @Test("Long intention text handled") func longIntentionTextHandled() throws {
        
        let longIntention = String(repeating: "Long intention text with many words. ", count: 10)
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .dmt,
            administration: .oral,
            intention: longIntention,
            moodBefore: 5,
            moodAfter: 10,
            reflections: "",
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.intention == longIntention)
        #expect(rowView.session.intention.count > 100)
    }

    @Test("Unicode in intention displayed correctly") func unicodeInIntentionDisplayedCorrectly() throws {
        
        let unicodeIntention = "Explore creativity 🌈✨ with émotions françaises and 日本語"
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .mescaline,
            administration: .oral,
            intention: unicodeIntention,
            moodBefore: 4,
            moodAfter: 9,
            reflections: "",
            reminderDate: nil
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today")

        
        #expect(rowView.session.intention == unicodeIntention)
        #expect(rowView.session.intention.contains("🌈"))
    }

    @Test("Session with all fields populated") func sessionWithAllFieldsPopulated() throws {
        
        let futureReminder = Date().addingTimeInterval(7200) 
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Deep healing and self-discovery",
            moodBefore: 3,
            moodAfter: 9,
            reflections: "Profound experience",
            reminderDate: futureReminder
        )

        
        let rowView = SessionRowView(session: session, dateText: "Today at 2:30 PM")

        
        #expect(rowView.session.treatmentType == .psilocybin)
        #expect(!rowView.session.intention.isEmpty)
        #expect(rowView.session.status == .complete)
        #expect(rowView.session.reminderDate != nil)
        #expect(rowView.dateText.contains("Today"))
    }
}
