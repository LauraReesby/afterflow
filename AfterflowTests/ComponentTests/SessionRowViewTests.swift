@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct SessionRowViewTests {
    // MARK: - Basic Display Tests

    @Test("Displays treatment type") func displaysTreatmentType() throws {
        // Arrange
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.treatmentType == .psilocybin)
        #expect(rowView.session.treatmentType.displayName == "Psilocybin")
    }

    @Test("Displays date text") func displaysDateText() throws {
        // Arrange
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

        // Act
        let rowView = SessionRowView(session: session, dateText: dateText)

        // Assert
        #expect(rowView.dateText == "Yesterday")
    }

    @Test("Displays intention text") func displaysIntention() throws {
        // Arrange
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.intention == "Explore creativity and connection")
        #expect(!rowView.session.intention.isEmpty)
    }

    @Test("Empty intention handled gracefully") func emptyIntentionHandled() throws {
        // Arrange
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.intention.isEmpty)
        // View should handle empty intention gracefully (UI logic)
    }

    // MARK: - Status Badge Tests

    @Test("Needs reflection status shown") func needsReflectionStatusShown() throws {
        // Arrange - Create session that needs reflection
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Test intention",
            moodBefore: 5,
            moodAfter: 8,
            reflections: "", // Empty reflections = needs reflection
            reminderDate: nil
        )

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.status == .needsReflection)
    }

    @Test("Complete status shown") func completeStatusShown() throws {
        // Arrange - Create completed session
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.status == .complete)
        #expect(!rowView.session.reflections.isEmpty)
    }

    @Test("Draft status handled") func draftStatusHandled() throws {
        // Arrange - Create draft session (empty intention)
        let session = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ayahuasca,
            administration: .oral,
            intention: "", // Empty intention = draft
            moodBefore: 5,
            moodAfter: 8,
            reflections: "",
            reminderDate: nil
        )

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.status == .draft)
    }

    // MARK: - Reminder Label Tests

    @Test("Reminder label shown when present") func reminderLabelShownWhenPresent() throws {
        // Arrange - Create session with future reminder
        let futureDate = Date().addingTimeInterval(3600) // 1 hour in future
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.reminderDate != nil)
        #expect(rowView.session.reminderRelativeDescription != nil)
    }

    @Test("Reminder label hidden for past reminders") func reminderLabelHiddenForPastReminders() throws {
        // Arrange - Create session with past reminder
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour in past
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.reminderDate != nil)
        // Past reminders should have nil relative description
        #expect(rowView.session.reminderRelativeDescription == nil)
    }

    @Test("Reminder label nil when no reminder") func reminderLabelNilWhenNoReminder() throws {
        // Arrange
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.reminderDate == nil)
        #expect(rowView.session.reminderRelativeDescription == nil)
    }

    // MARK: - Treatment Type Coverage Tests

    @Test("All treatment types display correctly") func allTreatmentTypesDisplayCorrectly() throws {
        // Arrange & Act & Assert
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

    // MARK: - Date Text Variations

    @Test("Various date text formats handled") func variousDateTextFormatsHandled() throws {
        // Arrange
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

        // Act & Assert
        for dateText in dateTexts {
            let rowView = SessionRowView(session: session, dateText: dateText)
            #expect(rowView.dateText == dateText)
        }
    }

    // MARK: - Edge Cases

    @Test("Long intention text handled") func longIntentionTextHandled() throws {
        // Arrange
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.intention == longIntention)
        #expect(rowView.session.intention.count > 100)
    }

    @Test("Unicode in intention displayed correctly") func unicodeInIntentionDisplayedCorrectly() throws {
        // Arrange
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today")

        // Assert
        #expect(rowView.session.intention == unicodeIntention)
        #expect(rowView.session.intention.contains("🌈"))
    }

    @Test("Session with all fields populated") func sessionWithAllFieldsPopulated() throws {
        // Arrange
        let futureReminder = Date().addingTimeInterval(7200) // 2 hours
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

        // Act
        let rowView = SessionRowView(session: session, dateText: "Today at 2:30 PM")

        // Assert
        #expect(rowView.session.treatmentType == .psilocybin)
        #expect(!rowView.session.intention.isEmpty)
        #expect(rowView.session.status == .complete)
        #expect(rowView.session.reminderDate != nil)
        #expect(rowView.dateText.contains("Today"))
    }
}
