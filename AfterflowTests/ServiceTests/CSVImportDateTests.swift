@testable import Afterflow
import Foundation
import Testing

/// Date formats and day-first versus month-first slash dates.
@MainActor
struct CSVImportDateTests {
    private typealias Support = CSVImportTestSupport

    private func parsedDate(_ text: String, locale: Locale = CSVImportTestSupport.usLocale) -> Date? {
        let csv = "Date,Intention\n\"\(text)\",x"
        return try? CSVImportTestSupport.service(locale: locale).importDetailed(from: csv).sessions.first?.sessionDate
    }

    // MARK: - Export format and ISO 8601

    @Test("The Afterflow export format is read first") func exportFormat() {
        #expect(self.parsedDate("Dec 1, 2024 at 10:30 AM") == Support.localDate(2024, 12, 1, 10, 30))
        #expect(self.parsedDate("Dec 10, 2024 at 2:30 PM") == Support.localDate(2024, 12, 10, 14, 30))
    }

    @Test("A non-breaking space before AM/PM is accepted") func narrowNoBreakSpace() {
        #expect(self.parsedDate("Dec 1, 2024 at 10:30\u{202F}PM") == Support.localDate(2024, 12, 1, 22, 30))
    }

    @Test("ISO 8601 with a time zone keeps the exact instant") func isoWithTimeZone() {
        #expect(self.parsedDate("2024-12-01T10:30:00Z") == Support.utcDate("2024-12-01T10:30:00Z"))
        #expect(self.parsedDate("2024-12-01T10:30:00+02:00") == Support.utcDate("2024-12-01T08:30:00Z"))
    }

    @Test("ISO 8601 with fractional seconds is accepted") func isoFractionalSeconds() throws {
        let date = try #require(self.parsedDate("2024-12-01T10:30:00.500Z"))

        let expected = Support.utcDate("2024-12-01T10:30:00Z").timeIntervalSince1970 + 0.5
        #expect(abs(date.timeIntervalSince1970 - expected) < 0.01)
    }

    @Test("ISO 8601 without a time zone is read as local time") func isoWithoutTimeZone() {
        #expect(self.parsedDate("2024-12-01T10:30:15") == Support.localDate(2024, 12, 1, 10, 30, 15))
        #expect(self.parsedDate("2024-12-01T10:30") == Support.localDate(2024, 12, 1, 10, 30))
    }

    // MARK: - Numeric formats

    @Test("yyyy-MM-dd with and without a time") func dashedDates() {
        #expect(self.parsedDate("2024-12-01 10:30:45") == Support.localDate(2024, 12, 1, 10, 30, 45))
        #expect(self.parsedDate("2024-12-01 10:30") == Support.localDate(2024, 12, 1, 10, 30))
        #expect(self.parsedDate("2024-12-01") == Support.localDate(2024, 12, 1))
        #expect(self.parsedDate("2024-12-01 5:30 PM") == Support.localDate(2024, 12, 1, 17, 30))
    }

    @Test("Slash dates with and without a time") func slashDates() {
        #expect(self.parsedDate("12/25/2024 5:30 PM") == Support.localDate(2024, 12, 25, 17, 30))
        #expect(self.parsedDate("12/25/2024 5:30 pm") == Support.localDate(2024, 12, 25, 17, 30))
        #expect(self.parsedDate("12/25/2024 17:30") == Support.localDate(2024, 12, 25, 17, 30))
        #expect(self.parsedDate("12/25/2024 17:30:15") == Support.localDate(2024, 12, 25, 17, 30, 15))
        #expect(self.parsedDate("12/25/2024") == Support.localDate(2024, 12, 25))
        #expect(self.parsedDate("12/25/24") == Support.localDate(2024, 12, 25))
        #expect(self.parsedDate("1/2/2024") == Support.localDate(2024, 1, 2))
    }

    @Test("Ambiguous slash dates follow the locale") func ambiguousSlashDates() {
        let monthFirst = self.parsedDate("03/04/2024", locale: Support.usLocale)
        let dayFirst = self.parsedDate("03/04/2024", locale: Support.ukLocale)

        #expect(monthFirst == Support.localDate(2024, 3, 4))
        #expect(dayFirst == Support.localDate(2024, 4, 3))
    }

    @Test("Ambiguous slash dates with a time follow the locale") func ambiguousSlashDatesWithTime() {
        #expect(self.parsedDate("03/04/2024 14:15", locale: Support.usLocale) == Support.localDate(2024, 3, 4, 14, 15))
        #expect(self.parsedDate("03/04/2024 14:15", locale: Support.ukLocale) == Support.localDate(2024, 4, 3, 14, 15))
    }

    @Test("An impossible month falls back to the other order") func slashFallback() {
        #expect(self.parsedDate("25/12/2024", locale: Support.usLocale) == Support.localDate(2024, 12, 25))
        #expect(self.parsedDate("12/25/2024", locale: Support.ukLocale) == Support.localDate(2024, 12, 25))
    }

    // MARK: - Month names

    @Test("Month-name dates") func monthNames() {
        #expect(self.parsedDate("1 Dec 2024") == Support.localDate(2024, 12, 1))
        #expect(self.parsedDate("Dec 1, 2024") == Support.localDate(2024, 12, 1))
        #expect(self.parsedDate("December 1, 2024") == Support.localDate(2024, 12, 1))
        #expect(self.parsedDate("1 December 2024") == Support.localDate(2024, 12, 1))
        #expect(self.parsedDate("1 Dec 2024 10:30") == Support.localDate(2024, 12, 1, 10, 30))
        #expect(self.parsedDate("Dec 1, 2024 5:30 PM") == Support.localDate(2024, 12, 1, 17, 30))
    }

    @Test("Month names parse the same under a non-English device locale") func monthNamesIgnoreDeviceLocale() {
        let german = Locale(identifier: "de_DE")

        #expect(self.parsedDate("Dec 1, 2024", locale: german) == Support.localDate(2024, 12, 1))
        #expect(self.parsedDate("1 Dec 2024", locale: german) == Support.localDate(2024, 12, 1))
    }

    // MARK: - Rejections

    @Test("Unrecognised or impossible dates are not parsed") func unrecognisedDates() {
        for text in ["not a date", "2024-13-45", "13/13/2024", "2/30/2024", "yesterday"] {
            #expect(self.parsedDate(text) == nil)
        }
    }

    @Test("A time that no pattern understands is not silently dropped") func unsupportedTimeIsNotDropped() {
        #expect(self.parsedDate("1 Dec 2024 25:99") == nil)
    }
}
