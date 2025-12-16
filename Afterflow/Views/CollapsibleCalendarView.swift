import SwiftUI

public struct CollapsibleCalendarView: View {
    public enum DisplayMode {
        case twoWeeks
        case month
    }

    @Binding private var selectedDate: Date?
    @Binding private var currentMonthStart: Date
    @Binding private var mode: DisplayMode

    private let markedDates: [Date: Color]
    private let calendar: Calendar
    private let onSelect: (Date) -> Void

    public init(
        selectedDate: Binding<Date?>,
        currentMonth: Binding<Date>,
        mode: Binding<DisplayMode>,
        markedDates: [Date: Color],
        calendar: Calendar = .current,
        onSelect: @escaping (Date) -> Void
    ) {
        self._selectedDate = selectedDate
        self._currentMonthStart = currentMonth
        self._mode = mode
        self.calendar = calendar
        self.markedDates = markedDates.reduce(into: [:]) { result, entry in
            let normalized = calendar.startOfDay(for: entry.key)
            result[normalized] = entry.value
        }
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(spacing: 8) {
            self.header
            self.weekDayHeader
            self.calendarGrid
                .id(self.gridIdentity)
            self.grabber
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .gesture(self.pullGesture)
        .animation(.easeInOut(duration: 0.25), value: self.mode)
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(.bottom, 6)
            .onTapGesture { self.toggleMode() }
            .accessibilityLabel("Toggle calendar size")
            .accessibilityHint("Tap to expand or collapse the calendar")
    }

    private var header: some View {
        HStack {
            Button { self.shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(self.monthTitle(self.currentMonthStart))
                .font(.headline)
            Spacer()
            Button { self.shiftMonth(1) } label: { Image(systemName: "chevron.right") }
        }
        .buttonStyle(.plain)
        .onTapGesture { self.toggleMode() }
    }

    private var weekDayHeader: some View {
        let symbols = self.calendar.shortWeekdaySymbols
        return HStack {
            ForEach(0 ..< 7, id: \.self) { i in
                Text(symbols[(i + self.calendar.firstWeekday - 1) % 7])
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var calendarGrid: some View {
        let days = self.visibleDays()
        return VStack(spacing: 4) {
            ForEach(0 ..< self.rowsCount(), id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0 ..< 7, id: \.self) { col in
                        let index = row * 7 + col
                        if index < days.count {
                            let day = days[index]
                            self.dayCell(day)
                        }
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isCurrentMonth = self.calendar.isDate(day, equalTo: self.currentMonthStart, toGranularity: .month)
        let isSelected = self.selectedDate.map { self.calendar.isDate($0, inSameDayAs: day) } ?? false
        let normalizedDay = self.calendar.startOfDay(for: day)
        let markerColor = self.markedDates[normalizedDay]
        let isMarked = markerColor != nil

        return Button {
            self.selectedDate = day
            self.onSelect(day)
        } label: {
            VStack(spacing: 4) {
                Text("\(self.calendar.component(.day, from: day))")
                    .font(.footnote.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isCurrentMonth ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                Circle()
                    .fill(markerColor ?? .clear)
                    .frame(width: 6, height: 6)
                    .opacity(isMarked ? 1 : 0)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AccessibilityLabelBuilder.label(for: day, calendar: self.calendar, marked: isMarked))
    }

    private func rowsCount() -> Int {
        switch self.mode {
        case .twoWeeks:
            2
        case .month:
            6 // enough to cover any month grid
        }
    }

    private func visibleDays() -> [Date] {
        switch self.mode {
        case .twoWeeks:
            // When the calendar is collapsed we still want the visible days to follow the
            // current month selection, even if the previously selected day belongs to a
            // different month.
            let anchor = self.selectedDate ?? self.currentMonthStart
            let reference = self.calendar
                .isDate(anchor, equalTo: self.currentMonthStart, toGranularity: .month) ? anchor : self
                .currentMonthStart
            let startOfWeek = self.calendar.startOfWeek(containing: reference)
            guard let secondWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) else { return [] }

            let firstWeek = (0 ..< 7).compactMap { self.calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
            let nextWeek = (0 ..< 7).compactMap { self.calendar.date(byAdding: .day, value: $0, to: secondWeek) }
            return firstWeek + nextWeek

        case .month:
            let start = self.calendar.firstGridDate(forMonthStartingAt: self.currentMonthStart)
            return (0 ..< 42).compactMap { self.calendar.date(byAdding: .day, value: $0, to: start) }
        }
    }

    private func shiftMonth(_ delta: Int) {
        guard let newStart = calendar.date(byAdding: .month, value: delta, to: currentMonthStart) else { return }
        self.currentMonthStart = self.calendar.startOfMonth(for: newStart)

        if self.mode == .twoWeeks {
            self.selectedDate = self.currentMonthStart
        }
    }

    private func monthTitle(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.calendar = self.calendar
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: date)
    }

    private var pullGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in
                let horizontalDistance = abs(value.translation.x)
                let verticalDistance = abs(value.translation.y)
                
                // Prioritize horizontal swipes for month navigation
                if horizontalDistance > verticalDistance && horizontalDistance > 30 {
                    if value.translation.x > 0 {
                        // Swiped right - go to previous month
                        self.shiftMonth(-1)
                    } else {
                        // Swiped left - go to next month
                        self.shiftMonth(1)
                    }
                }
                // Vertical swipes for mode toggling
                else if verticalDistance > 20 {
                    if value.translation.y > 0 {
                        self.mode = .month
                    } else {
                        self.mode = .twoWeeks
                    }
                }
            }
    }

    private func toggleMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.mode = (self.mode == .twoWeeks) ? .month : .twoWeeks
        }
    }

    private var gridIdentity: String {
        let comps = self.calendar.dateComponents([.year, .month], from: self.currentMonthStart)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(self.mode)"
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

private enum AccessibilityLabelBuilder {
    static func label(for date: Date, calendar: Calendar, marked: Bool) -> String {
        let df = DateFormatter()
        df.calendar = calendar
        df.dateStyle = .full
        let base = df.string(from: date)
        return marked ? "\(base), has sessions" : base
    }
}
