import SwiftUI

struct SessionStatusIndicatorView: View {
    let status: SessionLifecycleStatus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: self.iconName)
                .foregroundStyle(self.iconColor)
                .imageScale(.large)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.headline)
                Text(self.detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(self.backgroundTint)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.title)
        .accessibilityHint(self.detail)
    }

    private var title: String {
        switch self.status {
        case .draft:
            "Draft • Capture your intention"
        case .needsReflection:
            "Needs Reflection • Return later to reflect"
        case .complete:
            "Complete • Reflections saved"
        }
    }

    private var detail: String {
        switch self.status {
        case .draft:
            "Complete the required fields below to save this entry and set an optional reminder."
        case .needsReflection:
            "This session is waiting for reflections. You'll see it highlighted in your history until you finish."
        case .complete:
            "This session is complete. You can still update reflections any time."
        }
    }

    private var iconName: String {
        switch self.status {
        case .draft: "square.fill"
        case .needsReflection: "square.lefthalf.fill"
        case .complete: "checkmark.square.fill"
        }
    }

    private var iconColor: Color {
        switch self.status {
        case .draft: .blue
        case .needsReflection: .orange
        case .complete: .green
        }
    }

    private var backgroundTint: Color {
        switch self.status {
        case .draft: Color.blue.opacity(0.15)
        case .needsReflection: Color.orange.opacity(0.15)
        case .complete: Color.green.opacity(0.15)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SessionStatusIndicatorView(status: .draft)
        SessionStatusIndicatorView(status: .needsReflection)
        SessionStatusIndicatorView(status: .complete)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
