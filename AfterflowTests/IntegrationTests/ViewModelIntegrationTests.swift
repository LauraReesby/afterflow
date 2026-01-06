@testable import Afterflow
import Foundation
import SwiftData
import Testing

@Suite("ViewModel Integration Tests")
@MainActor
struct ViewModelIntegrationTests {
    @Test("SessionListViewModel with live SwiftData store") func listViewModelWithLiveStore() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let context = container.mainContext

        let sessions = SessionFixtureFactory.makeSessions(count: 10)
        for session in sessions {
            context.insert(session)
        }
        try context.save()

        let descriptor = FetchDescriptor<TherapeuticSession>(sortBy: [SortDescriptor(\.sessionDate, order: .reverse)])
        let fetchedSessions = try context.fetch(descriptor)

        let viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: nil,
            sortOption: .newestFirst
        )

        let filtered = viewModel.applyFilters(to: fetchedSessions)

        #expect(filtered.count == 10)
        #expect(filtered[0].sessionDate >= filtered[9].sessionDate)
    }

    @Test("SessionListViewModel filtering with live data") func listViewModelFilteringLiveData() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let context = container.mainContext

        let psilocybin = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .psilocybin,
            administration: .oral,
            intention: "Healing journey",
            moodBefore: 4,
            moodAfter: 8
        )
        let ketamine = TherapeuticSession(
            sessionDate: Date(),
            treatmentType: .ketamine,
            administration: .nasal,
            intention: "Reset session",
            moodBefore: 3,
            moodAfter: 7
        )

        context.insert(psilocybin)
        context.insert(ketamine)
        try context.save()

        let descriptor = FetchDescriptor<TherapeuticSession>()
        let allSessions = try context.fetch(descriptor)

        let viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: .psilocybin,
            sortOption: .newestFirst
        )

        let filtered = viewModel.applyFilters(to: allSessions)

        #expect(filtered.count == 1)
        #expect(filtered[0].treatmentType == .psilocybin)
    }

    @Test("SessionListViewModel search with live data") func listViewModelSearchLiveData() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let context = container.mainContext

        let sessions = [
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Healing journey",
                moodBefore: 5,
                moodAfter: 8
            ),
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .lsd,
                administration: .oral,
                intention: "Creative exploration",
                moodBefore: 6,
                moodAfter: 9
            )
        ]

        for session in sessions {
            context.insert(session)
        }
        try context.save()

        let descriptor = FetchDescriptor<TherapeuticSession>()
        let allSessions = try context.fetch(descriptor)

        let viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "healing",
            treatmentFilter: nil,
            sortOption: .newestFirst
        )

        let filtered = viewModel.applyFilters(to: allSessions)

        #expect(filtered.count == 1)
        #expect(filtered[0].intention.contains("Healing"))
    }

    @Test("Import CSV then filter in SessionListViewModel") func importThenFilterWorkflow() async throws {
        let sessions = [
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Psilocybin session",
                moodBefore: 5,
                moodAfter: 8
            ),
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .ketamine,
                administration: .nasal,
                intention: "Ketamine session",
                moodBefore: 4,
                moodAfter: 7
            )
        ]

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: sessions)

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        let viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: .psilocybin,
            sortOption: .newestFirst
        )

        let filtered = viewModel.applyFilters(to: importedSessions)

        #expect(filtered.count == 1)
        #expect(filtered[0].treatmentType == .psilocybin)
    }

    @Test("Filter sessions then export") func filterThenExportWorkflow() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 20)

        let viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "",
            treatmentFilter: .psilocybin,
            sortOption: .newestFirst
        )

        let filtered = viewModel.applyFilters(to: sessions)

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: filtered)

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.allSatisfy { $0.treatmentType == .psilocybin })
    }

    @Test("Search, filter, then export workflow") func searchFilterExportWorkflow() async throws {
        let sessions = [
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Healing journey",
                moodBefore: 5,
                moodAfter: 8
            ),
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Creative exploration",
                moodBefore: 6,
                moodAfter: 9
            ),
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .ketamine,
                administration: .nasal,
                intention: "Healing reset",
                moodBefore: 4,
                moodAfter: 7
            )
        ]

        let viewModel = TestHelpers.makeSessionListViewModel(
            searchText: "healing",
            treatmentFilter: .psilocybin,
            sortOption: .newestFirst
        )

        let filtered = viewModel.applyFilters(to: sessions)

        #expect(filtered.count == 1)
        #expect(filtered[0].intention == "Healing journey")

        let exportService = CSVExportService()
        let csvURL = try exportService.export(sessions: filtered)

        let importService = CSVImportService()
        let importedSessions = try importService.import(from: csvURL)

        try? FileManager.default.removeItem(at: csvURL)

        #expect(importedSessions.count == 1)
        #expect(importedSessions[0].intention == "Healing journey")
        #expect(importedSessions[0].treatmentType == .psilocybin)
    }
}
