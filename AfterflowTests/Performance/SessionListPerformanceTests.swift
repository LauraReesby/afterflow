@testable import Afterflow
import Foundation
import SwiftData
import Testing

@MainActor
struct SessionListPerformanceTests {
    @Test("View model filters 1k sessions quickly") func listViewModelPerformance() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: nil,
            sortOption: .moodChange
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        #expect(filtered.count == 1000)
        #expect(duration < 0.5)
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
        #expect(duration < 0.8)
    }

    // MARK: - Large Dataset Performance Tests

    @Test("Filtering 10k sessions completes quickly") func filteringTenThousandSessions() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 10000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: .psilocybin,
            sortOption: .newestFirst
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        // Should filter quickly even with 10k sessions
        #expect(duration < 2.0)
        #expect(filtered.count > 0)
    }

    @Test("Searching through 1k sessions is fast") func searchingThousandSessions() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "healing",
            treatmentFilter: nil,
            sortOption: .newestFirst
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        // Search should be fast
        #expect(duration < 0.5)
    }

    @Test("Searching through 5k sessions stays performant") func searchingFiveThousandSessions() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 5000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "journey",
            treatmentFilter: nil,
            sortOption: .newestFirst
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        // Search should complete in reasonable time even with 5k sessions
        #expect(duration < 1.5)
    }

    // MARK: - Sort Algorithm Performance

    @Test("Sorting by date descending is fast") func sortByDateDescending() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: nil,
            sortOption: .newestFirst
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        #expect(duration < 0.5)
        #expect(filtered.count == 1000)
        // Verify sort order
        if filtered.count > 1 {
            #expect(filtered[0].sessionDate >= filtered[1].sessionDate)
        }
    }

    @Test("Sorting by date ascending is fast") func sortByDateAscending() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: nil,
            sortOption: .oldestFirst
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        #expect(duration < 0.5)
        #expect(filtered.count == 1000)
        // Verify sort order
        if filtered.count > 1 {
            #expect(filtered[0].sessionDate <= filtered[1].sessionDate)
        }
    }

    @Test("Sorting by mood change is fast") func sortByMoodChange() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: nil,
            sortOption: .moodChange
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        #expect(duration < 0.5)
        #expect(filtered.count == 1000)
    }

    // MARK: - Cache Performance

    @Test("Cache hit provides fast results") func cacheHitPerformance() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: .psilocybin,
            sortOption: .newestFirst
        )

        // First call to populate cache
        _ = viewModel.applyFilters(to: sessions)

        // Second call should hit cache and be very fast
        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        // Cache hit should be extremely fast
        #expect(duration < 0.1)
        #expect(filtered.count > 0)
    }

    @Test("Cache miss with filter change is acceptable") func cacheMissPerformance() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: .psilocybin,
            sortOption: .newestFirst
        )

        // First call with psilocybin filter
        _ = viewModel.applyFilters(to: sessions)

        // Change filter to cause cache miss
        viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: .ketamine,
            sortOption: .newestFirst
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        // Cache miss should still be reasonably fast
        #expect(duration < 0.5)
    }

    // MARK: - Export/Import Performance

    @Test("CSV export of 1k sessions completes quickly") func csvExportPerformance() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let service = CSVExportService()

        var csvURL: URL?
        let duration = measureTime {
            csvURL = try? service.export(sessions: sessions)
        }

        #expect(csvURL != nil)
        #expect(duration < 2.0)
    }

    @Test("CSV export of 5k sessions stays performant") func csvExportLargeDataset() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 5000)
        let service = CSVExportService()

        var csvURL: URL?
        let duration = measureTime {
            csvURL = try? service.export(sessions: sessions)
        }

        #expect(csvURL != nil)
        // Larger dataset should still complete in reasonable time
        #expect(duration < 8.0)
    }

    @Test("PDF export of 100 sessions completes quickly") func pdfExportPerformance() async throws {
        #if canImport(PDFKit)
            let sessions = SessionFixtureFactory.makeSessions(count: 100)
            let service = PDFExportService()

            var pdfURL: URL?
            let duration = measureTime {
                pdfURL = try? service.export(sessions: sessions, options: .init(includeCoverPage: false))
            }

            #expect(pdfURL != nil)
            #expect(duration < 5.0)
        #else
            throw XCTSkip("PDFKit not available")
        #endif
    }

    @Test("CSV import of 1k sessions is performant") func csvImportPerformance() async throws {
        // Generate CSV file for 1000 sessions
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let exportService = CSVExportService()
        guard let csvURL = try? exportService.export(sessions: sessions) else {
            #expect(Bool(false), "Failed to export CSV file")
            return
        }

        let importService = CSVImportService()
        var importedSessions: [TherapeuticSession] = []
        let duration = measureTime {
            importedSessions = (try? importService.import(from: csvURL)) ?? []
        }

        // Clean up
        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 1000)
        #expect(duration < 3.0)
    }

    // MARK: - Calendar Performance

    @Test("Calendar with 365 marked dates renders quickly") func calendarRenderingPerformance() async throws {
        // Create sessions for every day of the year
        let sessions = SessionFixtureFactory.makeSessionsForCalendar(monthCount: 12)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: nil,
            sortOption: .newestFirst
        )

        var markedDates: Set<Date> = []
        let duration = measureTime {
            markedDates = viewModel.markedDates(from: sessions)
        }

        #expect(markedDates.count > 0)
        // Should compute marked dates quickly even for a full year
        #expect(duration < 0.5)
    }

    @Test("Combined filtering and sorting with 5k sessions") func combinedOperationsPerformance() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 5000)
        var viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "meditation",
            treatmentFilter: .psilocybin,
            sortOption: .moodChange
        )

        var filtered: [TherapeuticSession] = []
        let duration = measureTime {
            filtered = viewModel.applyFilters(to: sessions)
        }

        // Combined operations should still be fast
        #expect(duration < 1.5)
    }
}

private func measureTime(_ block: () -> Void) -> TimeInterval {
    let start = CFAbsoluteTimeGetCurrent()
    block()
    return CFAbsoluteTimeGetCurrent() - start
}
