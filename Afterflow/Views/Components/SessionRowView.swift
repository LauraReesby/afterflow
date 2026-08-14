import SwiftUI

struct SessionRowView: View {
    let session: TherapeuticSession
    let dateText: String

    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            TreatmentAvatar(type: self.session.treatmentType)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(self.session.treatmentType.displayName)
                        .font(.afterflowBody(16, weight: .semibold))
                        .foregroundStyle(AF.text)
                    Spacer(minLength: 8)
                    Text(self.dateText)
                        .font(.afterflowBody(12))
                        .foregroundStyle(AF.neutral(600))
                }

                if !self.session.intention.isEmpty {
                    Text(self.session.intention)
                        .font(.afterflowBody(13))
                        .foregroundStyle(AF.neutral(700))
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    StatusTag(status: self.session.status)

                    Text(self.moodText)
                        .font(.afterflowBody(11))
                        .foregroundStyle(AF.neutral(600))

                    if self.session.status == .needsReflection,
                       let reminderText = self.session.reminderRelativeDescription {
                        HStack(spacing: 3) {
                            Image(systemName: "bell")
                                .font(.system(size: 10, weight: .semibold))
                                .accessibilityHidden(true)
                            Text(reminderText)
                                .font(.afterflowBody(11))
                                .accessibilityIdentifier("needsReflectionReminderLabel")
                        }
                        .foregroundStyle(AF.accent(700))
                    }
                }
                .padding(.top, 3)
            }
        }
        .padding(.vertical, 2)
    }

    private var moodText: String {
        if self.session.hasAfterMood {
            "mood \(self.session.moodBefore) → \(self.session.moodAfter)"
        } else {
            "mood \(self.session.moodBefore) · after not added"
        }
    }
}
