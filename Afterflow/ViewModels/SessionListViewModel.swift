import Foundation

struct SessionListViewModel {
    enum SortOption: String, CaseIterable, Identifiable {
        case newestFirst
        case oldestFirst
        case moodChange

        var id: String {
            self.rawValue
        }

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

    func applyFilters(to sessions: [TherapeuticSession]) -> [TherapeuticSession] {
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

        return filtered
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

    /// Returns the passage of the session's reflection text that matches the active
    /// query, expanded to roughly ±60 characters around the hit, with ellipses when
    /// the passage is clipped. `nil` when the query is empty or only the intention
    /// matched — the quote block is evidence of a reflection match specifically.
    func matchingReflectionSnippet(for session: TherapeuticSession) -> String? {
        let query = self.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }

        let reflections = session.reflections
        guard let matchRange = reflections.range(
            of: query,
            options: [.caseInsensitive, .diacriticInsensitive]
        ) else { return nil }

        let contextRadius = 60
        var start = reflections.index(
            matchRange.lowerBound,
            offsetBy: -contextRadius,
            limitedBy: reflections.startIndex
        ) ?? reflections.startIndex
        var end = reflections.index(
            matchRange.upperBound,
            offsetBy: contextRadius,
            limitedBy: reflections.endIndex
        ) ?? reflections.endIndex

        // Snap outward-facing edges to word boundaries so the quote reads naturally.
        if start > reflections.startIndex {
            while start > reflections.startIndex, !reflections[reflections.index(before: start)].isWhitespace {
                start = reflections.index(before: start)
            }
        }
        if end < reflections.endIndex {
            while end < reflections.endIndex, !reflections[end].isWhitespace {
                end = reflections.index(after: end)
            }
        }

        var snippet = String(reflections[start ..< end])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
        if start > reflections.startIndex {
            snippet = "…" + snippet
        }
        if end < reflections.endIndex {
            snippet += "…"
        }
        return snippet
    }
}
