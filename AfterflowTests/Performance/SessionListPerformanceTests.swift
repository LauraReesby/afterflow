@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct SessionListPerformanceTests {
    @Test("View model filters 1k sessions quickly") func listViewModelPerformance() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let viewModel = SessionListViewModel(sortOption: .moodChange, treatmentFilter: nil, searchText: "")

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        #expect(filtered.count == 1000)
        #expect(duration < 0.2)
    }

    @Test("Fetching 1k sessions stays performant")
    @MainActor func fetchPerformance() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let context = container.mainContext

        for session in SessionFixtureFactory.makeSessions(count: 1000) {
            context.insert(session)
        }
        try context.save()

        var fetched: [TherapeuticSession] = []
        let duration = measureTime {
            let descriptor = FetchDescriptor<TherapeuticSession>(sortBy: [SortDescriptor(
                \.sessionDate,
                order: .reverse
            )])
            fetched = (try? context.fetch(descriptor)) ?? []
        }

        #expect(fetched.count == 1000)
        #expect(duration < 0.4)
    }
}

private func measureTime(_ block: () -> Void) -> TimeInterval {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    return CFAbsoluteTimeGetCurrent() - start
}
