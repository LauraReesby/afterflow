import SwiftUI

public struct CollapsibleCalendarView: View {
    public enum DisplayMode {
        case twoWeeks
        case month
    }

    @Binding private var selectedDate: Date?
    @Binding private var currentMonthStart: Date
    @Binding private var mode: DisplayMode
    @Binding private var centerOnMonthRequest: Date?

    private let markedDates: [Date: Color]
    private let calendar: Calendar
    private let onSelect: (Date) -> Void
    private let minMonth: Date
    private let maxMonth: Date

    @State private var monthStack: [Date]
    @State private var isExtendingStack = false
    @State private var hasCenteredExpanded = false
    @State private var pendingCenterMonth: Date?
    @State private var pagingDragAccumulation: CGFloat = 0

    private let maxMonthStackSize = 9
    private let expandedRowCount: CGFloat = 5
    private let estimatedRowHeight: CGFloat = 44

    private var estimatedMonthHeight: CGFloat {
        // Approximate month block height: rows * estimatedRowHeight + vertical spacing between weeks and months
        // We already use `expandedRowCount` and `estimatedRowHeight` to size the ScrollView frame.
        // Add a conservative spacing buffer (e.g., 12 per month + 4 per week row spacing).
        return (self.expandedRowCount * self.estimatedRowHeight)
    }

    public init(
        selectedDate: Binding<Date?>,
        currentMonth: Binding<Date>,
        mode: Binding<DisplayMode>,
        markedDates: [Date: Color],
        calendar: Calendar = .current,
        centerOnMonth: Binding<Date?>? = nil,
        onSelect: @escaping (Date) -> Void
    ) {
        self._selectedDate = selectedDate
        self._currentMonthStart = currentMonth
        self._mode = mode
        if let centerOnMonth {
            self._centerOnMonthRequest = centerOnMonth
        } else {
            self._centerOnMonthRequest = .constant(nil)
        }
        self.calendar = calendar
        self.markedDates = markedDates.reduce(into: [:]) { result, entry in
            let normalized = calendar.startOfDay(for: entry.key)
            result[normalized] = entry.value
        }
        self.onSelect = onSelect
        let todayMonth = calendar.startOfMonth(for: Date())
        let minMonth = markedDates.keys.min().map { calendar.startOfMonth(for: $0) } ?? todayMonth
        let maxMonth = calendar.date(byAdding: .month, value: 2, to: todayMonth)
            .map { calendar.startOfMonth(for: $0) } ?? todayMonth
        self.minMonth = minMonth
        self.maxMonth = maxMonth
        let normalized = calendar.startOfMonth(for: currentMonth.wrappedValue)
        self._monthStack = State(
            initialValue: Self.seedMonths(
                centeredOn: normalized,
                calendar: calendar,
                minMonth: minMonth,
                maxMonth: maxMonth
            )
        )
    }

