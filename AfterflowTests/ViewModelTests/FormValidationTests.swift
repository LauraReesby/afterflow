@testable import Afterflow
import Foundation
import Testing

@MainActor
struct FormValidationTests {
    // MARK: - Basic Validation Tests

    @Test("Valid intention passes validation") func validIntentionValidation() async throws {
        let validation = FormValidation()

        let result = validation.validateIntention("Connect with inner wisdom")

        #expect(result.isValid == true)
        #expect(result.message == nil)
    }

    @Test("Empty intention fails validation with therapeutic message") func emptyIntentionValidation() async throws {
        let validation = FormValidation()

        let result = validation.validateIntention("")

        #expect(result.isValid == false)
        #expect(result.message == "Please share what you hope to explore in this session")
    }

    @Test("Current date passes validation") func currentDateValidation() async throws {
        let validation = FormValidation()

        let result = validation.validateSessionDate(Date())

        #expect(result.isValid == true)
        #expect(result.message == nil)
    }

    @Test("Future date fails validation with therapeutic message") func futureDateValidation() async throws {
        let validation = FormValidation()
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let result = validation.validateSessionDate(futureDate)

        #expect(result.isValid == false)
        #expect(result.message == "Please choose a date from today or earlier")
    }

    @Test("Date within 1 hour future tolerance passes validation") func futureToleranceValidation() async throws {
        let validation = FormValidation()
        let nearFutureDate = Date().addingTimeInterval(30 * 60) // 30 minutes in future

        let result = validation.validateSessionDate(nearFutureDate)

        #expect(result.isValid == true)
        #expect(result.message == nil)
    }

    @Test("Very old date fails validation with therapeutic message") func veryOldDateValidation() async throws {
        let validation = FormValidation()
        let veryOldDate = Calendar.current.date(byAdding: .year, value: -15, to: Date())!

        let result = validation.validateSessionDate(veryOldDate)

        #expect(result.isValid == false)
        #expect(result.message?.contains("Please choose a date after") == true)
    }

    @Test("Date normalization rounds to nearest 15 minutes") func dateNormalization() async throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        // Test date with 7 minutes (should round down to 0)
        var components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 7)
        let testDate1 = calendar.date(from: components)!
        let normalized1 = validation.normalizeSessionDate(testDate1)
        let result1Components = calendar.dateComponents([.hour, .minute], from: normalized1)

        #expect(result1Components.hour == 14)
        #expect(result1Components.minute == 0)

        // Test date with 12 minutes (should round to 15)
        components.minute = 12
        let testDate2 = calendar.date(from: components)!
        let normalized2 = validation.normalizeSessionDate(testDate2)
        let result2Components = calendar.dateComponents([.hour, .minute], from: normalized2)

        #expect(result2Components.hour == 14)
        #expect(result2Components.minute == 15)
    }

    @Test("Date normalization message appears for significant changes") func dateNormalizationMessage() async throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        // Create a date that will be significantly normalized
        let components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 7)
        let originalDate = calendar.date(from: components)!
        let normalizedDate = validation.normalizeSessionDate(originalDate)

        let message = validation.getDateNormalizationMessage(originalDate: originalDate, normalizedDate: normalizedDate)

        // Should provide a helpful message for significant changes
        #expect(message?.contains("Time adjusted") == true)
    }

    @Test("No normalization message for minor changes") func noNormalizationMessageForMinorChanges() async throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        // Create a date that's already on a 15-minute boundary
        let components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 15)
        let originalDate = calendar.date(from: components)!
        let normalizedDate = validation.normalizeSessionDate(originalDate)

        let message = validation.getDateNormalizationMessage(originalDate: originalDate, normalizedDate: normalizedDate)

        // Should not provide message for dates that don't change significantly
        #expect(message == nil)
    }

    @Test("Empty dosage passes validation (optional field)") func emptyDosageValidation() async throws {
        let validation = FormValidation()

        let result = validation.validateDosage("")

        #expect(result.isValid == true)
        #expect(result.message == nil)
    }

    @Test("Valid dosage passes validation") func validDosageValidation() async throws {
        let validation = FormValidation()

        let result = validation.validateDosage("3.5g")

        #expect(result.isValid == true)
        #expect(result.message == nil)
    }

    @Test("Extremely long dosage shows gentle guidance") func longDosageValidation() async throws {
        let validation = FormValidation()
        let longDosage = String(repeating: "very long dosage description ", count: 10)

        let result = validation.validateDosage(longDosage)

        #expect(result.isValid == false)
        #expect(result.message == "Please keep dosage brief for easier tracking")
    }

    // MARK: - Form Data Tests

    @Test("Valid complete form passes validation") func completeFormValidation() async throws {
        let validation = FormValidation()

        let formData = SessionFormData(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            dosage: "3.5g",
            administration: .oral,
            intention: "Connect with inner wisdom"
        )

        let result = validation.validateForm(formData)

        #expect(result.isValid == true)
        #expect(result.errors.isEmpty)
    }

    // MARK: - Therapeutic Tone Tests

    @Test("All error messages use therapeutic tone") func therapeuticTone() async throws {
        let validation = FormValidation()

        // Test all validation messages for therapeutic tone
        let intentionResult = validation.validateIntention("")
        let dateResult = validation.validateSessionDate(Date().addingTimeInterval(86400))
        let dosageResult = validation.validateDosage(String(repeating: "x", count: 200))

        // Messages should be gentle and supportive
        let messages = [
            intentionResult.message,
            dateResult.message,
            dosageResult.message
        ].compactMap { $0 }

        for message in messages {
            // Should use "please" (gentle)
            #expect(message.lowercased().contains("please"))

            // Should not use harsh language
            #expect(!message.lowercased().contains("error"))
            #expect(!message.lowercased().contains("invalid"))
            #expect(!message.lowercased().contains("wrong"))
            #expect(!message.lowercased().contains("failed"))
        }
    }
}
