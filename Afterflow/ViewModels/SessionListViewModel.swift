import Foundation

struct SessionListViewModel {
    enum SortOption: String, CaseIterable, Identifiable {
        case newestFirst
        case oldestFirst
        case moodChange

        var id: String { self.rawValue }

        var label: String {
            switch self {
            case .newestFirst:
                "Newest First"
            case .oldestFirst:
                "Oldest First"
            case .moodChange:
                "Biggest Mood Lift"
            }
        }
    }

    var sortOption: SortOption = .newestFirst
    var treatmentFilter: PsychedelicTreatmentType?
    var searchText: String = ""
    var selectedDate: Date?

    // MARK: - Performance Optimization (Memoization)

    private var cachedFilteredSessions: [TherapeuticSession] = []
    private var lastSessionsHash: Int = 0
    private var lastFilterHash: Int = 0

    mutating func applyFilters(to sessions: [TherapeuticSession]) -> [TherapeuticSession] {
        let currentSessionsHash = sessions.map(\.id).hashValue
        let currentFilterHash = self.filterHash

        // Return cached result if inputs haven't changed
        if currentSessionsHash == self.lastSessionsHash, currentFilterHash == self.lastFilterHash {
            return self.cachedFilteredSessions
        }

        // Update cache tracking
        self.lastSessionsHash = currentSessionsHash
        self.lastFilterHash = currentFilterHash

        // Perform filtering
        var filtered = sessions

        if let treatmentFilter {
            filtered = filtered.filter { $0.treatmentType == treatmentFilter }
        }

        let trimmedQuery = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            let normalizedQuery = trimmedQuery.lowercased()
            filtered = filtered.filter { session in
                session.intention.lowercased().contains(normalizedQuery) ||
                    session.reflections.lowercased().contains(normalizedQuery)
            }
        }

        switch self.sortOption {
        case .newestFirst:
            filtered.sort { $0.sessionDate > $1.sessionDate }
        case .oldestFirst:
            filtered.sort { $0.sessionDate < $1.sessionDate }
        case .moodChange:
            filtered.sort {
                $0.moodChange == $1.moodChange
                    ? $0.sessionDate > $1.sessionDate
                    : $0.moodChange > $1.moodChange
            }
        }

        // Cache and return result
        self.cachedFilteredSessions = filtered
        return filtered
    }

    private var filterHash: Int {
        var hasher = Hasher()
        hasher.combine(self.sortOption)
        hasher.combine(self.treatmentFilter)
        hasher.combine(self.searchText)
        return hasher.finalize()
    }

    func markedDates(from sessions: [TherapeuticSession]) -> Set<Date> {
        let cal = Calendar.current
        return Set(sessions.map { cal.startOfDay(for: $0.sessionDate) })
    }

    func indexOfFirstSession(on date: Date, in sessions: [TherapeuticSession]) -> Int? {
        let cal = Calendar.current
        let day = cal.startOfDay(for: date)
        return sessions.firstIndex { cal.isDate(cal.startOfDay(for: $0.sessionDate), inSameDayAs: day) }
    }

    var currentFilterDescription: String {
        if let treatmentFilter {
            return "\(treatmentFilter.displayName) • \(self.sortOption.label)"
        }
        return self.sortOption.label
    }

    mutating func clearFilters() {
        self.treatmentFilter = nil
        self.searchText = ""
    }
}
