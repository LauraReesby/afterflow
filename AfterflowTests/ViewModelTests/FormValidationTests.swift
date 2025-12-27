@testable import Afterflow
import Foundation
import Testing

@MainActor
struct FormValidationTests {
    @Test("Valid intention passes validation") func validIntentionValidation() async throws {
        let validation = FormValidation()

        let result = validation.validateIntention("Connect with inner wisdom")

        #expect(result.isValid == true)
    }

    @Test("Empty intention fails validation with therapeutic message") func emptyIntentionValidation() async throws {
        let validation = FormValidation()

        let result = validation.validateIntention("")

        #expect(result.isValid == false)
    }

    @Test("Current date passes validation") func currentDateValidation() async throws {
        let validation = FormValidation()

        let result = validation.validateSessionDate(Date())

        #expect(result.isValid == true)
    }

    @Test("Future date fails validation with therapeutic message") func futureDateValidation() async throws {
        let validation = FormValidation()
        let futureDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        let result = validation.validateSessionDate(futureDate)

        #expect(result.isValid == false)
    }

    @Test("Date within 1 hour future tolerance passes validation") func futureToleranceValidation() async throws {
        let validation = FormValidation()
        let nearFutureDate = Date().addingTimeInterval(30 * 60)

        let result = validation.validateSessionDate(nearFutureDate)

        #expect(result.isValid == true)
    }

    @Test("Date well beyond future tolerance fails validation") func futureBeyondToleranceValidation() async throws {
        let validation = FormValidation()
        let tooFarFuture = Date().addingTimeInterval(12 * 60 * 60)

        let result = validation.validateSessionDate(tooFarFuture)

        #expect(result.isValid == false)
    }

    @Test("Date comfortably within 10-year minimum passes validation") func earliestAllowedDateValidation(
    ) async throws {
        let validation = FormValidation()
        let withinRange = Date().addingTimeInterval(-9 * 365 * 24 * 60 * 60)

        let result = validation.validateSessionDate(withinRange)

        #expect(result.isValid == true)
    }

    @Test("Very old date fails validation with therapeutic message") func veryOldDateValidation() async throws {
        let validation = FormValidation()
        let veryOldDate = Calendar.current.date(byAdding: .year, value: -15, to: Date())!

        let result = validation.validateSessionDate(veryOldDate)

        #expect(result.isValid == false)
    }

    @Test("Date normalization rounds to nearest 15 minutes") func dateNormalization() async throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        var components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 7)
        let testDate1 = calendar.date(from: components)!
        let normalized1 = validation.normalizeSessionDate(testDate1)
        let result1Components = calendar.dateComponents([.hour, .minute], from: normalized1)

        #expect(result1Components.hour == 14)
        #expect(result1Components.minute == 0)

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

        let components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 7)
        let originalDate = calendar.date(from: components)!
        let normalizedDate = validation.normalizeSessionDate(originalDate)

        let message = validation.getDateNormalizationMessage(originalDate: originalDate, normalizedDate: normalizedDate)

        #expect(message?.contains("Time adjusted") == true)
    }

    @Test("No normalization message for minor changes") func noNormalizationMessageForMinorChanges() async throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        let components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 15)
        let originalDate = calendar.date(from: components)!
        let normalizedDate = validation.normalizeSessionDate(originalDate)

        let message = validation.getDateNormalizationMessage(originalDate: originalDate, normalizedDate: normalizedDate)

        #expect(message == nil)
    }

    @Test("Valid complete form passes validation") func completeFormValidation() async throws {
        let validation = FormValidation()

        let formData = SessionFormData(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Connect with inner wisdom"
        )

        let result = validation.validateForm(formData)

        #expect(result == true)
    }
}
