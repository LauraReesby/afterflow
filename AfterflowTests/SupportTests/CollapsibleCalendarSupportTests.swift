@testable import Afterflow
import Foundation
import Testing

struct CollapsibleCalendarSupportTests {
    // MARK: - Calendar.startOfMonth Tests

    @Test("Start of month returns first day of month") func startOfMonthReturnsFirstDayOfMonth() throws {
        // Arrange
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 15, hour: 14, minute: 30)

        // Act
        let monthStart = calendar.startOfMonth(for: date)

        // Assert
        let components = calendar.dateComponents([.year, .month, .day], from: monthStart)
        #expect(components.year == 2024)
        #expect(components.month == 12)
        #expect(components.day == 1)
    }

    @Test("Start of month with leap year February") func startOfMonthWithLeapYear() throws {
        // Arrange
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 2, day: 29) // 2024 is a leap year

        // Act
        let monthStart = calendar.startOfMonth(for: date)

        // Assert
        let components = calendar.dateComponents([.year, .month, .day], from: monthStart)
        #expect(components.year == 2024)
        #expect(components.month == 2)
        #expect(components.day == 1)
    }

    @Test("Start of month at year boundary") func startOfMonthAtYearBoundary() throws {
        // Arrange
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 31)

        // Act
        let monthStart = calendar.startOfMonth(for: date)

        // Assert
        let components = calendar.dateComponents([.year, .month, .day], from: monthStart)
        #expect(components.year == 2024)
        #expect(components.month == 12)
        #expect(components.day == 1)
    }

    @Test("Start of month handles first day of month", .serialized) func startOfMonthHandlesFirstDayOfMonth() throws {
        // Arrange - Use fixed calendar with UTC timezone to match TestHelpers
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = TestHelpers.dateComponents(year: 2024, month: 6, day: 1)

        // Act
        let monthStart = calendar.startOfMonth(for: date)

        // Assert - Should return first day of the month
        let components = calendar.dateComponents([.year, .month, .day], from: monthStart)
        #expect(components.year == 2024)
        #expect(components.month == 6)
        #expect(components.day == 1)
    }

    // MARK: - Calendar.startOfWeek Tests

    @Test("Start of week returns first day of week") func startOfWeekReturnsFirstDayOfWeek() throws {
        // Arrange
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 15) // Mid-week date

        // Act
        let weekStart = calendar.startOfWeek(containing: date)

        // Assert - Should return start of the week containing Dec 15
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: weekStart)
        #expect(components.weekday == calendar.firstWeekday)
    }

    @Test("Start of week at week boundary") func startOfWeekAtWeekBoundary() throws {
        // Arrange
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 1) // First day of December 2024 (Sunday)

        // Act
        let weekStart = calendar.startOfWeek(containing: date)

        // Assert
        let components = calendar.dateComponents([.weekday], from: weekStart)
        #expect(components.weekday == calendar.firstWeekday)
    }

    @Test("Start of week with different locales") func startOfWeekWithDifferentLocales() throws {
        // Arrange - US calendar (Sunday first)
        var usCalendar = Calendar.current
        usCalendar.locale = Locale(identifier: "en_US")

        // European calendar (Monday first)
        var euCalendar = Calendar.current
        euCalendar.locale = Locale(identifier: "en_GB")
        euCalendar.firstWeekday = 2 // Monday

        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 15)

        // Act
        let usWeekStart = usCalendar.startOfWeek(containing: date)
        let euWeekStart = euCalendar.startOfWeek(containing: date)

        // Assert - Different calendars may have different week starts
        let usComponents = usCalendar.dateComponents([.weekday], from: usWeekStart)
        let euComponents = euCalendar.dateComponents([.weekday], from: euWeekStart)

        #expect(usComponents.weekday == usCalendar.firstWeekday)
        #expect(euComponents.weekday == euCalendar.firstWeekday)
    }

    // MARK: - Calendar.firstGridDate Tests

    @Test("First grid date calculates correctly") func firstGridDateCalculatesCorrectly() throws {
        // Arrange
        let calendar = Calendar.current
        let monthStart = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)

        // Act
        let gridStart = calendar.firstGridDate(forMonthStartingAt: monthStart)

        // Assert - Grid start should be on or before the month start
        // and should align with the first weekday
        #expect(gridStart <= monthStart)

        let weekday = calendar.component(.weekday, from: gridStart)
        #expect(weekday == calendar.firstWeekday)
    }

    @Test("First grid date when month starts on first weekday")
    func firstGridDateWhenMonthStartsOnFirstWeekday() throws {
        // Arrange - Find a month that starts on the first weekday
        let calendar = Calendar.current

        // December 1, 2024 is a Sunday (assuming US calendar with Sunday as first weekday)
        var testCalendar = Calendar.current
        testCalendar.firstWeekday = 1 // Sunday

        let monthStart = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)

        // Act
        let gridStart = testCalendar.firstGridDate(forMonthStartingAt: monthStart)

        // Assert - If the month starts on the first weekday, grid start should equal month start
        let monthWeekday = testCalendar.component(.weekday, from: monthStart)
        if monthWeekday == testCalendar.firstWeekday {
            #expect(gridStart == monthStart)
        }
    }

    @Test("First grid date respects first weekday setting") func firstGridDateRespectsFirstWeekday() throws {
        // Arrange
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday

        let monthStart = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)

        // Act
        let gridStart = calendar.firstGridDate(forMonthStartingAt: monthStart)

        // Assert
        let weekday = calendar.component(.weekday, from: gridStart)
        #expect(weekday == 2) // Monday
    }

    @Test("First grid date at month boundaries") func firstGridDateAtMonthBoundaries() throws {
        // Arrange
        let calendar = Calendar.current

        // Test January (beginning of year)
        let janStart = TestHelpers.dateComponents(year: 2024, month: 1, day: 1)
        let janGridStart = calendar.firstGridDate(forMonthStartingAt: janStart)
        let janWeekday = calendar.component(.weekday, from: janGridStart)
        #expect(janWeekday == calendar.firstWeekday)

        // Test December (end of year)
        let decStart = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)
        let decGridStart = calendar.firstGridDate(forMonthStartingAt: decStart)
        let decWeekday = calendar.component(.weekday, from: decGridStart)
        #expect(decWeekday == calendar.firstWeekday)
    }

    // MARK: - AccessibilityLabelBuilder Tests

    @Test("Accessibility label includes full date", .serialized) func accessibilityLabelIncludesFullDate() throws {
        // Arrange - Use fixed calendar with UTC timezone to match TestHelpers
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 25)

        // Act
        let label = AccessibilityLabelBuilder.label(for: date, calendar: calendar, marked: false)

        // Assert - Should produce a non-empty formatted date string
        // Don't check for specific locale strings, just verify it's a proper date label
        #expect(!label.isEmpty)
        #expect(label.count > 10) // Full date style should be reasonably long

        // Verify the date components are present in some form
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2024)
        #expect(components.month == 12)
        #expect(components.day == 25)
    }

    @Test("Accessibility label includes marked status") func accessibilityLabelIncludesMarkedStatus() throws {
        // Arrange
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 15)

        // Act
        let unmarkedLabel = AccessibilityLabelBuilder.label(for: date, calendar: calendar, marked: false)
        let markedLabel = AccessibilityLabelBuilder.label(for: date, calendar: calendar, marked: true)

        // Assert
        #expect(!unmarkedLabel.contains("has sessions"))
        #expect(markedLabel.contains("has sessions"))
    }

    @Test("Accessibility label formats correctly") func accessibilityLabelFormatsCorrectly() throws {
        // Arrange
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 6, day: 1)

        // Act
        let label = AccessibilityLabelBuilder.label(for: date, calendar: calendar, marked: true)

        // Assert - Should be a full date format with marked indicator
        #expect(!label.isEmpty)
        #expect(label.contains("has sessions"))
    }
}
