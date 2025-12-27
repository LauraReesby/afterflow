import Foundation

enum ReminderOption: CaseIterable {
    case threeHours
    case tomorrow
    case none

    func targetDate(from date: Date, calendar: Calendar = .current) -> Date? {
        switch self {
        case .none:
            return nil
        case .threeHours:
            return date.addingTimeInterval(3 * 3600)
        case .tomorrow:
            let startOfDay = calendar.startOfDay(for: date)
            
            return calendar.date(byAdding: DateComponents(day: 1, hour: 9), to: startOfDay)
        }
    }
}
