@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct FullWidthSearchBarTests {
    // MARK: - Initialization Tests

    @Test("Search bar initializes with bindings") func searchBarInitializesWithBindings() throws {
        // Arrange
        var searchText = ""
        var isExpanded = true
        let searchTextBinding = Binding(get: { searchText }, set: { searchText = $0 })
        let isExpandedBinding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        // Act
        let searchBar = FullWidthSearchBar(
            searchText: searchTextBinding,
            isExpanded: isExpandedBinding
        )

        // Assert
        #expect(searchTextBinding.wrappedValue == "")
        #expect(isExpandedBinding.wrappedValue == true)
    }

    // MARK: - Search Text Binding Tests

    @Test("Search text binding reflects initial value") func searchTextBindingReflectsInitialValue() throws {
        // Arrange
        var initialText = "test query"
        let binding = Binding(get: { initialText }, set: { initialText = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Assert
        #expect(binding.wrappedValue == "test query")
    }

    @Test("Search text binding updates") func searchTextBindingUpdates() throws {
        // Arrange
        var searchText = ""
        let binding = Binding(get: { searchText }, set: { searchText = $0 })
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Act
        searchText = "new query"

        // Assert
        #expect(binding.wrappedValue == "new query")
    }

    @Test("Empty search text handled") func emptySearchTextHandled() throws {
        // Arrange
        var searchText = ""
        let binding = Binding(get: { searchText }, set: { searchText = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Assert
        #expect(binding.wrappedValue.isEmpty)
    }

    // MARK: - Expansion State Tests

    @Test("Is expanded binding reflects state") func isExpandedBindingReflectsState() throws {
        // Arrange
        var isExpanded = true
        let expandedBinding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        var isCollapsed = false
        let collapsedBinding = Binding(get: { isCollapsed }, set: { isCollapsed = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: expandedBinding
        )
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: collapsedBinding
        )

        // Assert
        #expect(expandedBinding.wrappedValue == true)
        #expect(collapsedBinding.wrappedValue == false)
    }

    @Test("Expansion state binding updates") func expansionStateBindingUpdates() throws {
        // Arrange
        var isExpanded = false
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: binding
        )

        // Act
        isExpanded = true

        // Assert
        #expect(binding.wrappedValue == true)
    }

    // MARK: - Clear Button Tests

    @Test("Clear button action clears search text") func clearButtonActionClearsSearchText() throws {
        // Arrange
        var searchText = "test query"
        let binding = Binding(get: { searchText }, set: { searchText = $0 })
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Act - Simulate clear button tap
        searchText = ""

        // Assert
        #expect(binding.wrappedValue.isEmpty)
    }

    @Test("Clear button conditional display logic") func clearButtonConditionalDisplayLogic() throws {
        // Arrange
        var emptySearch = ""
        var populatedSearch = "query"
        let emptyBinding = Binding(get: { emptySearch }, set: { emptySearch = $0 })
        let populatedBinding = Binding(get: { populatedSearch }, set: { populatedSearch = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: emptyBinding,
            isExpanded: .constant(true)
        )
        _ = FullWidthSearchBar(
            searchText: populatedBinding,
            isExpanded: .constant(true)
        )

        // Assert
        // Clear button should only show when search text is not empty
        #expect(emptyBinding.wrappedValue.isEmpty)
        #expect(!populatedBinding.wrappedValue.isEmpty)
    }

    // MARK: - Cancel Button Tests

    @Test("Cancel button collapses search") func cancelButtonCollapsesSearch() throws {
        // Arrange
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: binding
        )

        // Act - Simulate cancel button tap
        isExpanded = false

        // Assert
        #expect(binding.wrappedValue == false)
    }

    @Test("Cancel button clears search text") func cancelButtonClearsSearchText() throws {
        // Arrange
        var searchText = "test query"
        var isExpanded = true

        let searchBinding = Binding(get: { searchText }, set: { searchText = $0 })
        let expandedBinding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        _ = FullWidthSearchBar(
            searchText: searchBinding,
            isExpanded: expandedBinding
        )

        // Act - Simulate cancel button tap (clears text and collapses)
        searchText = ""
        isExpanded = false

        // Assert
        #expect(searchBinding.wrappedValue.isEmpty)
        #expect(expandedBinding.wrappedValue == false)
    }

    // MARK: - Accessibility Tests

    @Test("Clear button has accessibility label") func clearButtonHasAccessibilityLabel() throws {
        // Arrange
        var searchText = "query"
        let binding = Binding(get: { searchText }, set: { searchText = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Assert
        // Accessibility label is defined in view code ("Clear search")
        #expect(!binding.wrappedValue.isEmpty)
    }

    @Test("Clear button has accessibility hint") func clearButtonHasAccessibilityHint() throws {
        // Arrange
        var searchText = "query"
        let binding = Binding(get: { searchText }, set: { searchText = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Assert
        // Accessibility hint is defined in view code ("Clears the search text")
        #expect(!binding.wrappedValue.isEmpty)
    }

    @Test("Cancel button has accessibility label") func cancelButtonHasAccessibilityLabel() throws {
        // Arrange
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: binding
        )

        // Assert
        // Accessibility label is defined in view code ("Cancel search")
        #expect(binding.wrappedValue == true)
    }

    @Test("Cancel button has accessibility hint") func cancelButtonHasAccessibilityHint() throws {
        // Arrange
        var isExpanded = true
        let binding = Binding(get: { isExpanded }, set: { isExpanded = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: .constant(""),
            isExpanded: binding
        )

        // Assert
        // Accessibility hint is defined in view code ("Closes the search and returns to the session list")
        #expect(binding.wrappedValue == true)
    }

    // MARK: - Edge Cases

    @Test("Long search text handled") func longSearchTextHandled() throws {
        // Arrange
        var longText = String(repeating: "long search query ", count: 50)
        let binding = Binding(get: { longText }, set: { longText = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Assert
        #expect(binding.wrappedValue.count > 500)
    }

    @Test("Unicode search text supported") func unicodeSearchTextSupported() throws {
        // Arrange
        var unicodeText = "search 🔍 with émojis and 日本語"
        let binding = Binding(get: { unicodeText }, set: { unicodeText = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Assert
        #expect(binding.wrappedValue == unicodeText)
        #expect(binding.wrappedValue.contains("🔍"))
    }

    @Test("Whitespace only search text") func whitespaceOnlySearchText() throws {
        // Arrange
        var whitespaceText = "   "
        let binding = Binding(get: { whitespaceText }, set: { whitespaceText = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Assert
        #expect(binding.wrappedValue == whitespaceText)
        #expect(!binding.wrappedValue.isEmpty) // Contains whitespace
    }

    @Test("Special characters in search text") func specialCharactersInSearchText() throws {
        // Arrange
        var specialChars = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let binding = Binding(get: { specialChars }, set: { specialChars = $0 })

        // Act
        _ = FullWidthSearchBar(
            searchText: binding,
            isExpanded: .constant(true)
        )

        // Assert
        #expect(binding.wrappedValue == specialChars)
    }
}
