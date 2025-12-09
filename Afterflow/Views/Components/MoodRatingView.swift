import SwiftUI

struct MoodRatingView: View {
    @Binding var value: Int
    let title: String
    let accessibilityIdentifier: String

    private var sliderBinding: Binding<Double> {
        Binding<Double>(
            get: { Double(self.value) },
            set: { self.value = Int($0.rounded()) }
        )
    }

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
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(self.emoji)  \(self.value)/10 • \(self.descriptor)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            Slider(
                value: self.sliderBinding,
                in: 1 ... 10,
                step: 1
            )
            .tint(Color("AccentColor"))
            .accessibilityLabel("\(self.title) mood rating")
            .accessibilityValue("\(self.value) of 10, \(self.descriptor)")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    self.value = min(self.value + 1, 10)
                case .decrement:
                    self.value = max(self.value - 1, 1)
                default:
                    break
                }
            }
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
