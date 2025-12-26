import SwiftUI

struct SessionRowView: View {
    let session: TherapeuticSession
    let dateText: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            TreatmentAvatar(type: self.session.treatmentType)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(self.session.treatmentType.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 6) {
                        Text(self.dateText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }

                if self.session.status == .needsReflection {
                    HStack(spacing: 8) {
                        HStack(spacing: 3) {
                            Image(systemName: "hourglass")
                            Text("Reflect")
                        }
                        .font(.footnote)
                        .foregroundColor(.orange)

                        if let reminderLabel = session.reminderRelativeDescription {
                            HStack(spacing: 3) {
                                Image(systemName: "bell")
                                Text(reminderLabel)
                            }
                            .font(.footnote)
                            .foregroundColor(Color(.systemRed).opacity(0.7))
                            .accessibilityIdentifier("needsReflectionReminderLabel")
                        }
                    }
                } else if self.session.status == .complete {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.circle")
                        Text("Complete")
                    }
                    .font(.footnote)
                    .foregroundColor(.green)
                }

                if !self.session.intention.isEmpty {
                    Text(self.session.intention)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }
}
