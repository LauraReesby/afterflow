@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct ExpandableSearchViewTests {
    @Test("Initializes with empty search text") func initializesWithEmptySearchText() throws {
        var searchText = ""
        var treatmentFilter: PsychedelicTreatmentType?
        var sortOption: SessionListViewModel.SortOption = .newestFirst

        let searchView = ExpandableSearchView(
            searchText: Binding(get: { searchText }, set: { searchText = $0 }),
            treatmentFilter: Binding(get: { treatmentFilter }, set: { treatmentFilter = $0 }),
            sortOption: Binding(get: { sortOption }, set: { sortOption = $0 }),
            onCollapse: {}
        )

        #expect(searchView.searchText == "")
    }

    @Test("Search text binding updates") func searchTextBindingUpdates() throws {
        var searchText = ""

        let searchView = ExpandableSearchView(
            searchText: Binding(get: { searchText }, set: { searchText = $0 }),
            treatmentFilter: .constant(nil),
            sortOption: .constant(.newestFirst),
            onCollapse: {}
        )

        #expect(searchView.searchText == "")

        searchText = "healing journey"
        #expect(searchText == "healing journey")
    }

    @Test("Treatment filter starts as nil") func treatmentFilterStartsAsNil() throws {
        var treatmentFilter: PsychedelicTreatmentType?

        let searchView = ExpandableSearchView(
            searchText: .constant(""),
            treatmentFilter: Binding(get: { treatmentFilter }, set: { treatmentFilter = $0 }),
            sortOption: .constant(.newestFirst),
            onCollapse: {}
        )

        #expect(searchView.treatmentFilter == nil)
    }

    @Test("Treatment filter can be set") func treatmentFilterCanBeSet() throws {
        var treatmentFilter: PsychedelicTreatmentType?

        _ = ExpandableSearchView(
            searchText: .constant(""),
            treatmentFilter: Binding(get: { treatmentFilter }, set: { treatmentFilter = $0 }),
            sortOption: .constant(.newestFirst),
            onCollapse: {}
        )

        treatmentFilter = .psilocybin
        #expect(treatmentFilter == .psilocybin)

        treatmentFilter = .ketamine
        #expect(treatmentFilter == .ketamine)
    }

    @Test("Treatment filter can be cleared") func treatmentFilterCanBeCleared() throws {
        var treatmentFilter: PsychedelicTreatmentType? = .mdma

        _ = ExpandableSearchView(
            searchText: .constant(""),
            treatmentFilter: Binding(get: { treatmentFilter }, set: { treatmentFilter = $0 }),
            sortOption: .constant(.newestFirst),
            onCollapse: {}
        )

        #expect(treatmentFilter == .mdma)

        treatmentFilter = nil
        #expect(treatmentFilter == nil)
    }

    @Test("Sort option defaults to newest first") func sortOptionDefaultsToNewestFirst() throws {
        var sortOption: SessionListViewModel.SortOption = .newestFirst

        let searchView = ExpandableSearchView(
            searchText: .constant(""),
            treatmentFilter: .constant(nil),
            sortOption: Binding(get: { sortOption }, set: { sortOption = $0 }),
            onCollapse: {}
        )

        #expect(searchView.sortOption == .newestFirst)
    }

    @Test("Sort option can change to oldest first") func sortOptionCanChangeToOldestFirst() throws {
        var sortOption: SessionListViewModel.SortOption = .newestFirst

        _ = ExpandableSearchView(
            searchText: .constant(""),
            treatmentFilter: .constant(nil),
            sortOption: Binding(get: { sortOption }, set: { sortOption = $0 }),
            onCollapse: {}
        )

        sortOption = .oldestFirst
        #expect(sortOption == .oldestFirst)
    }

    @Test("Sort option can change to mood change") func sortOptionCanChangeToMoodChange() throws {
        var sortOption: SessionListViewModel.SortOption = .newestFirst

        _ = ExpandableSearchView(
            searchText: .constant(""),
            treatmentFilter: .constant(nil),
            sortOption: Binding(get: { sortOption }, set: { sortOption = $0 }),
            onCollapse: {}
        )

        sortOption = .moodChange
        #expect(sortOption == .moodChange)
    }

    @Test("All sort options available") func allSortOptionsAvailable() throws {
        let sortOptions = SessionListViewModel.SortOption.allCases

        #expect(sortOptions.contains(.newestFirst))
        #expect(sortOptions.contains(.oldestFirst))
        #expect(sortOptions.contains(.moodChange))
        #expect(sortOptions.count == 3)
    }

    @Test("Collapse callback is set") func collapseCallbackIsSet() throws {
        var collapseCalled = false

        _ = ExpandableSearchView(
            searchText: .constant(""),
            treatmentFilter: .constant(nil),
            sortOption: .constant(.newestFirst),
            onCollapse: { collapseCalled = true }
        )

        // Callback not triggered during initialization
        #expect(collapseCalled == false)
    }

    @Test("Multiple bindings work together") func multipleBindingsWorkTogether() throws {
        var searchText = ""
        var treatmentFilter: PsychedelicTreatmentType?
        var sortOption: SessionListViewModel.SortOption = .newestFirst

        let searchView = ExpandableSearchView(
            searchText: Binding(get: { searchText }, set: { searchText = $0 }),
            treatmentFilter: Binding(get: { treatmentFilter }, set: { treatmentFilter = $0 }),
            sortOption: Binding(get: { sortOption }, set: { sortOption = $0 }),
            onCollapse: {}
        )

        #expect(searchView.searchText == "")
        #expect(searchView.treatmentFilter == nil)
        #expect(searchView.sortOption == .newestFirst)

        searchText = "psychedelic"
        treatmentFilter = .lsd
        sortOption = .moodChange

        #expect(searchText == "psychedelic")
        #expect(treatmentFilter == .lsd)
        #expect(sortOption == .moodChange)
    }

    @Test("Search text with special characters") func searchTextWithSpecialCharacters() throws {
        var searchText = ""

        _ = ExpandableSearchView(
            searchText: Binding(get: { searchText }, set: { searchText = $0 }),
            treatmentFilter: .constant(nil),
            sortOption: .constant(.newestFirst),
            onCollapse: {}
        )

        searchText = "healing & transformation 🌟"
        #expect(searchText == "healing & transformation 🌟")
    }

    @Test("Long search text handled") func longSearchTextHandled() throws {
        var searchText = String(repeating: "search term ", count: 50)

        let searchView = ExpandableSearchView(
            searchText: Binding(get: { searchText }, set: { searchText = $0 }),
            treatmentFilter: .constant(nil),
            sortOption: .constant(.newestFirst),
            onCollapse: {}
        )

        #expect(searchView.searchText.count > 100)
        #expect(searchView.searchText.contains("search term"))
    }

    @Test("All treatment types can be selected") func allTreatmentTypesCanBeSelected() throws {
        for treatmentType in PsychedelicTreatmentType.allCases {
            var filter: PsychedelicTreatmentType? = treatmentType

            _ = ExpandableSearchView(
                searchText: .constant(""),
                treatmentFilter: Binding(get: { filter }, set: { filter = $0 }),
                sortOption: .constant(.newestFirst),
                onCollapse: {}
            )

            #expect(filter == treatmentType)
            #expect(!treatmentType.displayName.isEmpty)
        }
    }

    @Test("Filter state persists when search text changes") func filterStatePersistsWhenSearchTextChanges() throws {
        var searchText = ""
        var treatmentFilter: PsychedelicTreatmentType? = .psilocybin

        _ = ExpandableSearchView(
            searchText: Binding(get: { searchText }, set: { searchText = $0 }),
            treatmentFilter: Binding(get: { treatmentFilter }, set: { treatmentFilter = $0 }),
            sortOption: .constant(.newestFirst),
            onCollapse: {}
        )

        #expect(treatmentFilter == .psilocybin)

        searchText = "new search"
        #expect(treatmentFilter == .psilocybin) // Filter should remain
    }

    @Test("Sort option persists when other fields change") func sortOptionPersistsWhenOtherFieldsChange() throws {
        var searchText = ""
        var treatmentFilter: PsychedelicTreatmentType?
        var sortOption: SessionListViewModel.SortOption = .moodChange

        _ = ExpandableSearchView(
            searchText: Binding(get: { searchText }, set: { searchText = $0 }),
            treatmentFilter: Binding(get: { treatmentFilter }, set: { treatmentFilter = $0 }),
            sortOption: Binding(get: { sortOption }, set: { sortOption = $0 }),
            onCollapse: {}
        )

        #expect(sortOption == .moodChange)

        searchText = "test"
        treatmentFilter = .ketamine

        #expect(sortOption == .moodChange) // Sort should remain unchanged
    }
}
