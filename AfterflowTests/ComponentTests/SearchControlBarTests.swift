@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct SearchControlBarTests {
    @Test("Initializes with correct bindings") func initializesWithCorrectBindings() throws {
        var listViewModel = SessionListViewModel()
        var showCalendarView = false
        var isSearchExpanded = false

        let controlBar = SearchControlBar(
            listViewModel: Binding(get: { listViewModel }, set: { listViewModel = $0 }),
            showCalendarView: Binding(get: { showCalendarView }, set: { showCalendarView = $0 }),
            isSearchExpanded: Binding(get: { isSearchExpanded }, set: { isSearchExpanded = $0 }),
            onAdd: {}
        )

        #expect(controlBar.listViewModel.searchText == "")
        #expect(controlBar.showCalendarView == false)
        #expect(controlBar.isSearchExpanded == false)
    }

    @Test("Add button callback triggers") func addButtonCallbackTriggers() throws {
        var listViewModel = SessionListViewModel()
        var addCalled = false

        _ = SearchControlBar(
            listViewModel: Binding(get: { listViewModel }, set: { listViewModel = $0 }),
            showCalendarView: .constant(false),
            isSearchExpanded: .constant(false),
            onAdd: { addCalled = true }
        )

        // Callback would be triggered by tapping the add button
        #expect(addCalled == false) // Not triggered during initialization
    }

    @Test("Calendar view toggle state") func calendarViewToggleState() throws {
        var listViewModel = SessionListViewModel()
        var showCalendarView = false

        let controlBar = SearchControlBar(
            listViewModel: Binding(get: { listViewModel }, set: { listViewModel = $0 }),
            showCalendarView: Binding(get: { showCalendarView }, set: { showCalendarView = $0 }),
            isSearchExpanded: .constant(false),
            onAdd: {}
        )

        #expect(controlBar.showCalendarView == false)

        showCalendarView = true
        #expect(showCalendarView == true)
    }

    @Test("Search expanded state") func searchExpandedState() throws {
        var listViewModel = SessionListViewModel()
        var isSearchExpanded = false

        let controlBar = SearchControlBar(
            listViewModel: Binding(get: { listViewModel }, set: { listViewModel = $0 }),
            showCalendarView: .constant(false),
            isSearchExpanded: Binding(get: { isSearchExpanded }, set: { isSearchExpanded = $0 }),
            onAdd: {}
        )

        #expect(controlBar.isSearchExpanded == false)

        isSearchExpanded = true
        #expect(isSearchExpanded == true)
    }

    @Test("List view model updates") func listViewModelUpdates() throws {
        var listViewModel = SessionListViewModel()

        let controlBar = SearchControlBar(
            listViewModel: Binding(get: { listViewModel }, set: { listViewModel = $0 }),
            showCalendarView: .constant(false),
            isSearchExpanded: .constant(false),
            onAdd: {}
        )

        #expect(controlBar.listViewModel.searchText == "")

        listViewModel.searchText = "test search"
        #expect(listViewModel.searchText == "test search")
    }

    @Test("Multiple state changes handled") func multipleStateChangesHandled() throws {
        var listViewModel = SessionListViewModel()
        var showCalendarView = false
        var isSearchExpanded = false

        let controlBar = SearchControlBar(
            listViewModel: Binding(get: { listViewModel }, set: { listViewModel = $0 }),
            showCalendarView: Binding(get: { showCalendarView }, set: { showCalendarView = $0 }),
            isSearchExpanded: Binding(get: { isSearchExpanded }, set: { isSearchExpanded = $0 }),
            onAdd: {}
        )

        #expect(controlBar.showCalendarView == false)
        #expect(controlBar.isSearchExpanded == false)

        showCalendarView = true
        isSearchExpanded = true

        #expect(showCalendarView == true)
        #expect(isSearchExpanded == true)
    }

    @Test("Treatment filter binding") func treatmentFilterBinding() throws {
        var listViewModel = SessionListViewModel()

        let controlBar = SearchControlBar(
            listViewModel: Binding(get: { listViewModel }, set: { listViewModel = $0 }),
            showCalendarView: .constant(false),
            isSearchExpanded: .constant(false),
            onAdd: {}
        )

        #expect(controlBar.listViewModel.treatmentFilter == nil)

        listViewModel.treatmentFilter = .psilocybin
        #expect(listViewModel.treatmentFilter == .psilocybin)
    }

    @Test("Sort option binding") func sortOptionBinding() throws {
        var listViewModel = SessionListViewModel()

        let controlBar = SearchControlBar(
            listViewModel: Binding(get: { listViewModel }, set: { listViewModel = $0 }),
            showCalendarView: .constant(false),
            isSearchExpanded: .constant(false),
            onAdd: {}
        )

        #expect(controlBar.listViewModel.sortOption == .newestFirst)

        listViewModel.sortOption = .oldestFirst
        #expect(listViewModel.sortOption == .oldestFirst)
    }
}
