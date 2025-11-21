@testable import Afterflow
import Testing

@MainActor
struct MoodRatingScaleTests {
    @Test("Descriptor mapping clamps low values") func descriptorClampsLow() async throws {
        #expect(MoodRatingScale.descriptor(for: 0) == "Tender")
        #expect(MoodRatingScale.descriptor(for: 1) == "Tender")
        #expect(MoodRatingScale.descriptor(for: 2) == "Tender")
    }

    @Test("Descriptor mapping covers full range") func descriptorMapping() async throws {
        #expect(MoodRatingScale.descriptor(for: 3) == "Reflective")
        #expect(MoodRatingScale.descriptor(for: 5) == "Centered")
        #expect(MoodRatingScale.descriptor(for: 7) == "Uplifted")
        #expect(MoodRatingScale.descriptor(for: 10) == "Radiant")
    }

    @Test("Emoji mapping clamps high values") func emojiClampsHigh() async throws {
        #expect(MoodRatingScale.emoji(for: 11) == "✨")
        #expect(MoodRatingScale.emoji(for: 9) == "✨")
    }

    @Test("Emoji mapping covers reflective middle values") func emojiMapping() async throws {
        #expect(MoodRatingScale.emoji(for: 4) == "🌦️")
        #expect(MoodRatingScale.emoji(for: 6) == "🌤️")
        #expect(MoodRatingScale.emoji(for: 7) == "☀️")
    }
}
