import SwiftUI

/// Session lifecycle status tag: sage for complete, terracotta for reflect,
/// neutral for draft.
struct StatusTag: View {
    let status: SessionLifecycleStatus

    var body: some View {
        Text(self.labelText)
            .font(.afterflowBody(11, weight: .semibold))
            .foregroundStyle(self.foreground)
            .padding(.horizontal, 9)
            .padding(.vertical, 2)
            .background(Capsule().fill(self.background))
    }

    private var labelText: String {
        switch self.status {
        case .needsReflection: "Reflect"
        default: self.status.displayName
        }
    }

    private var background: Color {
        switch self.status {
        case .complete: AF.accent2(200)
        case .needsReflection: AF.accent(200)
        case .draft: AF.neutral(200)
        }
    }

    private var foreground: Color {
        switch self.status {
        case .complete: AF.accent2(800)
        case .needsReflection: AF.accent(800)
        case .draft: AF.neutral(700)
        }
    }
}
