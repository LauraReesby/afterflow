import SwiftData
import SwiftUI

struct SessionListSection: View {
    let sessions: [TherapeuticSession]
    @Binding var listViewModel: SessionListViewModel
    @Binding var selection: UUID?
    let sessionStore: SessionStore
    let onDelete: (IndexSet) -> Void
    let onAdd: () -> Void
    let onExport: () -> Void
    let onImport: () -> Void
    let onOpenSettings: () -> Void
    let onExampleImport: () -> Void
    let onDebugNotification: () -> Void

    @State private var scrollTarget: UUID?
    @State private var showCalendarView = false
    @State private var isSearchExpanded = false
    @State private var navigateToSessionFromCalendar = false
    @State private var pendingCalendarSelection = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if self.showCalendarView {
                    self.calendarScrollView()
                } else {
                    self.sessionList()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AF.bg)

            self.addButton
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: self.showCalendarView) { wasCalendar, isCalendar in
            // In compact mode, when switching from calendar to list after having
            // navigated from calendar, clear selection to prevent auto-navigation
            if wasCalendar, !isCalendar, self.pendingCalendarSelection {
                self.selection = nil
                self.pendingCalendarSelection = false
            }
        }
    }

    // MARK: - Header

    @ViewBuilder private func headerBlock(includeSearchAndNudge: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                self.overflowMenu
                Spacer()
            }

            Text("Sessions")
                .font(.afterflowDisplay(40))
                .tracking(-0.8)
                .foregroundStyle(AF.text)
                .padding(.top, DesignConstants.Spacing.large)

            Text(self.subheadText)
                .font(.afterflowBody(14))
                .foregroundStyle(AF.neutral(600))
                .padding(.top, 2)

            AFSegmentedControl(
                selection: self.$showCalendarView,
                options: [(false, "List"), (true, "Calendar")]
            )
            .padding(.top, DesignConstants.Spacing.large)

            if includeSearchAndNudge {
                self.searchArea
                    .padding(.top, DesignConstants.Spacing.medium)

                if self.shouldShowNudge {
                    self.reflectNudge
                        .padding(.top, DesignConstants.Spacing.medium)
                }
            }
        }
    }

    private var overflowMenu: some View {
        Menu {
            Button {
                self.onOpenSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
            .accessibilityHint("Opens settings")
            Button {
                self.onExport()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .accessibilityHint("Exports your session data")
            Button {
                self.onImport()
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .accessibilityHint("Imports session data from a file")
            Menu {
                Button {
                    self.onExampleImport()
                } label: {
                    Label("Example Import", systemImage: "doc.badge.plus")
                }
                .accessibilityHint("Imports example session data")
            } label: {
                Label("Help", systemImage: "questionmark.circle")
            }
            #if DEBUG
                Divider()
                Button {
                    self.onDebugNotification()
                } label: {
                    Label("Test Notification (5s)", systemImage: "bell.badge")
                }
                .disabled(self.sessions.isEmpty)
                .accessibilityHint("Sends a test notification in 5 seconds")
            #endif
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AF.text)
                .frame(width: 60, height: 40)
                .background(Capsule().fill(AF.neutral(100)))
                .afShadow(.sm)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("overflowMenuButton")
        .accessibilityLabel("More options")
    }

    private var subheadText: String {
        guard let latest = self.sessions.map(\.sessionDate).max() else {
            return "Nothing logged yet"
        }
        let count = SpelledNumber.text(for: self.sessions.count)
        let calendar = Calendar.current
        let lastText: String
        if calendar.isDateInToday(latest) {
            lastText = "last one today"
        } else if calendar.isDateInYesterday(latest) {
            lastText = "last one yesterday"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            lastText = "last one \(formatter.localizedString(for: latest, relativeTo: Date()))"
        }
        return "\(count.capitalized) logged · \(lastText)"
    }

    // MARK: - Search (expanded panel is replaced in the search phase)

    @ViewBuilder private var searchArea: some View {
        if self.isSearchExpanded {
            VStack(spacing: 0) {
                ExpandableSearchView(
                    searchText: self.$listViewModel.searchText,
                    treatmentFilter: self.$listViewModel.treatmentFilter,
                    sortOption: self.$listViewModel.sortOption,
                    onCollapse: {
                        withAnimation(
                            .easeInOut(duration: DesignConstants.Animation.standardDuration)
                        ) {
                            self.isSearchExpanded = false
                        }
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                    .fill(AF.neutral(100))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                    .strokeBorder(AF.neutral(200), lineWidth: 1)
            )
        } else {
            Button {
                withAnimation(
                    .easeInOut(duration: DesignConstants.Animation.standardDuration)
                ) {
                    self.isSearchExpanded = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AF.neutral(600))
                    Text(self.listViewModel.searchText.isEmpty
                        ? "Search intentions and reflections"
                        : self.listViewModel.searchText)
                        .font(.afterflowBody(15))
                        .foregroundStyle(AF.neutral(600))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(Capsule().fill(AF.neutral(200)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search sessions")
            .accessibilityHint("Tap to expand search and filter controls")
        }
    }

    // MARK: - Reflect nudge

    private var shouldShowNudge: Bool {
        self.listViewModel.searchText.isEmpty && self.oldestUnreflectedSession != nil
    }

    private var oldestUnreflectedSession: TherapeuticSession? {
        self.sessions
            .filter { $0.status == .needsReflection }
            .min(by: { $0.sessionDate < $1.sessionDate })
    }

    private var reflectNudge: some View {
        let waitingCount = self.sessions.count(where: { $0.status == .needsReflection })
        let title = waitingCount == 1
            ? "One session is waiting"
            : "\(SpelledNumber.text(for: waitingCount).capitalized) sessions are waiting"

        return HStack(spacing: DesignConstants.Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.afterflowBody(15, weight: .semibold))
                    .foregroundStyle(AF.accent2(800))
                Text("A few words is plenty.")
                    .font(.afterflowBody(13))
                    .foregroundStyle(AF.accent2(700))
            }
            Spacer(minLength: 8)
            Button {
                if let target = self.oldestUnreflectedSession {
                    self.selection = target.id
                }
            } label: {
                Text("Reflect")
                    .font(.afterflowBody(13, weight: .semibold))
                    .foregroundStyle(AF.neutral(100))
                    .padding(.vertical, 9)
                    .padding(.horizontal, 16)
                    .background(Capsule().fill(AF.accent2(700)))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("reflectNudgeButton")
            .accessibilityHint("Opens the oldest session that still needs a reflection")
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .fill(AF.accent2(200))
        )
    }

    // MARK: - Floating add button

    private var addButton: some View {
        Button(action: self.onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AF.onAccent)
                .frame(width: 60, height: 60)
                .background(Circle().fill(AF.accent))
        }
        .buttonStyle(.plain)
        .afShadow(.md)
        .padding(.trailing, 20)
        .padding(.bottom, 34)
        .accessibilityIdentifier("addSessionButton")
        .accessibilityLabel("Add Session")
        .accessibilityHint("Creates a new therapy session")
    }

    // MARK: - Calendar mode

    private func calendarMarkers() -> [Date: Color] {
        CalendarGridHelper.calendarMarkers(from: self.sessions)
    }

    private func calendarScrollView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    self.headerBlock(includeSearchAndNudge: false)
                        .padding(.horizontal, DesignConstants.Spacing.large)

                    ForEach(self.generateMonthRange(), id: \.self) { monthStart in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(monthStart, format: .dateTime.month(.wide).year())
                                .font(.headline)
                                .padding(.horizontal)

                            self.monthGrid(for: monthStart)
                        }
                        .id(monthStart)
                    }
                }
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
            .navigationDestination(isPresented: self.$navigateToSessionFromCalendar) {
                if let sessionID = self.selection,
                   let session = self.sessions.first(where: { $0.id == sessionID }) {
                    SessionDetailView(session: session)
                        .environment(self.sessionStore)
                }
            }
        }
    }

    private func monthGrid(for monthStart: Date) -> some View {
        let calendar = Calendar.current
        let gridDays = self.generateGridDaysForMonth(monthStart)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        let markedDates = self.calendarMarkers()

        return VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0 ..< 7, id: \.self) { index in
                    let weekdayIndex = (calendar.firstWeekday + index - 1) % 7 + 1
                    let weekdaySymbol = calendar.veryShortWeekdaySymbols[weekdayIndex - 1]
                    Text(weekdaySymbol)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(0 ..< gridDays.count, id: \.self) { index in
                    if let date = gridDays[index] {
                        self.dayCell(for: date, in: monthStart, markedDates: markedDates)
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func dayCell(for date: Date, in monthStart: Date, markedDates: [Date: Color])
        -> some View {
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
            .font(.body)
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundColor(markerColor != nil ? .white : .primary)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(markerColor ?? (isToday ? Color.accentColor.opacity(0.2) : Color.clear))
            )
            .overlay(
                Circle()
                    .stroke(
                        isToday && markerColor == nil ? Color.accentColor : Color.clear,
                        lineWidth: 1
                    )
            )
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
                    .padding(-2)
            )
            .onTapGesture {
                if let idx = self.listViewModel.indexOfFirstSession(on: date, in: self.sessions) {
                    let session = self.sessions[idx]
                    self.listViewModel.selectedDate = normalizedDate
                    self.selection = session.id
                    // In compact mode, trigger navigation while keeping calendar visible
                    if self.horizontalSizeClass == .compact {
                        self.navigateToSessionFromCalendar = true
                        self.pendingCalendarSelection = true
                    }
                }
            }
    }

    // MARK: - List mode

    @ViewBuilder private func sessionList() -> some View {
        ScrollViewReader { proxy in
            List(selection: self.$selection) {
                self.headerBlock(includeSearchAndNudge: true)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(
                        .init(
                            top: DesignConstants.Spacing.small,
                            leading: DesignConstants.Spacing.large,
                            bottom: DesignConstants.Spacing.medium,
                            trailing: DesignConstants.Spacing.large
                        )
                    )
                    .selectionDisabled(true)

                ForEach(Array(self.sessions.enumerated()), id: \.element.id) { index, session in
                    self.buildSessionRow(session: session, index: index)
                }
                .onDelete(perform: self.onDelete)
            }
            .scrollContentBackground(.hidden)
            .background(AF.bg)
            .listSectionSeparator(.hidden)
            .listStyle(.plain)
            .tint(.clear)
            .scrollBounceBehavior(.basedOnSize)
            .coordinateSpace(name: "listScroll")
            .scrollDismissesKeyboard(.immediately)
            .contentMargins(.bottom, 130, for: .scrollContent)
            .onChange(of: self.scrollTarget) { _, target in
                guard let target else { return }
                withAnimation(.easeInOut(duration: DesignConstants.Animation.standardDuration)) {
                    proxy.scrollTo("session-\(target.uuidString)", anchor: .top)
                }
            }
            .onPreferenceChange(TopVisibleDatePreferenceKey.self) { date in
                if let date {
                    let normalized = Calendar.current.startOfDay(for: date)
                    Task { @MainActor in
                        self.listViewModel.selectedDate = normalized
                    }
                }
            }
        }
    }
}

private extension SessionListSection {
    func buildSessionRow(session: TherapeuticSession, index: Int) -> some View {
        let isSelected = self.selection == session.id
        let isFirst = index == 0
        let isLast = index == self.sessions.count - 1

        return NavigationLink(value: session.id) {
            SessionRowView(session: session, dateText: session.sessionDate.relativeSessionLabel)
        }
        .accessibilityIdentifier("sessionRow-\(session.id.uuidString)")
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                let frame = geo.frame(in: .named("listScroll"))
                let isCandidate = frame.minY > 0 && frame.minY < 300
                let candidateDate: Date? = isCandidate ? session.sessionDate : nil

                Color.clear
                    .preference(key: TopVisibleDatePreferenceKey.self, value: candidateDate)
            }
        )
        .id("session-\(session.id.uuidString)")
        .listRowBackground(
            SessionRowCardBackground(
                isFirst: isFirst,
                isLast: isLast,
                isHighlighted: isSelected
            )
        )
        .listRowSeparator(.hidden)
        .listRowInsets(
            .init(
                top: 14,
                leading: DesignConstants.Spacing.large * 2,
                bottom: 14,
                trailing: DesignConstants.Spacing.large * 2
            )
        )
        .contextMenu {
            Button(role: .destructive) {
                self.onDelete(IndexSet(integer: index))
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityHint("Deletes this session permanently")
        } preview: {
            SessionDetailView(session: session)
                .frame(width: 350, height: 600)
                .environment(self.sessionStore)
        }
    }
}

/// Rows share a single rounded card: the first and last rows round the card's
/// corners, and every row after the first draws a 1px hairline at its top.
private struct SessionRowCardBackground: View {
    let isFirst: Bool
    let isLast: Bool
    let isHighlighted: Bool

    var body: some View {
        let radius = DesignConstants.CornerRadius.card
        UnevenRoundedRectangle(
            topLeadingRadius: self.isFirst ? radius : 0,
            bottomLeadingRadius: self.isLast ? radius : 0,
            bottomTrailingRadius: self.isLast ? radius : 0,
            topTrailingRadius: self.isFirst ? radius : 0,
            style: .continuous
        )
        .fill(self.isHighlighted ? AF.neutral(200) : AF.neutral(100))
        .overlay(alignment: .top) {
            if !self.isFirst {
                Rectangle()
                    .fill(AF.neutral(200))
                    .frame(height: 1)
                    .padding(.horizontal, DesignConstants.Spacing.large)
            }
        }
        .padding(.horizontal, DesignConstants.Spacing.large)
    }
}

private enum SpelledNumber {
    private static let words = [
        "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen",
        "eighteen", "nineteen", "twenty"
    ]

    static func text(for value: Int) -> String {
        guard value >= 0, value < self.words.count else { return "\(value)" }
        return self.words[value]
    }
}

private extension SessionListSection {
    func generateMonthRange() -> [Date] {
        CalendarGridHelper.generateMonthRange(from: self.sessions)
    }

    func generateGridDaysForMonth(_ monthStart: Date) -> [Date?] {
        CalendarGridHelper.generateGridDaysForMonth(monthStart)
    }
}

private struct TopVisibleDatePreferenceKey: PreferenceKey {
    static var defaultValue: Date?
    static func reduce(value: inout Date?, nextValue: () -> Date?) {
        if value == nil {
            value = nextValue()
        }
    }
}
