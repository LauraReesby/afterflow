@testable import Afterflow
import Foundation
import Testing

@MainActor
struct TrendsViewModelTests {
    private func makeSession(
        daysAgo: Int,
        treatment: PsychedelicTreatmentType = .psilocybin,
        moodBefore: Int = 4,
        moodAfter: Int? = 5,
        reflections: String = ""
    ) -> TherapeuticSession {
        let session = TherapeuticSession(
            sessionDate: Date().addingTimeInterval(TimeInterval(-daysAgo * 86400)),
            treatmentType: treatment,
            administration: .oral,
            intention: "Test",
            moodBefore: moodBefore,
            moodAfter: moodAfter,
            reflections: reflections
        )
        return session
    }

    @Test("Range filtering keeps only recent sessions, ascending") func rangeFiltering() throws {
        let recent = self.makeSession(daysAgo: 10)
        let older = self.makeSession(daysAgo: 70)
        let ancient = self.makeSession(daysAgo: 400)

        var viewModel = TrendsViewModel()
        viewModel.range = .threeMonths
        let threeMonths = viewModel.filteredSessions(from: [recent, ancient, older])
        #expect(threeMonths.count == 2)
        #expect(threeMonths.first?.id == older.id)

        viewModel.range = .all
        #expect(viewModel.filteredSessions(from: [recent, ancient, older]).count == 3)
    }

    @Test("After series excludes sessions without a recorded after-mood") func afterSeriesExcludesSentinels() throws {
        let reflected = self.makeSession(daysAgo: 5, moodAfter: 8, reflections: "Grounded.")
        let unreflected = self.makeSession(daysAgo: 3, moodAfter: nil)

        let viewModel = TrendsViewModel()
        let after = viewModel.afterPoints(from: [reflected, unreflected])
        #expect(after.count == 1)
        #expect(after.first?.mood == 8)
        #expect(viewModel.beforePoints(from: [reflected, unreflected]).count == 2)
    }

    @Test("Lift by treatment excludes and marks treatments without after-moods")
    func liftByTreatmentExclusion() throws {
        let psilocybin = self.makeSession(
            daysAgo: 5,
            treatment: .psilocybin,
            moodBefore: 4,
            moodAfter: 7,
            reflections: "x"
        )
        let lsdNoAfter = self.makeSession(daysAgo: 6, treatment: .lsd, moodBefore: 5, moodAfter: nil)

        let viewModel = TrendsViewModel()
        let rows = viewModel.liftByTreatment(from: [psilocybin, lsdNoAfter])

        let psilocybinRow = try #require(rows.first { $0.treatment == .psilocybin })
        #expect(psilocybinRow.lift == 3.0)

        let lsdRow = try #require(rows.first { $0.treatment == .lsd })
        #expect(lsdRow.lift == nil)

        let footnote = try #require(viewModel.exclusionFootnote(from: [psilocybin, lsdNoAfter]))
        #expect(footnote.contains("LSD"))
    }

    @Test("Average lift only counts reflected sessions") func averageLift() throws {
        let up = self.makeSession(daysAgo: 2, moodBefore: 4, moodAfter: 8, reflections: "x")
        let down = self.makeSession(daysAgo: 4, moodBefore: 6, moodAfter: 4, reflections: "y")
        let sentinel = self.makeSession(daysAgo: 6, moodBefore: 3, moodAfter: nil)

        let viewModel = TrendsViewModel()
        #expect(viewModel.averageLift(from: [up, down, sentinel]) == 1.0)
        #expect(viewModel.averageLift(from: [sentinel]) == nil)
    }

    @Test("Mean days between sessions") func meanDaysBetween() throws {
        let first = self.makeSession(daysAgo: 20)
        let second = self.makeSession(daysAgo: 10)
        let third = self.makeSession(daysAgo: 0)

        let viewModel = TrendsViewModel()
        let mean = try #require(viewModel.meanDaysBetween(from: [first, second, third]))
        #expect(abs(mean - 10) < 0.01)
        #expect(viewModel.meanDaysBetween(from: [first]) == nil)
    }

    @Test("Word frequencies are deterministic, stopword-free, on-device text only") func wordFrequencies() throws {
        let one = self.makeSession(daysAgo: 1, reflections: "The grief moved through me. Grief takes time.")
        let two = self.makeSession(daysAgo: 2, reflections: "Openness and grief and warmth. Openness stayed.")

        let viewModel = TrendsViewModel()
        let words = viewModel.wordFrequencies(from: [one, two], limit: 3)

        #expect(words.first?.word == "grief")
        #expect(words.first?.count == 3)
        #expect(words.contains { $0.word == "openness" && $0.count == 2 })
        #expect(!words.contains { $0.word == "the" || $0.word == "and" })
    }
}
