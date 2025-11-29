@testable import Afterflow
import Foundation

enum SessionFixtureFactory {
    static func makeSessions(count: Int) -> [TherapeuticSession] {
        let calendar = Calendar.current
        return (0 ..< count).map { index in
            let date = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            let moodBefore = max(1, (index % 10) + 1)
            let moodAfter = min(10, moodBefore + Int.random(in: -2 ... 4))
            let treatment = PsychedelicTreatmentType.allCases[index % PsychedelicTreatmentType.allCases.count]

            let session = TherapeuticSession(
                sessionDate: date,
                treatmentType: treatment,
                administration: .oral,
                intention: "Fixture Session \(index)",
                environmentNotes: "Fixture environment \(index)",
                musicNotes: "Ambient playlist \(index)",
                moodBefore: moodBefore,
                moodAfter: moodAfter,
                reflections: index.isMultiple(of: 2) ? "Reflection \(index)" : ""
            )
            return session
        }
    }
}
