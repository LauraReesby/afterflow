@testable import Afterflow
import Foundation

enum SessionFixtureFactory {
    static func makeSessions(count: Int, referenceDate: Date = Date()) -> [TherapeuticSession] {
        var sessions: [TherapeuticSession] = []
        let treatments = PsychedelicTreatmentType.allCases

        for index in 0 ..< count {
            let session = TherapeuticSession(
                sessionDate: referenceDate.addingTimeInterval(TimeInterval(-index * 86400)),
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

    static func makeSeedSessions(referenceDate: Date = Date()) -> [TherapeuticSession] {
        SeedDataFactory.makeSeedSessions(referenceDate: referenceDate)
    }
}
