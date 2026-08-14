import SwiftUI

/// Standard content card: neutral-100 fill, 28pt radius, small shadow.
struct TokenCard<Content: View>: View {
    var padding: CGFloat
    @ViewBuilder let content: () -> Content

    init(padding: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        self.content()
            .padding(self.padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                    .fill(AF.neutral(100))
            )
            .afShadow(.sm)
    }
}
