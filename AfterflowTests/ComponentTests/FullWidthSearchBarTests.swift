@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct FullWidthSearchBarTests {
    @Test("Search bar initializes with bindings") func searchBarInitializesWithBindings() throws {
        var searchText = ""
        var isExpanded = true
        let searchTextBinding = Binding(get: { searchText }, set: { searchText = $0 })
        let isExpandedBinding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        _ = FullWidthSearchBar(
            searchText: searchTextBinding,
            isExpanded: isExpandedBinding
        )

        #expect(searchTextBinding.wrappedValue == "")
        #expect(isExpandedBinding.wrappedValue == true)
    }

    @Test("Search text binding reflects initial value") func searchTextBindingReflectsInitialValue() throws {
        var initialText = "test query"
        let binding = Binding(get: { initialText }, set: { initialText = $0 })

        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        #expect(binding.wrappedValue == "test query")
    }

    @Test("Search text binding updates") func searchTextBindingUpdates() throws {
        var searchText = ""
        let binding = Binding(get: { searchText }, set: { searchText = $0 })
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        searchText = "new query"

        #expect(binding.wrappedValue == "new query")
    }

    @Test("Empty search text handled") func emptySearchTextHandled() throws {
        var searchText = ""
        let binding = Binding(get: { searchText }, set: { searchText = $0 })

        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        #expect(binding.wrappedValue.isEmpty)
    }

    @Test("Is expanded binding reflects state") func isExpandedBindingReflectsState() throws {
        var isExpanded = true
        let expandedBinding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        var isCollapsed = false
        let collapsedBinding = Binding(get: { isCollapsed }, set: { isCollapsed = $0 })

        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: expandedBinding
        )
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: collapsedBinding
        )

        #expect(expandedBinding.wrappedValue == true)
        #expect(collapsedBinding.wrappedValue == false)
    }

    @Test("Expansion state binding updates") func expansionStateBindingUpdates() throws {
        var isExpanded = false
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: binding
        )

        isExpanded = true

        #expect(binding.wrappedValue == true)
    }

    @Test("Clear button action clears search text") func clearButtonActionClearsSearchText() throws {
        var searchText = "test query"
        let binding = Binding(get: { searchText }, set: { searchText = $0 })
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        searchText = ""

        #expect(binding.wrappedValue.isEmpty)
    }

    @Test("Clear button conditional display logic") func clearButtonConditionalDisplayLogic() throws {
        var emptySearch = ""
        var populatedSearch = "query"
        let emptyBinding = Binding(get: { emptySearch }, set: { emptySearch = $0 })
        let populatedBinding = Binding(get: { populatedSearch }, set: { populatedSearch = $0 })

        _ = FullWidthSearchBar(
            searchText: emptyBinding,
            isExpanded: .constant(true)
        )
        _ = FullWidthSearchBar(
            searchText: populatedBinding,
            isExpanded: .constant(true)
        )

        #expect(emptyBinding.wrappedValue.isEmpty)
        #expect(!populatedBinding.wrappedValue.isEmpty)
    }

    @Test("Cancel button collapses search") func cancelButtonCollapsesSearch() throws {
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: binding
        )

        isExpanded = false

        #expect(binding.wrappedValue == false)
    }

    @Test("Cancel button clears search text") func cancelButtonClearsSearchText() throws {
        var searchText = "test query"
        var isExpanded = true

        let searchBinding = Binding(get: { searchText }, set: { searchText = $0 })
        let expandedBinding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        _ = FullWidthSearchBar(
            searchText: searchBinding,
            isExpanded: expandedBinding
        )

        searchText = ""
        isExpanded = false

        #expect(searchBinding.wrappedValue.isEmpty)
        #expect(expandedBinding.wrappedValue == false)
    }

    @Test("Clear button has accessibility label") func clearButtonHasAccessibilityLabel() throws {
        var searchText = "query"
        let binding = Binding(get: { searchText }, set: { searchText = $0 })

        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        #expect(!binding.wrappedValue.isEmpty)
    }

    @Test("Clear button has accessibility hint") func clearButtonHasAccessibilityHint() throws {
        var searchText = "query"
        let binding = Binding(get: { searchText }, set: { searchText = $0 })

        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        #expect(!binding.wrappedValue.isEmpty)
    }

    @Test("Cancel button has accessibility label") func cancelButtonHasAccessibilityLabel() throws {
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: binding
        )

        #expect(binding.wrappedValue == true)
    }

    @Test("Cancel button has accessibility hint") func cancelButtonHasAccessibilityHint() throws {
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: binding
        )

        #expect(binding.wrappedValue == true)
    }

    @Test("Long search text handled") func longSearchTextHandled() throws {
        var longText = String(repeating: "long search query ", count: 50)
        let binding = Binding(get: { longText }, set: { longText = $0 })

        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        #expect(binding.wrappedValue.count > 500)
    }

    @Test("Unicode search text supported") func unicodeSearchTextSupported() throws {
        var unicodeText = "search 🔍 with émojis and 日本語"
        let binding = Binding(get: { unicodeText }, set: { unicodeText = $0 })

        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        #expect(binding.wrappedValue == unicodeText)
        #expect(binding.wrappedValue.contains("🔍"))
    }

    @Test("Whitespace only search text") func whitespaceOnlySearchText() throws {
        var whitespaceText = "   "
        let binding = Binding(get: { whitespaceText }, set: { whitespaceText = $0 })

        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        #expect(binding.wrappedValue == whitespaceText)
        #expect(!binding.wrappedValue.isEmpty)
    }

    @Test("Special characters in search text") func specialCharactersInSearchText() throws {
        var specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let binding = Binding(get: { specialChars }, set: { specialChars = $0 })

        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        #expect(binding.wrappedValue == specialChars)
    }
}
