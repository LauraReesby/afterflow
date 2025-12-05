@testable import Afterflow
import Foundation

enum SessionFixtureFactory {
    static func makeSessions(count: Int) -> [TherapeuticSession] {
        let calendar = Calendar.current
        return (0 ..< count).map { index in
            let now = Date()
            let moodBefore = (index % 10) + 1
            let moodAfter = ((index + 3) % 10) + 1
            let treatment = PsychedelicTreatmentType.allCases[index % PsychedelicTreatmentType.allCases.count]

            let session = TherapeuticSession(
                sessionDate: now.addingTimeInterval(TimeInterval(-index * 86400)),
                treatmentType: treatment,
                administration: .oral,
                intention: "Fixture Session \(index)",
                moodBefore: moodBefore,
                moodAfter: moodAfter,
                reflections: index % 2 == 0 ? "Short reflection \(index)" : "",
                reminderDate: index % 4 == 0 ? now.addingTimeInterval(TimeInterval(900 * (index + 1))) : nil
            )
            return session
        }
    }
}
