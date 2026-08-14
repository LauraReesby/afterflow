import SwiftUI

struct MoodRatingView: View {
    @Binding var value: Int
    let title: String
    let accessibilityIdentifier: String

    private var descriptor: String {
        MoodRatingScale.descriptor(for: self.value)
    }

    private var emoji: String {
        MoodRatingScale.emoji(for: self.value)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(self.title)
                    .font(.afterflowBody(15, weight: .semibold))
                    .foregroundStyle(AF.text)

                Spacer()

                Text("\(self.emoji)  \(self.value)/10 • \(self.descriptor)")
                    .font(.afterflowBody(13))
                    .foregroundStyle(AF.neutral(600))
                    .accessibilityHidden(true)
            }

            MoodBars(value: self.$value)
                .accessibilityLabel("\(self.title) mood rating")
                .accessibilityIdentifier(self.accessibilityIdentifier)
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
    struct MoodRatingView_Previews: PreviewProvider {
        static var previews: some View {
            VStack(spacing: 24) {
                MoodRatingView(
                    value: .constant(3),
                    title: "Before Session",
                    accessibilityIdentifier: "moodBeforeSlider"
                )
                MoodRatingView(
                    value: .constant(8),
                    title: "After Session",
                    accessibilityIdentifier: "moodAfterSlider"
                )
            }
            .padding()
        }
    }
#endif
