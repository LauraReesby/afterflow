@testable import Afterflow
import Foundation
import Testing

@MainActor
struct FormValidationTests {
    @Test("Valid intention passes validation") func validIntentionValidation() {
        let validation = FormValidation()

        let result = validation.validateIntention("Connect with inner wisdom")

        #expect(result.isValid == true)
    }

    @Test("Empty intention fails validation with therapeutic message") func emptyIntentionValidation() {
        let validation = FormValidation()

        let result = validation.validateIntention("")

        #expect(result.isValid == false)
    }

    @Test("Current date passes validation") func currentDateValidation() {
        let validation = FormValidation()

        let result = validation.validateSessionDate(Date())

        #expect(result.isValid == true)
    }

    @Test("Future date fails validation with therapeutic message") func futureDateValidation() throws {
        let validation = FormValidation()
        let futureDate = try #require(Calendar.current.date(byAdding: .day, value: 1, to: Date()))

        let result = validation.validateSessionDate(futureDate)

        #expect(result.isValid == false)
    }

    @Test("Date within 1 hour future tolerance passes validation") func futureToleranceValidation() {
        let validation = FormValidation()
        let nearFutureDate = Date().addingTimeInterval(30 * 60)

        let result = validation.validateSessionDate(nearFutureDate)

        #expect(result.isValid == true)
    }

    @Test("Date well beyond future tolerance fails validation") func futureBeyondToleranceValidation() {
        let validation = FormValidation()
        let tooFarFuture = Date().addingTimeInterval(12 * 60 * 60)

        let result = validation.validateSessionDate(tooFarFuture)

        #expect(result.isValid == false)
    }

    @Test("Date comfortably within 10-year minimum passes validation") func earliestAllowedDateValidation() {
        let validation = FormValidation()
        let withinRange = Date().addingTimeInterval(-9 * 365 * 24 * 60 * 60)

        let result = validation.validateSessionDate(withinRange)

        #expect(result.isValid == true)
    }

    @Test("Very old date fails validation with therapeutic message") func veryOldDateValidation() throws {
        let validation = FormValidation()
        let veryOldDate = try #require(Calendar.current.date(byAdding: .year, value: -15, to: Date()))

        let result = validation.validateSessionDate(veryOldDate)

        #expect(result.isValid == false)
    }

    @Test("Date normalization rounds to nearest 15 minutes") func dateNormalization() throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        var components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 7)
        let testDate1 = try #require(calendar.date(from: components))
        let normalized1 = validation.normalizeSessionDate(testDate1)
        let result1Components = calendar.dateComponents([.hour, .minute], from: normalized1)

        #expect(result1Components.hour == 14)
        #expect(result1Components.minute == 0)

        components.minute = 12
        let testDate2 = try #require(calendar.date(from: components))
        let normalized2 = validation.normalizeSessionDate(testDate2)
        let result2Components = calendar.dateComponents([.hour, .minute], from: normalized2)

        #expect(result2Components.hour == 14)
        #expect(result2Components.minute == 15)
    }

    @Test("Rounding up past the hour rolls the day, month, and year forward")
    func dateNormalizationBoundaryRollover() throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        // Regression: 23:53+ used to wrap the hour to 0 without advancing the
        // day, silently moving the session back ~24 hours.
        let lateNight = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 13,
            hour: 23,
            minute: 55
        )))
        let nextDay = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: validation.normalizeSessionDate(lateNight)
        )
        #expect(nextDay.year == 2026)
        #expect(nextDay.month == 8)
        #expect(nextDay.day == 14)
        #expect(nextDay.hour == 0)
        #expect(nextDay.minute == 0)

        // Month boundary
        let monthEnd = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 31,
            hour: 23,
            minute: 58
        )))
        let nextMonth = calendar.dateComponents(
            [.year, .month, .day, .hour],
            from: validation.normalizeSessionDate(monthEnd)
        )
        #expect(nextMonth.month == 9)
        #expect(nextMonth.day == 1)
        #expect(nextMonth.hour == 0)

        // Year boundary
        let yearEnd = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 12,
            day: 31,
            hour: 23,
            minute: 59
        )))
        let nextYear = calendar.dateComponents(
            [.year, .month, .day, .hour],
            from: validation.normalizeSessionDate(yearEnd)
        )
        #expect(nextYear.year == 2027)
        #expect(nextYear.month == 1)
        #expect(nextYear.day == 1)
        #expect(nextYear.hour == 0)

        // Mid-day hour rollover keeps the same day
        let midDay = try #require(calendar.date(from: DateComponents(
            year: 2026,
            month: 8,
            day: 13,
            hour: 14,
            minute: 53
        )))
        let nextHour = calendar.dateComponents(
            [.day, .hour, .minute],
            from: validation.normalizeSessionDate(midDay)
        )
        #expect(nextHour.day == 13)
        #expect(nextHour.hour == 15)
        #expect(nextHour.minute == 0)
    }

    @Test("Date normalization message appears for significant changes") func dateNormalizationMessage() throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        let components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 7)
        let originalDate = try #require(calendar.date(from: components))
        let normalizedDate = validation.normalizeSessionDate(originalDate)

        let message = validation.getDateNormalizationMessage(originalDate: originalDate, normalizedDate: normalizedDate)

        #expect(message?.contains("Time adjusted") == true)
    }

    @Test("No normalization message for minor changes") func noNormalizationMessageForMinorChanges() throws {
        let validation = FormValidation()
        let calendar = Calendar.current

        let components = DateComponents(year: 2024, month: 11, day: 13, hour: 14, minute: 15)
        let originalDate = try #require(calendar.date(from: components))
        let normalizedDate = validation.normalizeSessionDate(originalDate)

        let message = validation.getDateNormalizationMessage(originalDate: originalDate, normalizedDate: normalizedDate)

        #expect(message == nil)
    }

    @Test("Valid complete form passes validation") func completeFormValidation() {
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
