import SwiftUI

extension View {
    /// Applies a rounded rectangle glass effect background with fallback to ultraThinMaterial
    func glassPillBackground(cornerRadius: CGFloat = 25) -> some View {
        self.background {
            if #available(iOS 26.0, *) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                    .glassEffect()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
