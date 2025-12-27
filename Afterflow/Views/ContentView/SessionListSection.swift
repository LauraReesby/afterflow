import SwiftData
import SwiftUI

// swiftlint:disable:next type_body_length
struct SessionListSection: View {
    let sessions: [TherapeuticSession]
    @Binding var listViewModel: SessionListViewModel
    @Binding var navigationPath: NavigationPath
    let sessionStore: SessionStore
    let onDelete: (IndexSet) -> Void
    let onAdd: () -> Void
    let onExport: () -> Void
    let onImport: () -> Void
    let onOpenSettings: () -> Void
    let onExampleImport: () -> Void
    let onDebugNotification: () -> Void

    @State private var scrollTarget: UUID?
    @State private var calendarMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var calendarMode: CollapsibleCalendarView.DisplayMode = .twoWeeks
    @State private var pendingCalendarMonth: Date?
    @State private var suppressListSync = false
    @State private var calendarCenterOnMonth: Date?
    @State private var collapsedHeaderSyncEnabled = false
    @State private var isSearchExpanded = false

    var body: some View {
        NavigationStack(path: self.$navigationPath) {
            VStack(spacing: 0) {
                self.buildCalendarView()
                self.sessionList()
            }
            .toolbar { self.toolbarContent }
            .toolbarBackground(self.isSearchExpanded ? .hidden : .visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: UUID.self) { sessionID in
                if let session = self.sessions.first(where: { $0.id == sessionID }) {
                    SessionDetailView(session: session)
                        .environment(self.sessionStore)
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if self.isSearchExpanded {
                    FullWidthSearchBar(
                        searchText: self.$listViewModel.searchText,
                        isExpanded: self.$isSearchExpanded
                    )
                    .background(Color(.systemBackground))
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }
            }
            .animation(
                .spring(response: DesignConstants.Animation.springResponse,
                        dampingFraction: DesignConstants.Animation.springDampingFraction),
                value: self.isSearchExpanded
            )
        }
    }

    private func buildCalendarView() -> some View {
        CollapsibleCalendarView(
            selectedDate: self.$listViewModel.selectedDate,
            currentMonth: self.$calendarMonth,
            mode: self.$calendarMode,
            markedDates: self.calendarMarkers(),
            centerOnMonth: self.$calendarCenterOnMonth,
            onSelect: { date in
                self.focusCalendar(on: date)
            }
        )
        .padding(.bottom, 4)
    }

    private func calendarMarkers() -> [Date: Color] {
        let calendar = Calendar.current
        return self.sessions.reduce(into: [:]) { result, session in
            let day = calendar.startOfDay(for: session.sessionDate)
            if result[day] == nil {
                result[day] = session.treatmentType.accentColor
            }
        }
    }

    private func focusCalendar(on date: Date) {
        
        let normalized = Calendar.current.startOfDay(for: date)
        let monthStart = Calendar.current.startOfMonth(for: normalized)

        
        self.calendarMonth = monthStart

        
        self.listViewModel.selectedDate = normalized

        if let idx = self.listViewModel.indexOfFirstSession(on: normalized, in: self.sessions) {
            let session = self.sessions[idx]
            
            self.pendingCalendarMonth = monthStart
            self.suppressListSync = true
            self.scrollTarget = session.id
        } else {
            self.pendingCalendarMonth = nil
        }

        
        self.calendarCenterOnMonth = nil
    }

    @ViewBuilder private func sessionList() -> some View {
        ScrollViewReader { proxy in
            List {
                ForEach(Array(self.sessions.enumerated()), id: \.element.id) { index, session in
                    self.buildSessionRow(session: session, index: index)
                }
                .onDelete(perform: self.onDelete)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .listRowInsets(.init(
                top: DesignConstants.Spacing.small,
                leading: DesignConstants.Spacing.large,
                bottom: DesignConstants.Spacing.small,
                trailing: DesignConstants.Spacing.large
            ))
            .listSectionSeparator(.hidden)
            .listStyle(.plain)
            .scrollBounceBehavior(.basedOnSize)
            .coordinateSpace(name: "listScroll")
            .simultaneousGesture(self.calendarCollapseGesture())
            .toolbarBackground(.visible, for: .automatic)
            .scrollDismissesKeyboard(.immediately)
            .onChange(of: self.scrollTarget) { _, target in
                guard let target else { return }
                withAnimation(.easeInOut(duration: DesignConstants.Animation.standardDuration)) {
                    proxy.scrollTo("session-\(target.uuidString)", anchor: .top)
                }
            }
            .onPreferenceChange(TopVisibleDatePreferenceKey.self) { date in
                self.handleTopVisibleDateChange(date)
            }
            .onAppear {
                if let firstSession = self.sessions.first {
                    self.scrollTarget = firstSession.id
                }
            }
            .onChange(of: self.calendarMonth) { _, _ in
                if self.pendingCalendarMonth == nil {
                    
                    self.suppressListSync = true
                }
            }
            .onChange(of: self.calendarMode) { old, new in
                self.handleCalendarModeChange(old: old, new: new)
            }
        }
    }

    private func calendarCollapseGesture() -> some Gesture {
        DragGesture(minimumDistance: 30)
            .onEnded { value in
                let velocity = value.translation.height

                if velocity < -50, self.calendarMode == .month {
                    withAnimation(.easeInOut(duration: DesignConstants.Animation.standardDuration)) {
                        self.calendarMode = .twoWeeks
                    }
                }
            }
    }

    private func handleTopVisibleDateChange(_ date: Date?) {
        guard let date else { return }

        
        let normalized = Calendar.current.startOfDay(for: date)
        self.listViewModel.selectedDate = normalized

        
        let monthStart = Calendar.current.startOfMonth(for: normalized)

        
        if self.calendarMode == .twoWeeks, self.collapsedHeaderSyncEnabled, monthStart != self.calendarMonth {
            withAnimation(.easeInOut(duration: DesignConstants.Animation.quickDuration)) {
                self.calendarMonth = monthStart
            }
        }

        
        if let pending = self.pendingCalendarMonth,
           Calendar.current.isDate(monthStart, equalTo: pending, toGranularity: .month) {
            self.pendingCalendarMonth = nil
            return
        }

        
        if self.pendingCalendarMonth != nil { return }

        
        if monthStart != self.calendarMonth {
            withAnimation(.easeInOut(duration: DesignConstants.Animation.quickDuration)) {
                self.calendarMonth = monthStart
            }
        }
    }

    private func handleCalendarModeChange(
        old: CollapsibleCalendarView.DisplayMode,
        new: CollapsibleCalendarView.DisplayMode
    ) {
        guard old != new else { return }

        
        if new == .month {
            self.collapsedHeaderSyncEnabled = false
        } else if new == .twoWeeks {
            
            DispatchQueue.main.async {
                self.collapsedHeaderSyncEnabled = true
            }
        }

        
        if new == .month {
            if let selected = self.listViewModel.selectedDate {
                let normalized = Calendar.current.startOfDay(for: selected)
                let monthStart = Calendar.current.startOfMonth(for: normalized)
                
                self.pendingCalendarMonth = monthStart
                self.suppressListSync = true
                self.calendarMonth = monthStart
                
                self.calendarCenterOnMonth = monthStart
                if let idx = self.listViewModel.indexOfFirstSession(on: normalized, in: self.sessions) {
                    let session = self.sessions[idx]
                    self.scrollTarget = session.id
                }
            }
        }
    }

    private func buildSessionRow(session: TherapeuticSession, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .leading) {
                SessionRowView(session: session, dateText: session.sessionDate.relativeSessionLabel)
                    .padding(.vertical, -4)
                    .accessibilityIdentifier("sessionRow-\(session.id.uuidString)")
                NavigationLink(value: session.id) { EmptyView() }
                    .opacity(0)
            }
        }
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if !self.isSearchExpanded {
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
                        .padding(.horizontal, 2)
                }
                .accessibilityLabel("More options")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DesignConstants.Spacing.medium) {
                    FilterMenu(listViewModel: self.$listViewModel)

                    Button {
                        self.isSearchExpanded.toggle()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                    }
                    .accessibilityLabel("Search")
                    .accessibilityHint("Opens the search bar to find sessions")

                    Button(action: self.onAdd) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                    }
                    .accessibilityIdentifier("addSessionButton")
                    .accessibilityLabel("Add Session")
                    .accessibilityHint("Opens a form to create a new session")
                }
            }
        }
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
