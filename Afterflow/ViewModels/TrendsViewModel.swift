import Foundation

/// On-device aggregate computations for the Trends screen. Stateless over the
/// session array, like `SessionListViewModel` — no network, no analytics.
struct TrendsViewModel {
    enum TrendsRange: String, CaseIterable, Identifiable {
        case threeMonths
        case sixMonths
        case all

        var id: String { self.rawValue }

        var label: String {
            switch self {
            case .threeMonths: "3 months"
            case .sixMonths: "6 months"
            case .all: "All time"
            }
        }

        var months: Int? {
            switch self {
            case .threeMonths: 3
            case .sixMonths: 6
            case .all: nil
            }
        }
    }

    var range: TrendsRange = .threeMonths

    func filteredSessions(
        from sessions: [TherapeuticSession],
        now: Date = Date()
    ) -> [TherapeuticSession] {
        guard let months = self.range.months,
              let cutoff = Calendar.current.date(byAdding: .month, value: -months, to: now)
        else {
            return sessions.sorted { $0.sessionDate < $1.sessionDate }
        }
        return sessions
            .filter { $0.sessionDate >= cutoff }
            .sorted { $0.sessionDate < $1.sessionDate }
    }

    /// Before-mood series over every session in range, ascending by date.
    func beforePoints(from sessions: [TherapeuticSession], now: Date = Date()) -> [(date: Date, mood: Int)] {
        self.filteredSessions(from: sessions, now: now).map { ($0.sessionDate, $0.moodBefore) }
    }

    /// After-mood series — only sessions with a recorded after-mood.
    func afterPoints(from sessions: [TherapeuticSession], now: Date = Date()) -> [(date: Date, mood: Int)] {
        self.filteredSessions(from: sessions, now: now)
            .filter(\.hasAfterMood)
            .map { ($0.sessionDate, $0.moodAfter) }
    }

    func averageLift(from sessions: [TherapeuticSession], now: Date = Date()) -> Double? {
        let reflected = self.filteredSessions(from: sessions, now: now).filter(\.hasAfterMood)
        guard !reflected.isEmpty else { return nil }
        return Double(reflected.reduce(0) { $0 + $1.moodChange }) / Double(reflected.count)
    }

    func reflectedCount(from sessions: [TherapeuticSession], now: Date = Date()) -> Int {
        self.filteredSessions(from: sessions, now: now).count { $0.status == .complete }
    }

    func averageMoodAfter(from sessions: [TherapeuticSession], now: Date = Date()) -> Double? {
        let reflected = self.filteredSessions(from: sessions, now: now).filter(\.hasAfterMood)
        guard !reflected.isEmpty else { return nil }
        return Double(reflected.reduce(0) { $0 + $1.moodAfter }) / Double(reflected.count)
    }

    func meanDaysBetween(from sessions: [TherapeuticSession], now: Date = Date()) -> Double? {
        let dates = self.filteredSessions(from: sessions, now: now).map(\.sessionDate)
        guard dates.count >= 2 else { return nil }
        let gaps = zip(dates.dropFirst(), dates).map { later, earlier in
            later.timeIntervalSince(earlier) / 86_400
        }
        return gaps.reduce(0, +) / Double(gaps.count)
    }

    /// Average mood lift per treatment. `nil` lift means the treatment has no
    /// sessions with a recorded after-mood — render "—", dim, and exclude it.
    /// Never silently average incomplete data.
    func liftByTreatment(
        from sessions: [TherapeuticSession],
        now: Date = Date()
    ) -> [(treatment: PsychedelicTreatmentType, lift: Double?)] {
        let inRange = self.filteredSessions(from: sessions, now: now)
        let grouped = Dictionary(grouping: inRange, by: \.treatmentType)
        return grouped
            .map { treatment, group -> (PsychedelicTreatmentType, Double?) in
                let reflected = group.filter(\.hasAfterMood)
                guard !reflected.isEmpty else { return (treatment, nil) }
                let lift = Double(reflected.reduce(0) { $0 + $1.moodChange }) / Double(reflected.count)
                return (treatment, lift)
            }
            .sorted { lhs, rhs in
                switch (lhs.1, rhs.1) {
                case let (l?, r?): l > r
                case (_?, nil): true
                case (nil, _?): false
                case (nil, nil): lhs.0.displayName < rhs.0.displayName
                }
            }
    }

    func exclusionFootnote(from sessions: [TherapeuticSession], now: Date = Date()) -> String? {
        let inRange = self.filteredSessions(from: sessions, now: now)
        let unreflected = inRange.filter { !$0.hasAfterMood }
        guard !unreflected.isEmpty else { return nil }

        let excludedTreatments = self.liftByTreatment(from: sessions, now: now)
            .filter { $0.lift == nil }
            .map(\.treatment.displayName)

        let countText = unreflected.count == 1
            ? "One session still has no after-mood"
            : "\(unreflected.count) sessions still have no after-mood"

        if excludedTreatments.isEmpty {
            return "\(countText); those sessions sit out of the averages."
        }
        let names = excludedTreatments.joined(separator: " and ")
        let verb = excludedTreatments.count == 1 ? "sits" : "sit"
        return "\(countText), so \(names) \(verb) out of the average."
    }

    /// Word frequencies over the user's own reflection text — computed on
    /// device only, consistent with the privacy constitution.
    func wordFrequencies(
        from sessions: [TherapeuticSession],
        now: Date = Date(),
        limit: Int = 8
    ) -> [(word: String, count: Int)] {
        let text = self.filteredSessions(from: sessions, now: now)
            .map(\.reflections)
            .joined(separator: " ")
            .lowercased()

        var counts: [String: Int] = [:]
        var current = ""
        for character in text {
            if character.isLetter || character == "'" {
                current.append(character)
            } else {
                Self.tally(&counts, word: current)
                current = ""
            }
        }
        Self.tally(&counts, word: current)

        return counts
            .sorted { lhs, rhs in
                lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key < rhs.key
            }
            .prefix(limit)
            .map { ($0.key, $0.value) }
    }

    private static func tally(_ counts: inout [String: Int], word: String) {
        let cleaned = word.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
        guard cleaned.count >= 3, !self.stopWords.contains(cleaned) else { return }
        counts[cleaned, default: 0] += 1
    }

    private static let stopWords: Set<String> = [
        "the", "and", "was", "were", "that", "this", "with", "for", "from",
        "have", "has", "had", "not", "are", "but", "its", "it's", "all",
        "into", "out", "off", "over", "under", "then", "than", "them",
        "they", "their", "there", "here", "what", "when", "where", "which",
        "who", "how", "why", "can", "could", "would", "should", "will",
        "just", "still", "very", "more", "most", "some", "any", "each",
        "about", "after", "before", "during", "these", "those", "been",
        "being", "because", "you", "your", "our", "his", "her", "she",
        "him", "did", "does", "doing", "don't", "didn't", "i'm", "i've",
        "it", "its", "let", "may", "might", "much", "now", "one", "two",
        "own", "too", "way", "also", "felt", "feel", "feeling", "session",
        "sessions", "today"
    ]
}
