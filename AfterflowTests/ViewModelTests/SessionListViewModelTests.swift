@testable import Afterflow
import Testing

@MainActor
struct SessionListViewModelTests {
    @Test("Applies treatment filter and sorts newest first") func treatmentFilterAndSort() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 5)
        let viewModel = SessionListViewModel()
        viewModel.treatmentFilter = .psilocybin
        viewModel.sortOption = .newestFirst

        let filtered = viewModel.applyFilters(to: sessions)
        #expect(filtered.allSatisfy { $0.treatmentType == .psilocybin })
        #expect(filtered == filtered.sorted { $0.sessionDate > $1.sessionDate })
    }

    @Test("Sorts by mood change when requested") func sortByMoodChange() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 10)
        sessions[0].moodBefore = 2
        sessions[0].moodAfter = 9
        sessions[1].moodBefore = 7
        sessions[1].moodAfter = 6

        let viewModel = SessionListViewModel()
        viewModel.sortOption = .moodChange

        let sorted = viewModel.applyFilters(to: sessions)
        #expect(sorted.first?.moodChange ?? 0 >= sorted.last?.moodChange ?? 0)
    }

    @Test("Search text filters intentions") func searchFiltering() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 6)
        let viewModel = SessionListViewModel()
        viewModel.searchText = "Fixture Session 3"

        let filtered = viewModel.applyFilters(to: sessions)
        #expect(filtered.count == 1)
        #expect(filtered.first?.intention.contains("3") == true)
    }
}
