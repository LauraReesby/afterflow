import SwiftData
import SwiftUI

struct SessionListSection: View {
    let sessions: [TherapeuticSession]
    /// The unfiltered session set — feeds the subhead count and the Trends screen.
    var allSessions: [TherapeuticSession]?
    @Binding var listViewModel: SessionListViewModel
    @Binding var selection: UUID?
    let sessionStore: SessionStore
    let onDelete: (IndexSet) -> Void
    let onAdd: () -> Void
    let onReflect: (UUID) -> Void
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
    @State private var showingTrends = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if self.showCalendarView {
                    CalendarSection(
                        sessions: self.sessions,
                        listViewModel: self.$listViewModel,
                        selection: self.$selection,
                        sessionStore: self.sessionStore,
                        navigateToSession: self.$navigateToSessionFromCalendar,
                        onDaySelected: { self.pendingCalendarSelection = true }
                    ) {
                        self.headerBlock(includeSearchAndNudge: false)
                    }
                } else {
                    self.sessionList()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AF.bg)

            self.addButton
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: self.$showingTrends) {
            TrendsView(sessions: self.allSessions ?? self.sessions) { word in
                self.showingTrends = false
                self.showCalendarView = false
                self.listViewModel.searchText = word
                self.isSearchExpanded = true
            }
        }
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
                self.trendsPill
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

                if self.hasActiveQuery, !self.sessions.isEmpty {
                    self.resultLine
                        .padding(.top, DesignConstants.Spacing.medium)
                } else if self.shouldShowNudge {
                    self.reflectNudge
                        .padding(.top, DesignConstants.Spacing.medium)
                }
            }
        }
    }

    private var hasActiveQuery: Bool {
        !self.listViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var resultLine: some View {
        let query = self.listViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = self.sessions.count
        let noun = count == 1 ? "session mentions" : "sessions mention"

        return HStack {
            Text("\(SpelledNumber.text(for: count).capitalized) \(noun) \u{201C}\(query)\u{201D}")
                .font(.afterflowBody(13, weight: .semibold))
                .foregroundStyle(AF.accent(800))
            Spacer(minLength: 8)
            Button {
                self.listViewModel.searchText = ""
            } label: {
                Text("Clear")
                    .font(.afterflowBody(12, weight: .semibold))
                    .foregroundStyle(AF.neutral(600))
            }
            .buttonStyle(AFLinkButtonStyle())
            .accessibilityLabel("Clear search")
            .accessibilityHint("Empties the search query")
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

    private var trendsPill: some View {
        Button {
            self.showingTrends = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12, weight: .semibold))
                Text("Trends")
                    .font(.afterflowBody(13, weight: .semibold))
            }
            .foregroundStyle(AF.accent(800))
            .padding(.horizontal, 14)
            .frame(height: 40)
        }
        .buttonStyle(AFCapsuleButtonStyle(fill: AF.accent(200), pressedFill: AF.accent(300)))
        .accessibilityIdentifier("trendsButton")
        .accessibilityLabel("Trends")
        .accessibilityHint("Shows your mood over time")
    }

    private var subheadText: String {
        guard let latest = self.sessions.map(\.sessionDate).max() else {
            return "Nothing logged yet"
        }
        let count = SpelledNumber.text(for: (self.allSessions ?? self.sessions).count)

        if self.showCalendarView {
            let quarterCount = SpelledNumber.text(for: self.sessionsThisQuarter)
            return "\(count.capitalized) logged · \(quarterCount) this quarter"
        }

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

    private var sessionsThisQuarter: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentQuarter = (calendar.component(.month, from: now) - 1) / 3
        return self.sessions.count { session in
            calendar.component(.year, from: session.sessionDate) == currentYear
                && (calendar.component(.month, from: session.sessionDate) - 1) / 3 == currentQuarter
        }
    }

    // MARK: - Search (expanded panel is replaced in the search phase)

    @ViewBuilder private var searchArea: some View {
        if self.isSearchExpanded {
            SearchPanel(
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
            }
            .buttonStyle(AFCapsuleButtonStyle(fill: AF.neutral(200), pressedFill: AF.neutral(300)))
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
                    self.onReflect(target.id)
                }
            } label: {
                Text("Reflect")
                    .font(.afterflowBody(13, weight: .semibold))
                    .foregroundStyle(AF.neutral(100))
                    .padding(.vertical, 9)
                    .padding(.horizontal, 16)
            }
            .buttonStyle(AFCapsuleButtonStyle(fill: AF.accent2(700), pressedFill: AF.accent2(800)))
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

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            if self.hasActiveQuery {
                let query = self.listViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                Text("No matches for \u{201C}\(query)\u{201D}")
                    .font(.afterflowDisplay(20))
                    .foregroundStyle(AF.text)
                Text("Try another word, or clear the search.")
                    .font(.afterflowBody(14))
                    .foregroundStyle(AF.neutral(600))
            } else {
                Text("No sessions yet")
                    .font(.afterflowDisplay(20))
                    .foregroundStyle(AF.text)
                Text("Tap + to log your first.")
                    .font(.afterflowBody(14))
                    .foregroundStyle(AF.neutral(600))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DesignConstants.Spacing.lg)
    }

    // MARK: - Floating add button

    private var addButton: some View {
        Button(action: self.onAdd) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(AF.onAccent)
                .frame(width: 60, height: 60)
        }
        .buttonStyle(AFCircleButtonStyle(fill: AF.accent, pressedFill: AF.accentPressed))
        .afShadow(.md)
        .padding(.trailing, 20)
        .padding(.bottom, 34)
        .accessibilityIdentifier("addSessionButton")
        .accessibilityLabel("Add Session")
        .accessibilityHint("Creates a new therapy session")
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

                if self.sessions.isEmpty {
                    self.emptyState
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .selectionDisabled(true)
                }

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
            SessionRowView(
                session: session,
                dateText: session.sessionDate.relativeSessionLabel,
                reflectionSnippet: self.listViewModel.matchingReflectionSnippet(for: session)
            )
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

private struct TopVisibleDatePreferenceKey: PreferenceKey {
    static var defaultValue: Date?
    static func reduce(value: inout Date?, nextValue: () -> Date?) {
        if value == nil {
            value = nextValue()
        }
    }
}
