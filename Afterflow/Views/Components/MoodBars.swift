import SwiftUI

/// Ten tappable mood steps replacing the old slider: easier to hit and shows
/// the whole 1–10 scale at once. Steps below the value are accent-300, the
/// selected step is full accent, the rest neutral-200.
struct MoodBars: View {
    enum Style {
        /// Height 34, unnumbered — the new-session form.
        case plain
        /// Height 38 with numerals and tender/radiant end labels — reflection.
        case numbered
    }

    @Binding var value: Int
    var style: Style = .plain

    private var barHeight: CGFloat {
        self.style == .plain ? 34 : 38
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                HStack(spacing: 5) {
                    ForEach(1 ... 10, id: \.self) { step in
                        Capsule()
                            .fill(self.fill(for: step))
                            .overlay(alignment: .bottom) {
                                if self.style == .numbered {
                                    Text("\(step)")
                                        .font(.afterflowBody(10, weight: .semibold))
                                        .foregroundStyle(self.numeralColor(for: step))
                                        .padding(.bottom, 5)
                                }
                            }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            self.setValue(forX: gesture.location.x, width: geometry.size.width)
                        }
                )
            }
            .frame(height: self.barHeight)

            if self.style == .numbered {
                HStack {
                    Text("tender")
                    Spacer()
                    Text("radiant")
                }
                .font(.afterflowBody(11))
                .foregroundStyle(AF.neutral(600))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityValue("\(self.value) of 10, \(MoodRatingScale.descriptor(for: self.value))")
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
    }

    private func fill(for step: Int) -> Color {
        if step == self.value {
            AF.accent
        } else if step < self.value {
            AF.accent(300)
        } else {
            AF.neutral(200)
        }
    }

    private func numeralColor(for step: Int) -> Color {
        step == self.value ? AF.onAccent : AF.neutral(600)
    }

    private func setValue(forX x: CGFloat, width: CGFloat) {
        guard width > 0 else { return }
        let step = Int(x / width * 10) + 1
        self.value = min(max(step, 1), 10)
    }
}
