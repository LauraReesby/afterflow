import Foundation

extension Date {
    /// Returns "Today", "Yesterday", or a short date string (MM/dd/yy).
    var relativeSessionLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter.string(from: self)
    }
}
