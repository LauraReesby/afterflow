@testable import Afterflow
import Foundation

enum SessionFixtureFactory {
    /// Returns deterministic session fixtures by reusing the shared seed factory.
    static func makeSessions(count: Int, referenceDate: Date = Date()) -> [TherapeuticSession] {
        var sessions = SeedDataFactory.makeSeedSessions(referenceDate: referenceDate)
        guard count > sessions.count else { return Array(sessions.prefix(count)) }

        let treatments = PsychedelicTreatmentType.allCases
        for index in sessions.count ..< count {
            let offset = index - sessions.count + 1
            let session = TherapeuticSession(
                sessionDate: referenceDate.addingTimeInterval(TimeInterval(-offset * 86400)),
                treatmentType: treatments[index % treatments.count],
                administration: .oral,
                intention: "Fixture Session \(index)",
                moodBefore: (index % 10) + 1,
                moodAfter: ((index + 3) % 10) + 1,
                reflections: index.isMultiple(of: 2) ? "Short reflection \(index)" : "",
                reminderDate: index.isMultiple(of: 4) ? referenceDate
                    .addingTimeInterval(TimeInterval(900 * (index + 1))) : nil
            )
            sessions.append(session)
        }

        return sessions
    }
}
