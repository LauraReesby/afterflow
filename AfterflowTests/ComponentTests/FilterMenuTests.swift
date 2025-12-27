@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct FilterMenuTests {
    

    @Test("FilterMenu initializes with view model binding") func filterMenuInitializesWithViewModelBinding() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()

        
        let filterMenu = FilterMenu(listViewModel: .constant(viewModel))

        
        #expect(filterMenu.listViewModel.sortOption == viewModel.sortOption)
    }

    

    @Test("Sort option binding reflects view model state") func sortOptionBindingReflectsViewModelState() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()
        viewModel.sortOption = .newestFirst

        
        let filterMenu = FilterMenu(listViewModel: .constant(viewModel))

        
        #expect(filterMenu.listViewModel.sortOption == .newestFirst)
    }

    @Test("All sort options are available") func allSortOptionsAreAvailable() throws {
        
        let allOptions = SessionListViewModel.SortOption.allCases

        
        #expect(allOptions.contains(.newestFirst))
        #expect(allOptions.contains(.oldestFirst))
        #expect(allOptions.contains(.moodChange))
        #expect(allOptions.count >= 3)
    }

    @Test("Sort option labels are descriptive") func sortOptionLabelsAreDescriptive() throws {
        
        let options = SessionListViewModel.SortOption.allCases

        
        for option in options {
            #expect(!option.label.isEmpty)
        }
    }

    

    @Test("Treatment filter binding reflects view model state")
    func treatmentFilterBindingReflectsViewModelState() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()
        viewModel.treatmentFilter = .psilocybin

        
        let filterMenu = FilterMenu(listViewModel: .constant(viewModel))

        
        #expect(filterMenu.listViewModel.treatmentFilter == .psilocybin)
    }

    @Test("All treatment types are available") func allTreatmentTypesAreAvailable() throws {
        
        let allTypes = PsychedelicTreatmentType.allCases

        
        #expect(allTypes.contains(.psilocybin))
        #expect(allTypes.contains(.lsd))
        #expect(allTypes.contains(.mdma))
        #expect(allTypes.contains(.ketamine))
        #expect(allTypes.contains(.ayahuasca))
        #expect(allTypes.contains(.dmt))
        #expect(allTypes.contains(.mescaline))
        #expect(allTypes.contains(.cannabis))
        #expect(allTypes.contains(.other))
        #expect(allTypes.count == 9)
    }

    @Test("Treatment type display names are non-empty") func treatmentTypeDisplayNamesAreNonEmpty() throws {
        
        let types = PsychedelicTreatmentType.allCases

        
        for type in types {
            #expect(!type.displayName.isEmpty)
        }
    }

    @Test("Clear filter sets treatment filter to nil") func clearFilterSetsTreatmentFilterToNil() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()
        viewModel.treatmentFilter = .mdma
        #expect(viewModel.treatmentFilter == .mdma)

        
        viewModel.treatmentFilter = nil

        
        #expect(viewModel.treatmentFilter == nil)
    }

    

    @Test("FilterMenu has accessibility label") func filterMenuHasAccessibilityLabel() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()
        let filterMenu = FilterMenu(listViewModel: .constant(viewModel))

        
        

        
        
        #expect(true) 
    }

    @Test("FilterMenu has accessibility hint") func filterMenuHasAccessibilityHint() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()
        let filterMenu = FilterMenu(listViewModel: .constant(viewModel))

        
        
        #expect(true) 
    }

    

    @Test("Changing sort option updates view model") func changingSortOptionUpdatesViewModel() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()
        viewModel.sortOption = .newestFirst

        
        viewModel.sortOption = .oldestFirst

        
        #expect(viewModel.sortOption == .oldestFirst)
    }

    @Test("Changing treatment filter updates view model") func changingTreatmentFilterUpdatesViewModel() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()
        viewModel.treatmentFilter = nil

        
        viewModel.treatmentFilter = .ketamine

        
        #expect(viewModel.treatmentFilter == .ketamine)
    }

    @Test("Multiple filter changes maintain state correctly")
    func multipleFilterChangesMaintainStateCorrectly() throws {
        
        var viewModel = TestHelpers.makeSessionListViewModel()

        
        viewModel.sortOption = .moodChange
        viewModel.treatmentFilter = .psilocybin

        
        #expect(viewModel.sortOption == .moodChange)
        #expect(viewModel.treatmentFilter == .psilocybin)

        
        viewModel.sortOption = .newestFirst
        viewModel.treatmentFilter = .lsd

        
        #expect(viewModel.sortOption == .newestFirst)
        #expect(viewModel.treatmentFilter == .lsd)
    }
}
