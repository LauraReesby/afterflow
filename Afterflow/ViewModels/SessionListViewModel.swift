import Combine
import Foundation

final class SessionListViewModel: ObservableObject {
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

    @Published var sortOption: SortOption = .newestFirst
    @Published var treatmentFilter: PsychedelicTreatmentType?
    @Published var searchText: String = ""
    @Published var selectedDate: Date?

    init(
        sortOption: SortOption = .newestFirst,
        treatmentFilter: PsychedelicTreatmentType? = nil,
        searchText: String = "",
        selectedDate: Date? = nil
    ) {
        self.sortOption = sortOption
        self.treatmentFilter = treatmentFilter
        self.searchText = searchText
        self.selectedDate = selectedDate
    }

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

    func clearFilters() {
        self.treatmentFilter = nil
        self.searchText = ""
    }
}
