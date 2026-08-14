import SwiftUI

struct TreatmentAvatar: View {
    let type: PsychedelicTreatmentType
    let size: CGFloat

    init(type: PsychedelicTreatmentType, size: CGFloat = 38) {
        self.type = type
        self.size = size
    }

    var body: some View {
        // Flat fill is intentional per the Organic design system — no gradients or overlays.
        Circle()
            .fill(self.type.accentColor)
            .overlay {
                Text(self.type.initials)
                    .font(.afterflowBody(self.initialsSize, weight: .bold))
                    .foregroundStyle(Color("Treatment/ink"))
                    .accessibilityHidden(true)
            }
            .frame(width: self.size, height: self.size)
            .accessibilityIdentifier("treatmentAvatar")
    }

    private var initialsSize: CGFloat {
        self.size >= 52 ? 17 : 13
    }
}
