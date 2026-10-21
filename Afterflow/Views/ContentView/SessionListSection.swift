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
                        onDaySelected: { self.pendingCalendarSelection = true },
                        header: { self.headerBlock(includeSearchAndNudge: false) }
                    )
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

    private func headerBlock(includeSearchAndNudge: Bool) -> some View {
        SessionListHeader(
            sessions: self.sessions,
            totalSessions: self.allSessions ?? self.sessions,
            listViewModel: self.$listViewModel,
            showCalendarView: self.$showCalendarView,
            isSearchExpanded: self.$isSearchExpanded,
            showingTrends: self.$showingTrends,
            includeSearchAndNudge: includeSearchAndNudge,
            onReflect: self.onReflect,
            onExport: self.onExport,
            onImport: self.onImport,
            onOpenSettings: self.onOpenSettings,
            onExampleImport: self.onExampleImport,
            onDebugNotification: self.onDebugNotification
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 4) {
            let query = self.listViewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !query.isEmpty {
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

    private func sessionList() -> some View {
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

        return SessionRowView(
            session: session,
            dateText: session.sessionDate.relativeSessionLabel,
            reflectionSnippet: self.listViewModel.matchingReflectionSnippet(for: session)
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        // Selection-driven navigation: tapping sets the selection, which the
        // split view resolves to the detail (including the compact push) — no
        // NavigationLink, and therefore no disclosure chevron accessory. The
        // explicit gesture is required because tag-only selection ignores taps
        // in compact width.
        .tag(session.id)
        .onTapGesture {
            self.selection = session.id
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("sessionRow-\(session.id.uuidString)")
        .background(self.scrollTrackingBackground(for: session))
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

    /// Feeds the calendar's anchor month from the topmost visible row.
    func scrollTrackingBackground(for session: TherapeuticSession) -> some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .named("listScroll"))
            let isCandidate = frame.minY > 0 && frame.minY < 300
            let candidateDate: Date? = isCandidate ? session.sessionDate : nil

            Color.clear
                .preference(key: TopVisibleDatePreferenceKey.self, value: candidateDate)
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

private struct TopVisibleDatePreferenceKey: PreferenceKey {
    static var defaultValue: Date?
    static func reduce(value: inout Date?, nextValue: () -> Date?) {
        if value == nil {
            value = nextValue()
        }
    }
}
