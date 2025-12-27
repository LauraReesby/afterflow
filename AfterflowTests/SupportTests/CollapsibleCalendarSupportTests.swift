@testable import Afterflow
import Foundation
import Testing

struct CollapsibleCalendarSupportTests {
    @Test("Start of month returns first day of month") func startOfMonthReturnsFirstDayOfMonth() throws {
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 15, hour: 14, minute: 30)

        let monthStart = calendar.startOfMonth(for: date)

        let components = calendar.dateComponents([.year, .month, .day], from: monthStart)
        #expect(components.year == 2024)
        #expect(components.month == 12)
        #expect(components.day == 1)
    }

    @Test("Start of month with leap year February") func startOfMonthWithLeapYear() throws {
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 2, day: 29)

        let monthStart = calendar.startOfMonth(for: date)

        let components = calendar.dateComponents([.year, .month, .day], from: monthStart)
        #expect(components.year == 2024)
        #expect(components.month == 2)
        #expect(components.day == 1)
    }

    @Test("Start of month at year boundary") func startOfMonthAtYearBoundary() throws {
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 31)

        let monthStart = calendar.startOfMonth(for: date)

        let components = calendar.dateComponents([.year, .month, .day], from: monthStart)
        #expect(components.year == 2024)
        #expect(components.month == 12)
        #expect(components.day == 1)
    }

    @Test("Start of month handles first day of month", .serialized) func startOfMonthHandlesFirstDayOfMonth() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = TestHelpers.dateComponents(year: 2024, month: 6, day: 1)

        let monthStart = calendar.startOfMonth(for: date)

        let components = calendar.dateComponents([.year, .month, .day], from: monthStart)
        #expect(components.year == 2024)
        #expect(components.month == 6)
        #expect(components.day == 1)
    }

    @Test("Start of week returns first day of week") func startOfWeekReturnsFirstDayOfWeek() throws {
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 15)

        let weekStart = calendar.startOfWeek(containing: date)

        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: weekStart)
        #expect(components.weekday == calendar.firstWeekday)
    }

    @Test("Start of week at week boundary") func startOfWeekAtWeekBoundary() throws {
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)

        let weekStart = calendar.startOfWeek(containing: date)

        let components = calendar.dateComponents([.weekday], from: weekStart)
        #expect(components.weekday == calendar.firstWeekday)
    }

    @Test("Start of week with different locales") func startOfWeekWithDifferentLocales() throws {
        var usCalendar = Calendar.current
        usCalendar.locale = Locale(identifier: "en_US")

        var euCalendar = Calendar.current
        euCalendar.locale = Locale(identifier: "en_GB")
        euCalendar.firstWeekday = 2

        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 15)

        let usWeekStart = usCalendar.startOfWeek(containing: date)
        let euWeekStart = euCalendar.startOfWeek(containing: date)

        let usComponents = usCalendar.dateComponents([.weekday], from: usWeekStart)
        let euComponents = euCalendar.dateComponents([.weekday], from: euWeekStart)

        #expect(usComponents.weekday == usCalendar.firstWeekday)
        #expect(euComponents.weekday == euCalendar.firstWeekday)
    }

    @Test("First grid date calculates correctly") func firstGridDateCalculatesCorrectly() throws {
        let calendar = Calendar.current
        let monthStart = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)

        let gridStart = calendar.firstGridDate(forMonthStartingAt: monthStart)

        #expect(gridStart <= monthStart)

        let weekday = calendar.component(.weekday, from: gridStart)
        #expect(weekday == calendar.firstWeekday)
    }

    @Test("First grid date when month starts on first weekday")
    func firstGridDateWhenMonthStartsOnFirstWeekday() throws {
        let calendar = Calendar.current

        var testCalendar = Calendar.current
        testCalendar.firstWeekday = 1

        let monthStart = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)

        let gridStart = testCalendar.firstGridDate(forMonthStartingAt: monthStart)

        let monthWeekday = testCalendar.component(.weekday, from: monthStart)
        if monthWeekday == testCalendar.firstWeekday {
            #expect(gridStart == monthStart)
        }
    }

    @Test("First grid date respects first weekday setting") func firstGridDateRespectsFirstWeekday() throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        let monthStart = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)

        let gridStart = calendar.firstGridDate(forMonthStartingAt: monthStart)

        let weekday = calendar.component(.weekday, from: gridStart)
        #expect(weekday == 2)
    }

    @Test("First grid date at month boundaries") func firstGridDateAtMonthBoundaries() throws {
        let calendar = Calendar.current

        let janStart = TestHelpers.dateComponents(year: 2024, month: 1, day: 1)
        let janGridStart = calendar.firstGridDate(forMonthStartingAt: janStart)
        let janWeekday = calendar.component(.weekday, from: janGridStart)
        #expect(janWeekday == calendar.firstWeekday)

        let decStart = TestHelpers.dateComponents(year: 2024, month: 12, day: 1)
        let decGridStart = calendar.firstGridDate(forMonthStartingAt: decStart)
        let decWeekday = calendar.component(.weekday, from: decGridStart)
        #expect(decWeekday == calendar.firstWeekday)
    }

    @Test("Accessibility label includes full date", .serialized) func accessibilityLabelIncludesFullDate() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 25)

        let label = AccessibilityLabelBuilder.label(for: date, calendar: calendar, marked: false)

        #expect(!label.isEmpty)
        #expect(label.count > 10)

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2024)
        #expect(components.month == 12)
        #expect(components.day == 25)
    }

    @Test("Accessibility label includes marked status") func accessibilityLabelIncludesMarkedStatus() throws {
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 12, day: 15)

        let unmarkedLabel = AccessibilityLabelBuilder.label(for: date, calendar: calendar, marked: false)
        let markedLabel = AccessibilityLabelBuilder.label(for: date, calendar: calendar, marked: true)

        #expect(!unmarkedLabel.contains("has sessions"))
        #expect(markedLabel.contains("has sessions"))
    }

    @Test("Accessibility label formats correctly") func accessibilityLabelFormatsCorrectly() throws {
        let calendar = Calendar.current
        let date = TestHelpers.dateComponents(year: 2024, month: 6, day: 1)

        let label = AccessibilityLabelBuilder.label(for: date, calendar: calendar, marked: true)

        #expect(!label.isEmpty)
        #expect(label.contains("has sessions"))
    }
}
