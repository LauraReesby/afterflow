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
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if self.showCalendarView {
                    self.calendarScrollView()
                } else {
                    self.sessionList()
                }
            }
            .navigationTitle("Sessions")
            .toolbar { self.toolbarContent }
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)

            SearchControlBar(
                listViewModel: self.$listViewModel,
                showCalendarView: self.$showCalendarView,
                isSearchExpanded: self.$isSearchExpanded,
                onAdd: self.onAdd
            )
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

    private func calendarMarkers() -> [Date: Color] {
        CalendarGridHelper.calendarMarkers(from: self.sessions)
    }

    private func calendarScrollView() -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
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
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 88)
            }
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

    @ViewBuilder private func sessionList() -> some View {
        ScrollViewReader { proxy in
            List(selection: self.$selection) {
                ForEach(Array(self.sessions.enumerated()), id: \.element.id) { index, session in
                    self.buildSessionRow(session: session, index: index)
                }
                .onDelete(perform: self.onDelete)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .listRowInsets(
                .init(
                    top: DesignConstants.Spacing.small,
                    leading: DesignConstants.Spacing.large,
                    bottom: DesignConstants.Spacing.small,
                    trailing: DesignConstants.Spacing.large
                )
            )
            .listSectionSeparator(.hidden)
            .listStyle(.plain)
            .tint(.clear)
            .scrollBounceBehavior(.basedOnSize)
            .coordinateSpace(name: "listScroll")
            .toolbarBackground(.visible, for: .automatic)
            .scrollDismissesKeyboard(.immediately)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 88)
            }
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
            .onAppear {
                Task { @MainActor in
                    if let firstSession = self.sessions.first {
                        self.scrollTarget = firstSession.id
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
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
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("More options")
        }
    }
}

private extension SessionListSection {
    func buildSessionRow(session: TherapeuticSession, index: Int) -> some View {
        let isSelected = self.selection == session.id

        return NavigationLink(value: session.id) {
            SessionRowView(session: session, dateText: session.sessionDate.relativeSessionLabel)
                .padding(.vertical, -4)
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
        .listRowBackground(isSelected ? Color(uiColor: .systemGroupedBackground) : Color(.systemBackground))
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
        .listRowSeparator(index == 0 ? .hidden : .visible, edges: .top)
        .listRowSeparator(.visible, edges: .bottom)
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
