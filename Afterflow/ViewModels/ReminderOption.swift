import Foundation

enum ReminderOption: CaseIterable {
    case oneHour
    case laterToday
    case tomorrowMorning
    case none

    func targetDate(from date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none:
            return nil
        case .oneHour:
            return date.addingTimeInterval(3600)
        case .laterToday:
            guard let todayEvening = calendar.date(
                bySettingHour: 18,
                minute: 0,
                second: 0,
                of: date
            ) else {
                return date.addingTimeInterval(3600 * 6)
            }
            if todayEvening > date {
                return todayEvening
            }
            return calendar.date(byAdding: .day, value: 1, to: todayEvening)
        case .tomorrowMorning:
            let startOfDay = calendar.startOfDay(for: date)
            return calendar.date(byAdding: DateComponents(day: 1, hour: 8), to: startOfDay)
        }
    }
}
