import SwiftUI

/// Capsule segmented control from the Organic design system.
/// Light: neutral-200 track with a raised neutral-100 selected chip.
/// Dark: the inversion is baked into the `Theme/segmented*` colorsets —
/// track darker than the chip, with a 1px border.
struct AFSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let options: [(value: T, label: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(self.options, id: \.value) { option in
                Button {
                    withAnimation(
                        .spring(
                            response: DesignConstants.Animation.springResponse,
                            dampingFraction: DesignConstants.Animation.springDampingFraction
                        )
                    ) {
                        self.selection = option.value
                    }
                } label: {
                    Text(option.label)
                        .font(.afterflowBody(13, weight: .semibold))
                        .foregroundStyle(AF.text)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background {
                            if self.selection == option.value {
                                Capsule()
                                    .fill(AF.segmentedSelected)
                                    .afShadow(.sm)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(self.selection == option.value ? [.isSelected] : [])
            }
        }
        .padding(3)
        .background(Capsule().fill(AF.segmentedTrack))
        .overlay(Capsule().strokeBorder(AF.segmentedBorder, lineWidth: 1))
    }
}
