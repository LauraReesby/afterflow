import SwiftUI

struct SessionRowView: View {
    let session: TherapeuticSession
    let dateText: String
    var reflectionSnippet: String?

    init(session: TherapeuticSession, dateText: String, reflectionSnippet: String? = nil) {
        self.session = session
        self.dateText = dateText
        self.reflectionSnippet = reflectionSnippet
    }

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

                if let snippet = self.reflectionSnippet {
                    Text(snippet)
                        .font(.afterflowBody(12))
                        .lineSpacing(12 * 0.45)
                        .foregroundStyle(AF.accent(900))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 11)
                        .background(
                            RoundedRectangle(
                                cornerRadius: DesignConstants.CornerRadius.medium,
                                style: .continuous
                            )
                            .fill(AF.accent(100))
                        )
                        .overlay(alignment: .leading) {
                            UnevenRoundedRectangle(
                                topLeadingRadius: DesignConstants.CornerRadius.medium,
                                bottomLeadingRadius: DesignConstants.CornerRadius.medium
                            )
                            .fill(AF.accent(400))
                            .frame(width: 2)
                        }
                        .padding(.top, 4)
                        .accessibilityLabel("Matching reflection: \(snippet)")
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
        if let moodAfter = self.session.moodAfter {
            "mood \(self.session.moodBefore) → \(moodAfter)"
        } else {
            "mood \(self.session.moodBefore) · after not added"
        }
    }
}
