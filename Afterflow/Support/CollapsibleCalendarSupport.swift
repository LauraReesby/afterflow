import Foundation
import SwiftUI

struct MonthPosition: Equatable {
    let month: Date
    let minY: CGFloat
    let height: CGFloat
}

enum MonthPositionPreferenceKey: PreferenceKey {
    static var defaultValue: [MonthPosition] = []

    static func reduce(value: inout [MonthPosition], nextValue: () -> [MonthPosition]) {
        value.append(contentsOf: nextValue())
    }
}

enum ScrollViewportPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }

    func startOfWeek(containing date: Date) -> Date {
        let comps = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: comps) ?? date
    }

    func firstGridDate(forMonthStartingAt monthStart: Date) -> Date {
        let weekday = component(.weekday, from: monthStart)
        let delta = (weekday - firstWeekday + 7) % 7
        return date(byAdding: .day, value: -delta, to: monthStart) ?? monthStart
    }
}

enum AccessibilityLabelBuilder {
    static func label(for date: Date, calendar: Calendar, marked: Bool) -> String {
        let df = DateFormatter()
        df.calendar = calendar
        df.dateStyle = .full
        let base = df.string(from: date)
        return marked ? "\(base), has sessions" : base
    }
}
