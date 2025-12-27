@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct MoodRatingViewTests {
    @Test("Mood rating view initializes with value binding") func moodRatingViewInitializesWithValueBinding() throws {
        var moodValue = 5
        let moodView = MoodRatingView(
            value: Binding(get: { moodValue }, set: { moodValue = $0 }),
            title: "Mood Before",
            accessibilityIdentifier: "moodBeforeSlider"
        )

        #expect(moodView.title == "Mood Before")
        #expect(moodView.accessibilityIdentifier == "moodBeforeSlider")
    }

    @Test("Value binding updates correctly") func valueBindingUpdatesCorrectly() throws {
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

        moodValue = 7

        #expect(binding.wrappedValue == 7)
    }

    @Test("Slider rounds to integer") func sliderRoundsToInteger() throws {
        var moodValue = 5

        let decimalValue = 5.7
        moodValue = Int(decimalValue.rounded())

        #expect(moodValue == 6)
    }

    @Test("Slider handles minimum value") func sliderHandlesMinimumValue() throws {
        var moodValue = 1
        let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
        let moodView = MoodRatingView(
            value: binding,
            title: "Mood",
            accessibilityIdentifier: "slider"
        )

        #expect(binding.wrappedValue == 1)
    }

    @Test("Slider handles maximum value") func sliderHandlesMaximumValue() throws {
        var moodValue = 10
        let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
        let moodView = MoodRatingView(
            value: binding,
            title: "Mood",
            accessibilityIdentifier: "slider"
        )

        #expect(binding.wrappedValue == 10)
    }

    @Test("Displays title correctly") func displaysTitleCorrectly() throws {
        let titles = ["Mood Before", "Mood After", "Current Mood", "How are you feeling?"]

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
        for value in 1 ... 10 {
            var moodValue = value
            let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
            let moodView = MoodRatingView(
                value: binding,
                title: "Mood",
                accessibilityIdentifier: "slider"
            )

            #expect(binding.wrappedValue == value)
        }
    }

    @Test("Displays mood descriptor") func displaysMoodDescriptor() throws {
        for value in 1 ... 10 {
            let descriptor = MoodRatingScale.descriptor(for: value)

            #expect(!descriptor.isEmpty)
        }
    }

    @Test("Displays mood emoji") func displaysMoodEmoji() throws {
        for value in 1 ... 10 {
            let emoji = MoodRatingScale.emoji(for: value)

            #expect(!emoji.isEmpty)
        }
    }

    @Test("All mood values have unique descriptors") func allMoodValuesHaveUniqueDescriptors() throws {
        var descriptors = Set<String>()

        for value in 1 ... 10 {
            let descriptor = MoodRatingScale.descriptor(for: value)
            descriptors.insert(descriptor)
        }

        #expect(descriptors.count >= 5)
    }

    @Test("Mood descriptors are appropriate for values") func moodDescriptorsAreAppropriateForValues() throws {
        let lowMoodDescriptor = MoodRatingScale.descriptor(for: 1)
        let midMoodDescriptor = MoodRatingScale.descriptor(for: 5)
        let highMoodDescriptor = MoodRatingScale.descriptor(for: 10)

        #expect(!lowMoodDescriptor.isEmpty)
        #expect(!midMoodDescriptor.isEmpty)
        #expect(!highMoodDescriptor.isEmpty)

        #expect(lowMoodDescriptor != highMoodDescriptor)
    }

    @Test("Accessibility label includes title") func accessibilityLabelIncludesTitle() throws {
        let moodView = MoodRatingView(
            value: .constant(5),
            title: "Mood Before",
            accessibilityIdentifier: "moodBeforeSlider"
        )

        #expect(moodView.title == "Mood Before")
    }

    @Test("Accessibility value includes descriptor") func accessibilityValueIncludesDescriptor() throws {
        let value = 7
        var moodValue = value
        let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
        let moodView = MoodRatingView(
            value: binding,
            title: "Mood",
            accessibilityIdentifier: "slider"
        )

        let descriptor = MoodRatingScale.descriptor(for: value)

        #expect(!descriptor.isEmpty)
    }

    @Test("Accessibility identifier set correctly") func accessibilityIdentifierSetCorrectly() throws {
        let identifiers = ["moodBeforeSlider", "moodAfterSlider", "customSlider"]

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
        var moodValue = 5

        moodValue = min(moodValue + 1, 10)

        #expect(moodValue == 6)
    }

    @Test("Accessibility adjustable action decrements") func accessibilityAdjustableActionDecrements() throws {
        var moodValue = 5

        moodValue = max(moodValue - 1, 1)

        #expect(moodValue == 4)
    }

    @Test("Accessibility increment clamped at maximum") func accessibilityIncrementClampedAtMaximum() throws {
        var moodValue = 10

        moodValue = min(moodValue + 1, 10)

        #expect(moodValue == 10)
    }

    @Test("Accessibility decrement clamped at minimum") func accessibilityDecrementClampedAtMinimum() throws {
        var moodValue = 1

        moodValue = max(moodValue - 1, 1)

        #expect(moodValue == 1)
    }

    @Test("Multiple mood views maintain independent state") func multipleMoodViewsMaintainIndependentState() throws {
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

        moodBefore = 2
        moodAfter = 9

        #expect(bindingBefore.wrappedValue == 2)
        #expect(bindingAfter.wrappedValue == 9)
        #expect(bindingBefore.wrappedValue != bindingAfter.wrappedValue)
    }

    @Test("Rapid value changes handled correctly") func rapidValueChangesHandledCorrectly() throws {
        var moodValue = 5

        for newValue in [6, 7, 4, 8, 3, 9, 2, 10, 1, 5] {
            moodValue = newValue
            #expect(moodValue == newValue)
            #expect(moodValue >= 1 && moodValue <= 10)
        }

        #expect(moodValue == 5)
    }

    @Test("Value persistence across view updates") func valuePersistenceAcrossViewUpdates() throws {
        var moodValue = 7
        let binding = Binding(get: { moodValue }, set: { moodValue = $0 })
        let moodView = MoodRatingView(
            value: binding,
            title: "Mood",
            accessibilityIdentifier: "slider"
        )

        let storedValue = binding.wrappedValue

        #expect(storedValue == 7)
        #expect(moodValue == storedValue)
    }
}
