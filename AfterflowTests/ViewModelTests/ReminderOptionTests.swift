@testable import Afterflow
import Foundation
import Testing

@MainActor
struct ReminderOptionTests {
    @Test("One hour reminder adds 3600 seconds") func oneHourReminder() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let target = ReminderOption.oneHour.targetDate(from: now)!
        #expect(abs(target.timeIntervalSince1970 - now.timeIntervalSince1970 - 3600) < 0.001)
    }

    @Test("Later today returns 6PM same day when in future") func laterTodayFuture() {
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 21
        components.hour = 9
        components.minute = 0
        let calendar = Calendar(identifier: .gregorian)
        let morning = calendar.date(from: components)!

        let target = ReminderOption.laterToday.targetDate(from: morning, calendar: calendar)!
        let expected = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: morning)!
        #expect(target == expected)
    }

    @Test("Later today rolls to next day when after 6PM") func laterTodayRolls() {
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 21
        components.hour = 20
        components.minute = 0
        let calendar = Calendar(identifier: .gregorian)
        let evening = calendar.date(from: components)!

        let target = ReminderOption.laterToday.targetDate(from: evening, calendar: calendar)!
        let nextEvening = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: evening)!
        )!
        #expect(target == nextEvening)
    }

    @Test("Tomorrow morning reminder schedules 8AM next day") func tomorrowMorningReminder() {
        var components = DateComponents()
        components.year = 2025
        components.month = 11
        components.day = 21
        components.hour = 23
        components.minute = 0
        let calendar = Calendar(identifier: .gregorian)
        let lateNight = calendar.date(from: components)!

        let target = ReminderOption.tomorrowMorning.targetDate(from: lateNight, calendar: calendar)!
        let startOfDay = calendar.startOfDay(for: lateNight)
        let expected = calendar.date(byAdding: DateComponents(day: 1, hour: 8), to: startOfDay)!
        #expect(target == expected)
    }

    @Test("No reminder returns nil") func noneReminder() {
        let now = Date()
        #expect(ReminderOption.none.targetDate(from: now) == nil)
    }
}
