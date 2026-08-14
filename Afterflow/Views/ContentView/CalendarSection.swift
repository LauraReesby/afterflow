import SwiftUI

/// Calendar mode of the sessions surface: month grids with treatment-colored
/// day dots. Deliberately minimal — no search, no nudge.
struct CalendarSection<Header: View>: View {
    let sessions: [TherapeuticSession]
    @Binding var listViewModel: SessionListViewModel
    @Binding var selection: UUID?
    let sessionStore: SessionStore
    @Binding var navigateToSession: Bool
    let onDaySelected: () -> Void
    @ViewBuilder let header: () -> Header

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: DesignConstants.Spacing.lg) {
                    self.header()

                    ForEach(self.monthRange, id: \.self) { monthStart in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(monthStart, format: .dateTime.month(.wide).year())
                                .font(.afterflowDisplay(20))
                                .foregroundStyle(AF.text)

                            self.monthGrid(for: monthStart)

                            if !self.monthHasSessions(monthStart) {
                                Text("No sessions this month")
                                    .font(.afterflowBody(12))
                                    .foregroundStyle(AF.neutral(500))
                            }
                        }
                        .id(monthStart)
                    }
                }
                .padding(.horizontal, DesignConstants.Spacing.large)
                .padding(.vertical)
            }
            .contentMargins(.bottom, 110, for: .scrollContent)
            .onAppear {
                if let selectedDate = self.listViewModel.selectedDate {
                    let calendar = Calendar.current
                    let monthStart = calendar.startOfMonth(for: selectedDate)
                    proxy.scrollTo(monthStart, anchor: .top)
                }
            }
            .navigationDestination(isPresented: self.$navigateToSession) {
                if let sessionID = self.selection,
                   let session = self.sessions.first(where: { $0.id == sessionID }) {
                    SessionDetailView(session: session)
                        .environment(self.sessionStore)
                }
            }
        }
    }

    /// Newest month first — the current month sits at the top and older
    /// months are reached by scrolling down.
    private var monthRange: [Date] {
        CalendarGridHelper.generateMonthRange(from: self.sessions).reversed()
    }

    private var markedDates: [Date: Color] {
        CalendarGridHelper.calendarMarkers(from: self.sessions)
    }

    private func monthHasSessions(_ monthStart: Date) -> Bool {
        let calendar = Calendar.current
        return self.sessions.contains {
            calendar.isDate($0.sessionDate, equalTo: monthStart, toGranularity: .month)
        }
    }

    private func monthGrid(for monthStart: Date) -> some View {
        let calendar = Calendar.current
        let gridDays = CalendarGridHelper.generateGridDaysForMonth(monthStart)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        let marked = self.markedDates

        return VStack(spacing: 6) {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0 ..< 7, id: \.self) { index in
                    let weekdayIndex = (calendar.firstWeekday + index - 1) % 7 + 1
                    let weekdaySymbol = calendar.veryShortWeekdaySymbols[weekdayIndex - 1]
                    Text(weekdaySymbol)
                        .font(.afterflowBody(11, weight: .semibold))
                        .foregroundStyle(AF.neutral(500))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(0 ..< gridDays.count, id: \.self) { index in
                    if let date = gridDays[index] {
                        self.dayCell(for: date, markedDates: marked)
                    } else {
                        Color.clear
                            .frame(width: 38, height: 38)
                    }
                }
            }
        }
    }

    private func dayCell(for date: Date, markedDates: [Date: Color]) -> some View {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let normalizedDate = calendar.startOfDay(for: date)
        let markerColor = markedDates[normalizedDate]

        let isSelected: Bool = {
            guard let selectedID = self.selection,
                  let selectedSession = self.sessions.first(where: { $0.id == selectedID })
            else { return false }
            return calendar.startOfDay(for: selectedSession.sessionDate) == normalizedDate
        }()

        return Text("\(day)")
            .font(.afterflowBody(15, weight: markerColor != nil ? .semibold : .regular))
            .foregroundStyle(markerColor != nil ? Color("Treatment/ink") : AF.neutral(700))
            .frame(width: 38, height: 38)
            .background(
                Circle().fill(markerColor ?? .clear)
            )
            .overlay {
                if isToday {
                    Circle()
                        .stroke(AF.accent(200), lineWidth: 3)
                        .padding(-1.5)
                }
            }
            .overlay {
                if isSelected {
                    Circle()
                        .stroke(AF.text, lineWidth: 1.5)
                        .padding(-4)
                }
            }
            .onTapGesture {
                if let idx = self.listViewModel.indexOfFirstSession(on: date, in: self.sessions) {
                    let session = self.sessions[idx]
                    self.listViewModel.selectedDate = normalizedDate
                    self.selection = session.id
                    // In compact mode, trigger navigation while keeping calendar visible
                    if self.horizontalSizeClass == .compact {
                        self.navigateToSession = true
                        self.onDaySelected()
                    }
                }
            }
            .accessibilityLabel(self.dayAccessibilityLabel(for: date, hasSession: markerColor != nil))
    }

    private func dayAccessibilityLabel(for date: Date, hasSession: Bool) -> String {
        let base = date.formatted(date: .complete, time: .omitted)
        return hasSession ? "\(base), has sessions" : base
    }
}
