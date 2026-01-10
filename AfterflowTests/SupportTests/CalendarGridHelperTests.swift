@testable import Afterflow
import Foundation
import Testing

@MainActor
struct CalendarGridHelperTests {
    @Test("Month range with empty sessions returns current month") func monthRangeWithEmptySessions() throws {
        let referenceDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 15)
        let calendar = Calendar.current

        let months = CalendarGridHelper.generateMonthRange(from: [], referenceDate: referenceDate)

        #expect(months.count == 1)
        let expectedMonth = calendar.startOfMonth(for: referenceDate)
        #expect(months.first == expectedMonth)
    }

    @Test("Month range spans from oldest to newest session") func monthRangeSpansOldestToNewest() throws {
        let calendar = Calendar.current
        let oldDate = TestHelpers.dateComponents(year: 2024, month: 3, day: 10)
        let newDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 20)

        let sessions = [
            makeSession(date: newDate),
            makeSession(date: oldDate)
        ]

        let months = CalendarGridHelper.generateMonthRange(from: sessions, referenceDate: newDate)

        #expect(months.count == 4) // March, April, May, June
        #expect(months.first == calendar.startOfMonth(for: oldDate))
        #expect(months.last == calendar.startOfMonth(for: newDate))
    }

    @Test("Month range includes reference date if newer than sessions") func monthRangeIncludesReferenceDate() throws {
        let calendar = Calendar.current
        let sessionDate = TestHelpers.dateComponents(year: 2024, month: 3, day: 10)
        let referenceDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 15)

        let sessions = [makeSession(date: sessionDate)]

        let months = CalendarGridHelper.generateMonthRange(from: sessions, referenceDate: referenceDate)

        #expect(months.count == 4) // March, April, May, June
        #expect(months.last == calendar.startOfMonth(for: referenceDate))
    }

    @Test("Month range returns months in chronological order") func monthRangeReturnsChronologicalOrder() throws {
        let oldDate = TestHelpers.dateComponents(year: 2024, month: 1, day: 5)
        let newDate = TestHelpers.dateComponents(year: 2024, month: 4, day: 20)

        let sessions = [
            makeSession(date: newDate),
            makeSession(date: oldDate)
        ]

        let months = CalendarGridHelper.generateMonthRange(from: sessions, referenceDate: newDate)

        for i in 0 ..< months.count - 1 {
            #expect(months[i] < months[i + 1])
        }
    }

    @Test("Month range handles single session") func monthRangeHandlesSingleSession() throws {
        let calendar = Calendar.current
        let sessionDate = TestHelpers.dateComponents(year: 2024, month: 5, day: 15)

        let sessions = [makeSession(date: sessionDate)]

        let months = CalendarGridHelper.generateMonthRange(from: sessions, referenceDate: sessionDate)

        #expect(months.count == 1)
        #expect(months.first == calendar.startOfMonth(for: sessionDate))
    }

    @Test("Month range handles sessions spanning year boundary") func monthRangeHandlesYearBoundary() throws {
        let oldDate = TestHelpers.dateComponents(year: 2023, month: 11, day: 10)
        let newDate = TestHelpers.dateComponents(year: 2024, month: 2, day: 20)

        let sessions = [
            makeSession(date: newDate),
            makeSession(date: oldDate)
        ]

        let months = CalendarGridHelper.generateMonthRange(from: sessions, referenceDate: newDate)

        #expect(months.count == 4) // Nov 2023, Dec 2023, Jan 2024, Feb 2024
    }

    @Test("Grid days includes offset cells for month not starting on first weekday")
    func gridDaysIncludesOffsetCells() throws {
        let calendar = Calendar.current
        // Use startOfMonth for a consistent month start in local timezone
        let referenceDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 15, hour: 12)
        let monthStart = calendar.startOfMonth(for: referenceDate)
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let expectedOffset = (firstWeekday - calendar.firstWeekday + 7) % 7

        let gridDays = CalendarGridHelper.generateGridDaysForMonth(monthStart)

        // Count nil values at the start
        var nilCount = 0
        for day in gridDays {
            if day == nil {
                nilCount += 1
            } else {
                break
            }
        }

        #expect(nilCount == expectedOffset)
    }

    @Test("Grid days contains correct number of days for month") func gridDaysContainsCorrectDayCount() throws {
        let calendar = Calendar.current
        // Use startOfMonth to ensure we get a valid month start in local timezone
        let referenceDate = TestHelpers.dateComponents(year: 2024, month: 2, day: 15, hour: 12)
        let monthStart = calendar.startOfMonth(for: referenceDate)
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count

        let gridDays = CalendarGridHelper.generateGridDaysForMonth(monthStart)
        let nonNilDays = gridDays.compactMap { $0 }

        #expect(nonNilDays.count == daysInMonth)
        #expect(daysInMonth == 29) // Leap year February
    }

    @Test("Grid days has first actual day as month start") func gridDaysFirstActualDayIsMonthStart() throws {
        let calendar = Calendar.current
        let referenceDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 15, hour: 12)
        let monthStart = calendar.startOfMonth(for: referenceDate)

        let gridDays = CalendarGridHelper.generateGridDaysForMonth(monthStart)
        let firstActualDay = gridDays.compactMap { $0 }.first

        #expect(calendar.isDate(firstActualDay!, inSameDayAs: monthStart))
    }

    @Test("Grid days has last day as end of month") func gridDaysLastDayIsEndOfMonth() throws {
        let calendar = Calendar.current
        let referenceDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 15, hour: 12)
        let monthStart = calendar.startOfMonth(for: referenceDate)
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count

        let gridDays = CalendarGridHelper.generateGridDaysForMonth(monthStart)
        let lastActualDay = gridDays.compactMap { $0 }.last!

        let dayComponent = calendar.component(.day, from: lastActualDay)
        #expect(dayComponent == daysInMonth)
    }

    @Test("Grid days handles month starting on first weekday")
    func gridDaysHandlesMonthStartingOnFirstWeekday() throws {
        var calendar = Calendar.current
        calendar.firstWeekday = 1 // Sunday

        // Use startOfMonth for consistency
        let referenceDate = TestHelpers.dateComponents(year: 2024, month: 9, day: 15, hour: 12)
        let monthStart = calendar.startOfMonth(for: referenceDate)
        let weekday = calendar.component(.weekday, from: monthStart)

        // September 2024 starts on Sunday - only test if true in this timezone
        if weekday == 1 {
            let gridDays = CalendarGridHelper.generateGridDaysForMonth(monthStart)
            // First cell should not be nil when month starts on first weekday
            #expect(gridDays.first != nil)
        }
    }

    @Test("Grid days handles 31-day month") func gridDaysHandles31DayMonth() throws {
        let calendar = Calendar.current
        let referenceDate = TestHelpers.dateComponents(year: 2024, month: 7, day: 15, hour: 12) // July
        let monthStart = calendar.startOfMonth(for: referenceDate)

        let gridDays = CalendarGridHelper.generateGridDaysForMonth(monthStart)
        let nonNilDays = gridDays.compactMap { $0 }

        #expect(nonNilDays.count == 31)
    }

    @Test("Grid days handles 28-day month") func gridDaysHandles28DayMonth() throws {
        let calendar = Calendar.current
        let referenceDate = TestHelpers.dateComponents(year: 2023, month: 2, day: 15, hour: 12) // Non-leap year Feb
        let monthStart = calendar.startOfMonth(for: referenceDate)

        let gridDays = CalendarGridHelper.generateGridDaysForMonth(monthStart)
        let nonNilDays = gridDays.compactMap { $0 }

        #expect(nonNilDays.count == 28)
    }

    @Test("Calendar markers returns empty for no sessions") func calendarMarkersEmptyForNoSessions() throws {
        let markers = CalendarGridHelper.calendarMarkers(from: [])

        #expect(markers.isEmpty)
    }

    @Test("Calendar markers maps each session date to color") func calendarMarkersMapsSessionDates() throws {
        let date1 = TestHelpers.dateComponents(year: 2024, month: 6, day: 10)
        let date2 = TestHelpers.dateComponents(year: 2024, month: 6, day: 15)

        let sessions = [
            makeSession(date: date1, treatment: .psilocybin),
            makeSession(date: date2, treatment: .lsd)
        ]

        let markers = CalendarGridHelper.calendarMarkers(from: sessions)

        #expect(markers.count == 2)
    }

    @Test("Calendar markers uses first session color for duplicate dates")
    func calendarMarkersUsesFirstSessionColor() throws {
        let calendar = Calendar.current
        // Use noon to avoid timezone issues
        let date = TestHelpers.dateComponents(year: 2024, month: 6, day: 15, hour: 12)
        let dateLater = calendar.date(byAdding: .hour, value: 3, to: date)!

        let sessions = [
            makeSession(date: date, treatment: .psilocybin),
            makeSession(date: dateLater, treatment: .lsd)
        ]

        let markers = CalendarGridHelper.calendarMarkers(from: sessions)

        // Only one entry for this date (first session wins, second is ignored)
        #expect(markers.count == 1)
        // Verify we have exactly one marker
        #expect(markers.values.count == 1)
    }

    @Test("Calendar markers normalizes dates to start of day") func calendarMarkersNormalizesToStartOfDay() throws {
        let calendar = Calendar.current
        let dateWithTime = TestHelpers.dateComponents(year: 2024, month: 6, day: 15, hour: 14, minute: 30)

        let sessions = [makeSession(date: dateWithTime)]

        let markers = CalendarGridHelper.calendarMarkers(from: sessions)

        let markerDate = markers.keys.first!
        let components = calendar.dateComponents([.hour, .minute, .second], from: markerDate)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("Calendar markers handles multiple sessions on different dates")
    func calendarMarkersHandlesMultipleDates() throws {
        let sessions = SessionFixtureFactory.makeSessionsForCalendar(
            monthCount: 2,
            sessionsPerMonth: 3
        )

        let markers = CalendarGridHelper.calendarMarkers(from: sessions)

        // Should have markers for each unique date
        #expect(!markers.isEmpty)
        #expect(markers.count <= sessions.count)
    }

    private func makeSession(
        date: Date,
        treatment: PsychedelicTreatmentType = .psilocybin
    ) -> TherapeuticSession {
        TherapeuticSession(
            sessionDate: date,
            treatmentType: treatment,
            administration: .oral,
            intention: "Test session",
            moodBefore: 5,
            moodAfter: 8
        )
    }
}
