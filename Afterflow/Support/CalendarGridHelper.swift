import Foundation
import SwiftUI

enum CalendarGridHelper {
    static func generateMonthRange(
        from sessions: [TherapeuticSession],
        referenceDate: Date = Date()
    ) -> [Date] {
        let calendar = Calendar.current

        // Use min/max rather than first/last: the caller's array order depends on
        // the active sort option, so positional assumptions are unsafe.
        guard let oldestDate = sessions.map(\.sessionDate).min(),
              let newestDate = sessions.map(\.sessionDate).max()
        else {
            return [calendar.startOfMonth(for: referenceDate)]
        }

        let startMonth = calendar.startOfMonth(for: oldestDate)
        let endMonth = calendar.startOfMonth(for: max(newestDate, referenceDate))

        var months: [Date] = []
        var currentMonth = startMonth

        while currentMonth <= endMonth {
            months.append(currentMonth)
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
                break
            }
            currentMonth = nextMonth
        }

        return months
    }

    static func generateGridDaysForMonth(_ monthStart: Date) -> [Date?] {
        let calendar = Calendar.current

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let offset = (firstWeekday - calendar.firstWeekday + 7) % 7
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30

        var gridDays: [Date?] = []

        for _ in 0 ..< offset {
            gridDays.append(nil)
        }

        for day in 0 ..< daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day, to: monthStart) {
                gridDays.append(date)
            }
        }

        return gridDays
    }

    static func calendarMarkers(from sessions: [TherapeuticSession]) -> [Date: Color] {
        let calendar = Calendar.current
        return sessions.reduce(into: [:]) { result, session in
            let day = calendar.startOfDay(for: session.sessionDate)
            if result[day] == nil {
                result[day] = session.treatmentType.accentColor
            }
        }
    }
}
