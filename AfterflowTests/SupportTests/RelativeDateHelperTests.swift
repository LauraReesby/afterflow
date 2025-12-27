@testable import Afterflow
import Foundation
import Testing

@Suite("RelativeDateHelper Tests")
struct RelativeDateHelperTests {
    // MARK: - Basic Functionality

    @Test("Today's date returns 'Today'") func todayReturnsToday() {
        let now = Date()
        #expect(now.relativeSessionLabel == "Today")
    }

    @Test("Yesterday's date returns 'Yesterday'") func yesterdayReturnsYesterday() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        #expect(yesterday.relativeSessionLabel == "Yesterday")
    }

    @Test("Older dates return MM/dd/yy format") func olderDatesReturnFormattedDate() {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        let label = twoDaysAgo.relativeSessionLabel

        // Should match MM/dd/yy format (e.g., "12/24/25")
        let pattern = #"^\d{2}/\d{2}/\d{2}$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(label.startIndex..., in: label)
        #expect(regex.firstMatch(in: label, range: range) != nil)
    }

    @Test("Two weeks ago returns formatted date") func twoWeeksAgoReturnsFormattedDate() {
        let calendar = Calendar.current
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!
        let label = twoWeeksAgo.relativeSessionLabel

        // Should not be "Today" or "Yesterday"
        #expect(label != "Today")
        #expect(label != "Yesterday")

        // Should match MM/dd/yy format
        let pattern = #"^\d{2}/\d{2}/\d{2}$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(label.startIndex..., in: label)
        #expect(regex.firstMatch(in: label, range: range) != nil)
    }

    @Test("One year ago returns formatted date") func oneYearAgoReturnsFormattedDate() {
        let calendar = Calendar.current
        let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: Date())!
        let label = oneYearAgo.relativeSessionLabel

        // Should match MM/dd/yy format
        let pattern = #"^\d{2}/\d{2}/\d{2}$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(label.startIndex..., in: label)
        #expect(regex.firstMatch(in: label, range: range) != nil)
    }

    // MARK: - Edge Cases: Midnight Boundaries

    @Test("Midnight today returns 'Today'") func midnightTodayReturnsToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        #expect(today.relativeSessionLabel == "Today")
    }

    @Test("One second before midnight today returns 'Today'") func oneSecondBeforeMidnightReturnsToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneSecondBeforeMidnight = calendar.date(byAdding: .day, value: 1, to: today)!
            .addingTimeInterval(-1)
        #expect(oneSecondBeforeMidnight.relativeSessionLabel == "Today")
    }

    @Test("Midnight yesterday returns 'Yesterday'") func midnightYesterdayReturnsYesterday() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let midnightYesterday = calendar.startOfDay(for: yesterday)
        #expect(midnightYesterday.relativeSessionLabel == "Yesterday")
    }

    @Test("One second before midnight yesterday returns 'Yesterday'")
    func oneSecondBeforeMidnightYesterdayReturnsYesterday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneSecondBeforeMidnight = today.addingTimeInterval(-1)
        #expect(oneSecondBeforeMidnight.relativeSessionLabel == "Yesterday")
    }

    // MARK: - Edge Cases: Future Dates

    @Test("Tomorrow returns formatted date") func tomorrowReturnsFormattedDate() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let label = tomorrow.relativeSessionLabel

        // Future dates should return formatted date, not "Today"
        #expect(label != "Today")

        // Should match MM/dd/yy format
        let pattern = #"^\d{2}/\d{2}/\d{2}$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(label.startIndex..., in: label)
        #expect(regex.firstMatch(in: label, range: range) != nil)
    }

    @Test("One week in future returns formatted date") func oneWeekInFutureReturnsFormattedDate() {
        let calendar = Calendar.current
        let oneWeekFromNow = calendar.date(byAdding: .day, value: 7, to: Date())!
        let label = oneWeekFromNow.relativeSessionLabel

        // Should match MM/dd/yy format
        let pattern = #"^\d{2}/\d{2}/\d{2}$"#
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(label.startIndex..., in: label)
        #expect(regex.firstMatch(in: label, range: range) != nil)
    }

    // MARK: - Edge Cases: Specific Date Formatting

    @Test("Date format includes leading zeros") func dateFormatIncludesLeadingZeros() {
        // Create a date with single-digit month and day (e.g., January 5)
        let components = DateComponents(year: 2025, month: 1, day: 5)
        let calendar = Calendar.current
        let date = calendar.date(from: components)!

        let label = date.relativeSessionLabel

        // Should be in format MM/dd/yy (e.g., "01/05/25")
        // Verify it has leading zeros
        if label != "Today", label != "Yesterday" {
            #expect(label.hasPrefix("01/05/"))
        }
    }

    @Test("December 31st formats correctly") func december31FormatsCorrectly() {
        let components = DateComponents(year: 2024, month: 12, day: 31)
        let calendar = Calendar.current
        let date = calendar.date(from: components)!

        let label = date.relativeSessionLabel

        // Should match MM/dd/yy format
        if label != "Today", label != "Yesterday" {
            #expect(label.hasPrefix("12/31/"))
        }
    }

    @Test("Leap year date formats correctly") func leapYearDateFormatsCorrectly() {
        // February 29, 2024 (leap year)
        let components = DateComponents(year: 2024, month: 2, day: 29)
        let calendar = Calendar.current
        let date = calendar.date(from: components)!

        let label = date.relativeSessionLabel

        // Should match MM/dd/yy format
        if label != "Today", label != "Yesterday" {
            #expect(label.hasPrefix("02/29/"))
        }
    }

    // MARK: - Edge Cases: Year Boundaries

    @Test("Year transitions correctly in format") func yearTransitionsCorrectlyInFormat() {
        // Test a date from last year
        let calendar = Calendar.current
        let lastYear = calendar.component(.year, from: Date()) - 1
        let components = DateComponents(year: lastYear, month: 6, day: 15)
        let date = calendar.date(from: components)!

        let label = date.relativeSessionLabel

        // Should not be "Today" or "Yesterday"
        #expect(label != "Today")
        #expect(label != "Yesterday")

        // Should match MM/dd/yy format with last year's year
        let yearSuffix = String(lastYear % 100)
        let paddedYear = yearSuffix.count == 1 ? "0\(yearSuffix)" : yearSuffix
        #expect(label.hasSuffix("/\(paddedYear)"))
    }
}
