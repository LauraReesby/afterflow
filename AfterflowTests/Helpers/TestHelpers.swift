@testable import Afterflow
import Foundation
import SwiftData

enum TestHelpers {
    

    
    @MainActor static func makeTestEnvironment() throws -> (ModelContainer, SessionStore) {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: TherapeuticSession.self, configurations: config)
        let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
        return (container, store)
    }

    

    
    @MainActor static func makeExportState(sessionStore: SessionStore? = nil) throws -> ExportState {
        let store = try sessionStore ?? self.makeTestEnvironment().1
        return ExportState()
    }

    
    @MainActor static func makeImportState(sessionStore: SessionStore? = nil) throws -> ImportState {
        let store = try sessionStore ?? self.makeTestEnvironment().1
        return ImportState(sessionStore: store)
    }

    
    static func makeSessionListViewModel(
        searchText: String = "",
        treatmentFilter: PsychedelicTreatmentType? = nil,
        sortOption: SessionListViewModel.SortOption = .newestFirst
    ) -> SessionListViewModel {
        var viewModel = SessionListViewModel()
        viewModel.searchText = searchText
        viewModel.treatmentFilter = treatmentFilter
        viewModel.sortOption = sortOption
        return viewModel
    }

    

    
    static func makeCalendarTestData(monthCount: Int = 3, sessionsPerMonth: Int = 5) -> [TherapeuticSession] {
        var sessions: [TherapeuticSession] = []
        let calendar = Calendar.current
        let referenceDate = self.fixedDate()

        for monthOffset in 0 ..< monthCount {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: referenceDate) else {
                continue
            }

            for dayOffset in 0 ..< sessionsPerMonth {
                guard let sessionDate = calendar.date(byAdding: .day, value: dayOffset * 5, to: monthDate) else {
                    continue
                }

                let session = TherapeuticSession(
                    sessionDate: sessionDate,
                    treatmentType: .psilocybin,
                    administration: .oral,
                    intention: "Calendar session \(monthOffset)-\(dayOffset)",
                    moodBefore: 5,
                    moodAfter: 7,
                    reflections: "",
                    reminderDate: nil
                )
                sessions.append(session)
            }
        }

        return sessions
    }

    

    
    static func fixedDate() -> Date {
        var components = DateComponents()
        components.year = 2024
        components.month = 12
        components.day = 1
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)

        return Calendar.current.date(from: components) ?? Date()
    }

    
    static func monthStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    
    static func dateComponents(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: 0)

        return Calendar.current.date(from: components) ?? Date()
    }

    
    static func weekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }

    
    static func startOfDay(for date: Date) -> Date {
        let calendar = Calendar.current
        return calendar.startOfDay(for: date)
    }

    

    
    static func waitFor(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 1.0,
        pollingInterval: TimeInterval = 0.01
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)

        while !condition() {
            if Date() > deadline {
                throw TestError.timeout
            }
            try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
        }
    }

    
    static func makeTemporaryFileURL(filename: String) -> URL {
        let temporaryDirectory = FileManager.default.temporaryDirectory
        return temporaryDirectory.appendingPathComponent(filename)
    }
}



enum TestError: Error {
    case timeout
    case setupFailed
    case teardownFailed
}