    public var body: some View {
        VStack(spacing: 8) {
            self.header
            self.weekDayHeader
            self.calendarGrid
            self.grabber
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .gesture(self.pullGesture)
        .animation(.easeInOut(duration: 0.25), value: self.mode)
        .onChange(of: self.mode) { _, newMode in
            if newMode == .month {
                // Decide authoritative month to center
                let anchor = self.centerOnMonthRequest ?? (self.selectedDate.map { self.calendar.startOfMonth(for: $0) } ?? self.currentMonthStart)
                let normalized = self.clampMonth(self.calendar.startOfMonth(for: anchor))

                // Make currentMonthStart authoritative
                if normalized != self.currentMonthStart {
                    self.currentMonthStart = normalized
                }
                if self.selectedDate == nil {
                    self.selectedDate = normalized
                }

                // Seed stack around the authoritative month and schedule centering
                self.resetMonthStack()
                self.hasCenteredExpanded = false
                self.pendingCenterMonth = normalized

                // Clear one-shot request
                self.centerOnMonthRequest = nil
            } else {
                self.pendingCenterMonth = nil
            }
        }
    }

    private var grabber: some View {
        Capsule()
            .fill(Color.secondary.opacity(0.4))
            .frame(width: 36, height: 5)
            .padding(.bottom, 6)
            .onTapGesture { self.toggleMode() }
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onEnded { value in
                        let predicted = value.predictedEndTranslation.height
                        if predicted > 40 {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.mode = .month
                            }
                        } else if predicted < -40 {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.mode = .twoWeeks
                            }
                        }
                    }
            )
            .accessibilityLabel("Toggle calendar size")
            .accessibilityHint("Tap to expand or collapse the calendar")
    }

    private var header: some View {
        HStack {
            Text(self.monthTitle(self.currentMonthStart))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 14)
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
        Group {
            switch self.mode {
            case .twoWeeks:
                let days = self.oneWeekDays()
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        ForEach(0 ..< 7, id: \.self) { col in
                            if col < days.count {
                                let day = days[col]
                                self.dayCell(day, monthStart: self.currentMonthStart)
                            }
                        }
                    }
                }
            case .month:
                self.expandedMonthScroll()
            }
        }
    }

    private func dayCell(_ day: Date, monthStart: Date) -> some View {
        let isCurrentMonth = self.calendar.isDate(day, equalTo: monthStart, toGranularity: .month)
        let isSelected = self.selectedDate.map { self.calendar.isDate($0, inSameDayAs: day) } ?? false
        let normalizedDay = self.calendar.startOfDay(for: day)
        let markerColor = self.markedDates[normalizedDay]
        let isMarked = markerColor != nil

        return Button {
            let month = self.calendar.startOfMonth(for: day)
            if month != self.currentMonthStart {
                self.currentMonthStart = month
            }
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

    private func oneWeekDays() -> [Date] {
        // Collapsed view follows the week anchored to the selected date or the current month.
        let anchor = self.selectedDate ?? self.currentMonthStart
        let reference = self.calendar
            .isDate(anchor, equalTo: self.currentMonthStart, toGranularity: .month) ? anchor : self
            .currentMonthStart
        let startOfWeek = self.calendar.startOfWeek(containing: reference)
        return (0 ..< 7).compactMap { self.calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func shiftMonth(_ delta: Int) {
        guard let newStart = calendar.date(byAdding: .month, value: delta, to: currentMonthStart) else { return }
        let normalized = self.calendar.startOfMonth(for: newStart)
        let clamped = self.clampMonth(normalized)
        guard clamped != self.currentMonthStart else { return }
        self.currentMonthStart = clamped

        if self.mode == .twoWeeks {
            self.selectedDate = self.currentMonthStart
        }
        self.ensureMonthInStack(self.currentMonthStart)
        if self.mode == .month {
            self.pendingCenterMonth = self.currentMonthStart
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
                let verticalDistance = abs(value.translation.height)

                // When expanded, vertical swipes navigate months; otherwise they toggle size.
                if verticalDistance > 20 {
                    if self.mode == .month {
                        if value.translation.height > 0 {
                            self.shiftMonth(-1)
                        } else {
                            self.shiftMonth(1)
                        }
                    } else {
                        if value.translation.height > 0 {
                            self.mode = .month
                        } else {
                            self.mode = .twoWeeks
                        }
                    }
                }
            }
    }

    private func toggleMode() {
        withAnimation(.easeInOut(duration: 0.25)) {
            self.mode = (self.mode == .twoWeeks) ? .month : .twoWeeks
        }
    }

    private func expandedMonthScroll() -> some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 12) {
                    ForEach(self.monthStack, id: \.self) { month in
                        VStack(spacing: 6) {
                            let weeks = self.monthWeeks(for: month)
                            VStack(spacing: 4) {
                                ForEach(weeks.indices, id: \.self) { row in
                                    HStack(spacing: 4) {
                                        ForEach(0 ..< 7, id: \.self) { col in
                                            let day = weeks[row][col]
                                            if let day {
                                                self.dayCell(day, monthStart: month)
                                            } else {
                                                self.placeholderCell()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .id(self.id(for: month))
                        .onAppear {
                            self.expandStackIfNeeded(visibleMonth: month)
                        }
                    }
                }
                .padding(.bottom, 6)
            }
            .frame(height: self.expandedRowCount * self.estimatedRowHeight)
            .coordinateSpace(name: "monthScroll")
            .onAppear {
                let target = self.centerOnMonthRequest ?? self.currentMonthStart
                let normalized = self.clampMonth(self.calendar.startOfMonth(for: target))
                self.pendingCenterMonth = normalized
                self.centerOnMonthRequest = nil
            }
            .onChange(of: self.pendingCenterMonth) { _, target in
                guard let target else { return }
                self.centerOnMonth(target, proxy: proxy, animated: true)
            }
            .onChange(of: self.centerOnMonthRequest) { _, target in
                guard let target, self.mode == .month else { return }
                let normalized = self.clampMonth(self.calendar.startOfMonth(for: target))
                self.centerOnMonth(normalized, proxy: proxy, animated: true)
                self.centerOnMonthRequest = nil
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        // Accumulate vertical translation while dragging
                        self.pagingDragAccumulation = value.translation.height
                    }
                    .onEnded { value in
                        let translation = value.translation.height
                        let rawDelta = -translation / self.estimatedMonthHeight

                        let deltaIndex = Int(round(rawDelta))
                        guard deltaIndex != 0 else {
                            self.pagingDragAccumulation = 0
                            return
                        }

                        self.shiftMonth(deltaIndex)

                        // Clear accumulation
                        self.pagingDragAccumulation = 0
                    }
            )
        }
    }

    private func monthWeeks(for monthStart: Date) -> [[Date?]] {
        let normalized = self.calendar.startOfMonth(for: monthStart)
        let start = self.calendar.firstGridDate(forMonthStartingAt: normalized)
        let days: [Date?] = (0 ..< 42).compactMap { offset in
            guard let date = self.calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return self.calendar.isDate(date, equalTo: normalized, toGranularity: .month) ? date : nil
        }

        var weeks: [[Date?]] = stride(from: 0, to: days.count, by: 7).map { index in
            Array(days[index ..< min(index + 7, days.count)])
        }

        while let last = weeks.last, last.allSatisfy({ $0 == nil }) {
            weeks.removeLast()
        }

        return weeks
    }

    private func expandStackIfNeeded(visibleMonth: Date) {
        guard !self.isExtendingStack else { return }
        guard self.hasCenteredExpanded else { return }
        guard let first = self.monthStack.first, let last = self.monthStack.last else { return }
        let normalized = self.calendar.startOfMonth(for: visibleMonth)
        let needsPrepend = self.calendar.isDate(normalized, equalTo: first, toGranularity: .month)
        let needsAppend = self.calendar.isDate(normalized, equalTo: last, toGranularity: .month)

        guard needsPrepend || needsAppend else { return }
        self.isExtendingStack = true
        defer { self.isExtendingStack = false }

        if needsPrepend,
           let newMonth = self.calendar.date(byAdding: .month, value: -1, to: first) {
            let normalizedNew = self.calendar.startOfMonth(for: newMonth)
            if normalizedNew >= self.minMonth {
                self.monthStack.insert(normalizedNew, at: 0)
            }
        }

        if needsAppend,
           let newMonth = self.calendar.date(byAdding: .month, value: 1, to: last) {
            let normalizedNew = self.calendar.startOfMonth(for: newMonth)
            if normalizedNew <= self.maxMonth {
                self.monthStack.append(normalizedNew)
            }
        }

        self.trimMonthStack()
    }

    private func ensureMonthInStack(_ month: Date) {
        let normalized = self.calendar.startOfMonth(for: month)
        guard normalized >= self.minMonth, normalized <= self.maxMonth else { return }
        if !self.monthStack.contains(where: { self.calendar.isDate($0, equalTo: normalized, toGranularity: .month) }) {
            self.monthStack.append(normalized)
            self.monthStack.sort()
        }
        self.trimMonthStack()
    }

    private func centerOnMonth(_ month: Date, proxy: ScrollViewProxy, animated: Bool) {
        self.ensureMonthInStack(month)
        let action = {
            let targetID = self.id(for: month)

            // Defer scroll one tick to ensure layout is committed
            DispatchQueue.main.async {
                proxy.scrollTo(targetID, anchor: .top)
                self.hasCenteredExpanded = true
                self.pendingCenterMonth = nil
            }
        }
        if animated {
            withAnimation(.easeInOut(duration: 0.25)) { action() }
        } else {
            action()
        }
    }

    private func id(for month: Date) -> String {
        let comps = self.calendar.dateComponents([.year, .month], from: month)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }

    private func resetMonthStack() {
        let normalized = self.calendar.startOfMonth(for: self.currentMonthStart)
        self.monthStack = Self.seedMonths(
            centeredOn: normalized,
            calendar: self.calendar,
            minMonth: self.minMonth,
            maxMonth: self.maxMonth
        )
        self.isExtendingStack = false
        self.hasCenteredExpanded = false
        self.pendingCenterMonth = normalized
    }

    private func placeholderCell() -> some View {
        VStack(spacing: 4) {
            Text("")
                .font(.footnote)
                .frame(maxWidth: .infinity)
            Circle()
                .fill(Color.clear)
                .frame(width: 6, height: 6)
                .opacity(0)
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
    }

    private func trimMonthStack() {
        guard self.monthStack.count > self.maxMonthStackSize else { return }
        let center = self.calendar.startOfMonth(for: self.currentMonthStart)
        while self.monthStack.count > self.maxMonthStackSize {
            let distances = self.monthStack.enumerated().compactMap { index, month -> (Int, Int)? in
                let delta = self.monthsBetween(month, center)
                return (index, abs(delta))
            }
            guard let farthest = distances.max(by: { $0.1 < $1.1 }) else { break }
            self.monthStack.remove(at: farthest.0)
        }
    }

    private func monthsBetween(_ lhs: Date, _ rhs: Date) -> Int {
        let startL = self.calendar.startOfMonth(for: lhs)
        let startR = self.calendar.startOfMonth(for: rhs)
        return self.calendar.dateComponents([.month], from: startL, to: startR).month ?? 0
    }

    private func clampMonth(_ month: Date) -> Date {
        min(max(month, self.minMonth), self.maxMonth)
    }

    private static func seedMonths(centeredOn date: Date, calendar: Calendar, minMonth: Date,
                                   maxMonth: Date) -> [Date] {
        let normalized = calendar.startOfMonth(for: date)
        let clamped = min(max(normalized, minMonth), maxMonth)
        let months = (-2 ... 2).compactMap { offset in
            calendar.date(byAdding: .month, value: offset, to: clamped)
        }
        return months
            .map { calendar.startOfMonth(for: $0) }
            .filter { $0 >= minMonth && $0 <= maxMonth }
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
