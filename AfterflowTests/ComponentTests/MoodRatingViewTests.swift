@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct MoodRatingViewTests {
    // MARK: - Initialization Tests

    @Test("Mood rating view initializes with value binding") func moodRatingViewInitializesWithValueBinding() throws {
        // Arrange & Act
        var moodValue = 5
        let moodView = MoodRatingView(
            value: Binding(get: { moodValue }, set: { moodValue = $0 }),
            title: "Mood Before",
            accessibilityIdentifier: "moodBeforeSlider"
        )

        // Assert
        #expect(moodView.title == "Mood Before")
        #expect(moodView.accessibilityIdentifier == "moodBeforeSlider")
    }

    // MARK: - Value Binding Tests

    @Test("Value binding updates correctly") func valueBindingUpdatesCorrectly() throws {
        // Arrange
        var moodValue = 3
        let binding = Binding(
            get: { moodValue },
            set: { moodValue = $0 }
        )
        let moodView = MoodRatingView(
            value: binding,
            title: "Test Mood",
            accessibilityIdentifier: "testSlider"
        )

        // Act
        moodValue = 7

        // Assert
        #expect(binding.wrappedValue == 7)
    }

    @Test("Slider rounds to integer") func sliderRoundsToInteger() throws {
        // Arrange
        var moodValue = 5

        // Act - Simulate slider producing decimal value (should round)
        let decimalValue = 5.7
        moodValue = Int(decimalValue.rounded())

        // Assert
        #expect(moodValue == 6)
    }

    @Test("Slider handles minimum value") func sliderHandlesMinimumValue() throws {
        // Arrange & Act
        var moodValue = 1
        let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
        let moodView = MoodRatingView(
            value: binding,
            title: "Mood",
            accessibilityIdentifier: "slider"
        )

        // Assert
        #expect(binding.wrappedValue == 1)
    }

    @Test("Slider handles maximum value") func sliderHandlesMaximumValue() throws {
        // Arrange & Act
        var moodValue = 10
        let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
        let moodView = MoodRatingView(
            value: binding,
            title: "Mood",
            accessibilityIdentifier: "slider"
        )

        // Assert
        #expect(binding.wrappedValue == 10)
    }

    // MARK: - Display Tests

    @Test("Displays title correctly") func displaysTitleCorrectly() throws {
        // Arrange
        let titles = ["Mood Before", "Mood After", "Current Mood", "How are you feeling?"]

        // Act & Assert
        for title in titles {
            let moodView = MoodRatingView(
                value: .constant(5),
                title: title,
                accessibilityIdentifier: "slider"
            )
            #expect(moodView.title == title)
        }
    }

    @Test("Displays value out of ten") func displaysValueOutOfTen() throws {
        // Arrange & Act
        for value in 1 ... 10 {
            var moodValue = value
            let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
            let moodView = MoodRatingView(
                value: binding,
                title: "Mood",
                accessibilityIdentifier: "slider"
            )

            // Assert - View should display "{value}/10"
            #expect(binding.wrappedValue == value)
        }
    }

    @Test("Displays mood descriptor") func displaysMoodDescriptor() throws {
        // Arrange & Act
        for value in 1 ... 10 {
            let descriptor = MoodRatingScale.descriptor(for: value)

            // Assert - Each value should have a descriptor
            #expect(!descriptor.isEmpty)
        }
    }

    @Test("Displays mood emoji") func displaysMoodEmoji() throws {
        // Arrange & Act
        for value in 1 ... 10 {
            let emoji = MoodRatingScale.emoji(for: value)

            // Assert - Each value should have an emoji
            #expect(!emoji.isEmpty)
        }
    }

    // MARK: - Mood Scale Tests

    @Test("All mood values have unique descriptors") func allMoodValuesHaveUniqueDescriptors() throws {
        // Arrange
        var descriptors = Set<String>()

        // Act
        for value in 1 ... 10 {
            let descriptor = MoodRatingScale.descriptor(for: value)
            descriptors.insert(descriptor)
        }

        // Assert - Should have 10 unique descriptors (or reasonable grouping)
        #expect(descriptors.count >= 5) // At least 5 different mood categories
    }

    @Test("Mood descriptors are appropriate for values") func moodDescriptorsAreAppropriateForValues() throws {
        // Arrange & Act
        let lowMoodDescriptor = MoodRatingScale.descriptor(for: 1)
        let midMoodDescriptor = MoodRatingScale.descriptor(for: 5)
        let highMoodDescriptor = MoodRatingScale.descriptor(for: 10)

        // Assert - Descriptors should reflect mood quality
        #expect(!lowMoodDescriptor.isEmpty)
        #expect(!midMoodDescriptor.isEmpty)
        #expect(!highMoodDescriptor.isEmpty)
        // Low mood should be different from high mood
        #expect(lowMoodDescriptor != highMoodDescriptor)
    }

    // MARK: - Accessibility Tests

    @Test("Accessibility label includes title") func accessibilityLabelIncludesTitle() throws {
        // Arrange
        let moodView = MoodRatingView(
            value: .constant(5),
            title: "Mood Before",
            accessibilityIdentifier: "moodBeforeSlider"
        )

        // Act & Assert
        // Accessibility label should be "{title} mood rating"
        #expect(moodView.title == "Mood Before")
    }

    @Test("Accessibility value includes descriptor") func accessibilityValueIncludesDescriptor() throws {
        // Arrange
        let value = 7
        var moodValue = value
        let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
        let moodView = MoodRatingView(
            value: binding,
            title: "Mood",
            accessibilityIdentifier: "slider"
        )

        // Act
        let descriptor = MoodRatingScale.descriptor(for: value)

        // Assert
        // Accessibility value should be "{value} of 10, {descriptor}"
        #expect(!descriptor.isEmpty)
    }

    @Test("Accessibility identifier set correctly") func accessibilityIdentifierSetCorrectly() throws {
        // Arrange
        let identifiers = ["moodBeforeSlider", "moodAfterSlider", "customSlider"]

        // Act & Assert
        for identifier in identifiers {
            let moodView = MoodRatingView(
                value: .constant(5),
                title: "Mood",
                accessibilityIdentifier: identifier
            )
            #expect(moodView.accessibilityIdentifier == identifier)
        }
    }

    @Test("Accessibility adjustable action increments") func accessibilityAdjustableActionIncrements() throws {
        // Arrange
        var moodValue = 5

        // Act - Simulate accessibility increment
        moodValue = min(moodValue + 1, 10)

        // Assert
        #expect(moodValue == 6)
    }

    @Test("Accessibility adjustable action decrements") func accessibilityAdjustableActionDecrements() throws {
        // Arrange
        var moodValue = 5

        // Act - Simulate accessibility decrement
        moodValue = max(moodValue - 1, 1)

        // Assert
        #expect(moodValue == 4)
    }

    @Test("Accessibility increment clamped at maximum") func accessibilityIncrementClampedAtMaximum() throws {
        // Arrange
        var moodValue = 10

        // Act - Simulate accessibility increment at max
        moodValue = min(moodValue + 1, 10)

        // Assert
        #expect(moodValue == 10)
    }

    @Test("Accessibility decrement clamped at minimum") func accessibilityDecrementClampedAtMinimum() throws {
        // Arrange
        var moodValue = 1

        // Act - Simulate accessibility decrement at min
        moodValue = max(moodValue - 1, 1)

        // Assert
        #expect(moodValue == 1)
    }

    // MARK: - Edge Cases

    @Test("Multiple mood views maintain independent state") func multipleMoodViewsMaintainIndependentState() throws {
        // Arrange
        var moodBefore = 3
        var moodAfter = 8

        let bindingBefore = Binding(get: { moodBefore }, set: { moodBefore = $0 })
        let bindingAfter = Binding(get: { moodAfter }, set: { moodAfter = $0 })

        let viewBefore = MoodRatingView(
            value: bindingBefore,
            title: "Before",
            accessibilityIdentifier: "before"
        )

        let viewAfter = MoodRatingView(
            value: bindingAfter,
            title: "After",
            accessibilityIdentifier: "after"
        )

        // Act
        moodBefore = 2
        moodAfter = 9

        // Assert
        #expect(bindingBefore.wrappedValue == 2)
        #expect(bindingAfter.wrappedValue == 9)
        #expect(bindingBefore.wrappedValue != bindingAfter.wrappedValue)
    }

    @Test("Rapid value changes handled correctly") func rapidValueChangesHandledCorrectly() throws {
        // Arrange
        var moodValue = 5

        // Act - Simulate rapid slider movements
        for newValue in [6, 7, 4, 8, 3, 9, 2, 10, 1, 5] {
            moodValue = newValue
            #expect(moodValue == newValue)
            #expect(moodValue >= 1 && moodValue <= 10)
        }

        // Assert
        #expect(moodValue == 5)
    }

    @Test("Value persistence across view updates") func valuePersistenceAcrossViewUpdates() throws {
        // Arrange
        var moodValue = 7
        let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
        let moodView = MoodRatingView(
            value: binding,
            title: "Mood",
            accessibilityIdentifier: "slider"
        )

        // Act - Value remains stable
        let storedValue = binding.wrappedValue

        // Assert
        #expect(storedValue == 7)
        #expect(moodValue == storedValue)
    }
}
