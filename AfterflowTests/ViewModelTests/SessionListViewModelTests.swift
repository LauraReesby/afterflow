@testable import Afterflow
import Foundation
import Testing

@MainActor
struct SessionListViewModelTests {
    @Test("Applies treatment filter and sorts newest first") func treatmentFilterAndSort() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 5)
        var viewModel = SessionListViewModel()
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

        var viewModel = SessionListViewModel()
        viewModel.sortOption = .moodChange

        let sorted = viewModel.applyFilters(to: sessions)
        #expect(sorted.first?.moodChange ?? 0 >= sorted.last?.moodChange ?? 0)
    }

    @Test("Search text filters intentions") func searchFiltering() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 6)
        var viewModel = SessionListViewModel()
        viewModel.searchText = "Fixture Session 3"

        let filtered = viewModel.applyFilters(to: sessions)
        #expect(filtered.count == 1)
        #expect(filtered.first?.intention.contains("3") == true)
    }

    

    @Test("Marked dates returns unique start of days") func markedDatesReturnsUniqueStartOfDays() async throws {
        let calendar = Calendar.current
        let baseDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 15)

        let sessions = [
            TherapeuticSession(
                sessionDate: baseDate,
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test 1",
                moodBefore: 5,
                moodAfter: 8
            ),
            TherapeuticSession(
                sessionDate: calendar.date(byAdding: .hour, value: 5, to: baseDate)!,
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test 2",
                moodBefore: 5,
                moodAfter: 8
            ),
            TherapeuticSession(
                sessionDate: calendar.date(byAdding: .day, value: 1, to: baseDate)!,
                treatmentType: .lsd,
                administration: .oral,
                intention: "Test 3",
                moodBefore: 5,
                moodAfter: 8
            )
        ]

        let viewModel = SessionListViewModel()
        let markedDates = viewModel.markedDates(from: sessions)

        #expect(markedDates.count == 2) 
        #expect(markedDates.contains(calendar.startOfDay(for: baseDate)))
        #expect(markedDates.contains(calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: baseDate)!)))
    }

    @Test("Marked dates normalizes to midnight") func markedDatesNormalizesToMidnight() async throws {
        let calendar = Calendar.current
        let dateWithTime = TestHelpers.dateComponents(year: 2024, month: 12, day: 15, hour: 14, minute: 30)

        let sessions = [
            TherapeuticSession(
                sessionDate: dateWithTime,
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test",
                moodBefore: 5,
                moodAfter: 8
            )
        ]

        let viewModel = SessionListViewModel()
        let markedDates = viewModel.markedDates(from: sessions)

        let markedDate = markedDates.first!
        let components = calendar.dateComponents([.hour, .minute, .second], from: markedDate)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    @Test("Marked dates handles empty sessions") func markedDatesHandlesEmptySessions() async throws {
        let viewModel = SessionListViewModel()
        let markedDates = viewModel.markedDates(from: [])

        #expect(markedDates.isEmpty)
    }

    

    @Test("Index of first session finds correct index") func indexOfFirstSessionFindsCorrectIndex() async throws {
        let calendar = Calendar.current
        let date1 = TestHelpers.dateComponents(year: 2024, month: 12, day: 10)
        let date2 = TestHelpers.dateComponents(year: 2024, month: 12, day: 15)
        let date3 = TestHelpers.dateComponents(year: 2024, month: 12, day: 20)

        let sessions = [
            TherapeuticSession(
                sessionDate: date1,
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test 1",
                moodBefore: 5,
                moodAfter: 8
            ),
            TherapeuticSession(
                sessionDate: date2,
                treatmentType: .lsd,
                administration: .oral,
                intention: "Test 2",
                moodBefore: 5,
                moodAfter: 8
            ),
            TherapeuticSession(
                sessionDate: date3,
                treatmentType: .mdma,
                administration: .oral,
                intention: "Test 3",
                moodBefore: 5,
                moodAfter: 8
            )
        ]

        let viewModel = SessionListViewModel()
        let index = viewModel.indexOfFirstSession(on: date2, in: sessions)

        #expect(index == 1)
    }

    @Test("Index of first session returns nil when not found")
    func indexOfFirstSessionReturnsNilWhenNotFound() async throws {
        let date1 = TestHelpers.dateComponents(year: 2024, month: 12, day: 10)
        let searchDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 25)

        let sessions = [
            TherapeuticSession(
                sessionDate: date1,
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test 1",
                moodBefore: 5,
                moodAfter: 8
            )
        ]

        let viewModel = SessionListViewModel()
        let index = viewModel.indexOfFirstSession(on: searchDate, in: sessions)

        #expect(index == nil)
    }

    

    @Test("Clear filters clears treatment filter") func clearFiltersClearsTreatmentFilter() async throws {
        var viewModel = SessionListViewModel()
        viewModel.treatmentFilter = .psilocybin
        viewModel.sortOption = .moodChange

        viewModel.clearFilters()

        #expect(viewModel.treatmentFilter == nil)
        #expect(viewModel.sortOption == .moodChange) 
    }

    @Test("Clear filters clears search text") func clearFiltersClearsSearchText() async throws {
        var viewModel = SessionListViewModel()
        viewModel.searchText = "test query"
        viewModel.sortOption = .newestFirst

        viewModel.clearFilters()

        #expect(viewModel.searchText == "")
        #expect(viewModel.sortOption == .newestFirst) 
    }

    @Test("Clear filters does not affect sort option") func clearFiltersDoesNotAffectSortOption() async throws {
        var viewModel = SessionListViewModel()
        viewModel.treatmentFilter = .mdma
        viewModel.searchText = "test"
        viewModel.sortOption = .oldestFirst

        viewModel.clearFilters()

        #expect(viewModel.sortOption == .oldestFirst)
    }

    

    @Test("Cache hit when inputs unchanged") func cacheHitWhenInputsUnchanged() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 10)
        var viewModel = SessionListViewModel()

        let result1 = viewModel.applyFilters(to: sessions)
        let result2 = viewModel.applyFilters(to: sessions)

        
        #expect(result1.count == result2.count)
        #expect(zip(result1, result2).allSatisfy { $0.0.id == $0.1.id })
    }

    @Test("Cache miss when sessions change") func cacheMissWhenSessionsChange() async throws {
        let sessions1 = SessionFixtureFactory.makeSessions(count: 5)
        let sessions2 = SessionFixtureFactory.makeSessions(count: 10)
        var viewModel = SessionListViewModel()

        let result1 = viewModel.applyFilters(to: sessions1)
        let result2 = viewModel.applyFilters(to: sessions2)

        #expect(result1.count == 5)
        #expect(result2.count == 10)
    }

    @Test("Cache miss when filters change") func cacheMissWhenFiltersChange() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 10)
        var viewModel = SessionListViewModel()

        let result1 = viewModel.applyFilters(to: sessions)

        viewModel.treatmentFilter = .psilocybin
        let result2 = viewModel.applyFilters(to: sessions)

        #expect(result1.count >= result2.count) 
    }

    

    @Test("Apply filters with empty sessions") func applyFiltersWithEmptySessions() async throws {
        var viewModel = SessionListViewModel()
        viewModel.treatmentFilter = .psilocybin
        viewModel.searchText = "test"

        let filtered = viewModel.applyFilters(to: [])

        #expect(filtered.isEmpty)
    }

    @Test("Search text with whitespace only") func searchTextWithWhitespaceOnly() async throws {
        let sessions = SessionFixtureFactory.makeSessions(count: 5)
        var viewModel = SessionListViewModel()
        viewModel.searchText = "   \n\t   "

        let filtered = viewModel.applyFilters(to: sessions)

        #expect(filtered.count == sessions.count) 
    }

    @Test("Current filter description formats correctly") func currentFilterDescriptionFormats() async throws {
        var viewModel = SessionListViewModel()

        
        #expect(viewModel.currentFilterDescription == "Newest First")

        
        viewModel.treatmentFilter = .psilocybin
        #expect(viewModel.currentFilterDescription.contains("Psilocybin"))
        #expect(viewModel.currentFilterDescription.contains("Newest First"))

        
        viewModel.sortOption = .moodChange
        #expect(viewModel.currentFilterDescription.contains("Psilocybin"))
        #expect(viewModel.currentFilterDescription.contains("Biggest Mood Lift"))
    }

    @Test("Search filters reflections as well as intentions") func searchFiltersReflections() async throws {
        let sessions = [
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Explore creativity",
                moodBefore: 5,
                moodAfter: 8,
                reflections: "Amazing insights about art"
            ),
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .lsd,
                administration: .oral,
                intention: "Healing",
                moodBefore: 4,
                moodAfter: 9,
                reflections: "Felt peaceful"
            )
        ]

        var viewModel = SessionListViewModel()
        viewModel.searchText = "insights"

        let filtered = viewModel.applyFilters(to: sessions)

        #expect(filtered.count == 1)
        #expect(filtered.first?.reflections.contains("insights") == true)
    }

    @Test("Search is case insensitive") func searchIsCaseInsensitive() async throws {
        let sessions = [
            TherapeuticSession(
                sessionDate: Date(),
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "EXPLORE CREATIVITY",
                moodBefore: 5,
                moodAfter: 8
            )
        ]

        var viewModel = SessionListViewModel()
        viewModel.searchText = "explore"

        let filtered = viewModel.applyFilters(to: sessions)

        #expect(filtered.count == 1)
    }

    @Test("Mood change sort uses date as tiebreaker") func moodChangeSortUsesDateAsTiebreaker() async throws {
        let date1 = TestHelpers.dateComponents(year: 2024, month: 12, day: 10)
        let date2 = TestHelpers.dateComponents(year: 2024, month: 12, day: 15)

        let sessions = [
            TherapeuticSession(
                sessionDate: date1,
                treatmentType: .psilocybin,
                administration: .oral,
                intention: "Test 1",
                moodBefore: 5,
                moodAfter: 8
            ), 
            TherapeuticSession(
                sessionDate: date2,
                treatmentType: .lsd,
                administration: .oral,
                intention: "Test 2",
                moodBefore: 5,
                moodAfter: 8
            ) 
        ]

        var viewModel = SessionListViewModel()
        viewModel.sortOption = .moodChange

        let sorted = viewModel.applyFilters(to: sessions)

        
        #expect(sorted.first?.sessionDate == date2)
    }
}
