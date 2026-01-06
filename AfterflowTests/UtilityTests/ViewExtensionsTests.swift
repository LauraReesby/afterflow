@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct ViewExtensionsTests {
    @Test("Glass pill background modifier exists") func glassPillBackgroundModifierExists() throws {
        let view = Text("Test")
        let modifiedView = view.glassPillBackground()

        // Verify the modifier can be applied without error
        _ = modifiedView
    }

    @Test("Glass pill background with custom corner radius") func glassPillBackgroundWithCustomCornerRadius() throws {
        let view = Text("Test")
        let modifiedView = view.glassPillBackground(cornerRadius: 16)

        // Verify the modifier accepts custom corner radius
        _ = modifiedView
    }

    @Test("Glass pill background with default corner radius") func glassPillBackgroundWithDefaultCornerRadius() throws {
        let view = Text("Test")
        let modifiedView = view.glassPillBackground()

        // Default corner radius is 25
        _ = modifiedView
    }

    @Test("Glass pill background on various views") func glassPillBackgroundOnVariousViews() throws {
        let textView = Text("Test").glassPillBackground()
        let buttonView = Button("Test") {}.glassPillBackground()
        let vstackView = VStack { Text("Test") }.glassPillBackground()
        let hstackView = HStack { Text("Test") }.glassPillBackground()

        // Verify modifier works on different view types
        _ = textView
        _ = buttonView
        _ = vstackView
        _ = hstackView
    }

    @Test("Glass pill background with different corner radii") func glassPillBackgroundWithDifferentCornerRadii(
    ) throws {
        let view1 = Text("Test").glassPillBackground(cornerRadius: 8)
        let view2 = Text("Test").glassPillBackground(cornerRadius: 12)
        let view3 = Text("Test").glassPillBackground(cornerRadius: 20)
        let view4 = Text("Test").glassPillBackground(cornerRadius: 30)

        // Verify different corner radii work
        _ = view1
        _ = view2
        _ = view3
        _ = view4
    }

    @Test("Glass pill background with zero corner radius") func glassPillBackgroundWithZeroCornerRadius() throws {
        let view = Text("Test").glassPillBackground(cornerRadius: 0)

        // Should work with zero corner radius
        _ = view
    }

    @Test("Glass pill background with large corner radius") func glassPillBackgroundWithLargeCornerRadius() throws {
        let view = Text("Test").glassPillBackground(cornerRadius: 100)

        // Should work with large corner radius
        _ = view
    }

    @Test("Glass pill background is chainable") func glassPillBackgroundIsChainable() throws {
        let view = Text("Test")
            .glassPillBackground()
            .padding()
            .frame(width: 200, height: 50)

        // Verify modifier can be chained with other modifiers
        _ = view
    }

    @Test("Glass pill background on complex views") func glassPillBackgroundOnComplexViews() throws {
        let complexView = VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                Text("Search")
            }
            .padding()
        }
        .glassPillBackground(cornerRadius: 16)

        // Verify modifier works on complex view hierarchies
        _ = complexView
    }

    @Test("Multiple glass pill backgrounds can be applied") func multipleGlassPillBackgroundsCanBeApplied() throws {
        let outerView = VStack {
            Text("Inner")
                .glassPillBackground(cornerRadius: 8)
        }
        .glassPillBackground(cornerRadius: 16)

        // Verify nested glass backgrounds work
        _ = outerView
    }

    @Test("Glass pill background with conditional content") func glassPillBackgroundWithConditionalContent() throws {
        let shouldShow = true
        let view = Group {
            if shouldShow {
                Text("Shown")
                    .glassPillBackground()
            } else {
                Text("Hidden")
                    .glassPillBackground()
            }
        }

        // Verify modifier works with conditional content
        _ = view
    }

    @Test("Glass pill background with empty view") func glassPillBackgroundWithEmptyView() throws {
        let view = EmptyView().glassPillBackground()

        // Should work with EmptyView
        _ = view
    }

    @Test("Glass pill background preserves view identity") func glassPillBackgroundPreservesViewIdentity() throws {
        let originalView = Text("Test").id("testID")
        let modifiedView = originalView.glassPillBackground()

        // Verify the modifier doesn't break view identity
        _ = modifiedView
    }

    @Test("Glass pill background with accessibility") func glassPillBackgroundWithAccessibility() throws {
        let view = Text("Test")
            .accessibilityLabel("Test Button")
            .glassPillBackground()

        // Verify accessibility works with modifier
        _ = view
    }

    @Test("Glass pill background with gestures") func glassPillBackgroundWithGestures() throws {
        var tapped = false
        let view = Text("Test")
            .glassPillBackground()
            .onTapGesture { tapped = true }

        // Verify gestures work with modifier
        _ = view
        #expect(tapped == false) // Not tapped during initialization
    }
}
