import SwiftUI

/// The in-content header shared by the list and calendar surfaces: overflow
/// menu, Trends pill, title + live subhead, List ⇄ Calendar segmented control,
/// and (list only) the search area, result line, and reflect nudge.
struct SessionListHeader: View {
    let sessions: [TherapeuticSession]
    /// The unfiltered session set — feeds the subhead count.
    let totalSessions: [TherapeuticSession]
    @Binding var listViewModel: SessionListViewModel
    @Binding var showCalendarView: Bool
    @Binding var isSearchExpanded: Bool
    @Binding var showingTrends: Bool
    let includeSearchAndNudge: Bool
    let onReflect: (UUID) -> Void
    let onExport: () -> Void
    let onImport: () -> Void
    let onOpenSettings: () -> Void
    let onExampleImport: () -> Void
    let onDebugNotification: () -> Void

    var body: some View {
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

            if self.includeSearchAndNudge {
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
        let count = SpelledNumber.text(for: self.totalSessions.count)

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

    // MARK: - Search

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
}

/// Spelled-out counts for the header's conversational copy.
enum SpelledNumber {
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
