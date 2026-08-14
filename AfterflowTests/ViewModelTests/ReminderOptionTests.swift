@testable import Afterflow
import Foundation
import Testing

@MainActor
struct ReminderOptionTests {
    @Test("Three hour reminder adds 10_800 seconds") func threeHourReminder() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let target = try #require(ReminderOption.threeHours.targetDate(from: now))
        #expect(abs(target.timeIntervalSince1970 - now.timeIntervalSince1970 - 10800) < 0.001)
    }

    @Test("Tomorrow reminder schedules 9AM next day") func tomorrowReminder() throws {
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 21
        components.hour = 23
        components.minute = 15
        let calendar = Calendar(identifier: .gregorian)
        let lateNight = try #require(calendar.date(from: components))

        let target = try #require(ReminderOption.tomorrow.targetDate(from: lateNight, calendar: calendar))
        let startOfDay = calendar.startOfDay(for: lateNight)
        let expected = try #require(calendar.date(byAdding: DateComponents(day: 1, hour: 9), to: startOfDay))
        #expect(target == expected)
    }

    @Test("No reminder returns nil") func noneReminder() {
        let now = Date()
        #expect(ReminderOption.none.targetDate(from: now) == nil)
    }
}
