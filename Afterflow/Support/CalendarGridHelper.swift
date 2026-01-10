import Foundation
import SwiftUI

enum CalendarGridHelper {
    static func generateMonthRange(
        from sessions: [TherapeuticSession],
        referenceDate: Date = Date()
    ) -> [Date] {
        let calendar = Calendar.current

        guard let oldestSession = sessions.last,
              let newestSession = sessions.first
        else {
            return [calendar.startOfMonth(for: referenceDate)]
        }

        let startMonth = calendar.startOfMonth(for: oldestSession.sessionDate)
        let endMonth = calendar.startOfMonth(for: max(newestSession.sessionDate, referenceDate))

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
