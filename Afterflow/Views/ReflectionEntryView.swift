import SwiftUI

/// Dedicated reflection entry: mood-now bars, prompt chips, and a free text
/// field. Saving appends to `reflections` and writes `moodAfter`, which flips
/// the session to `.complete` and cancels any pending reminder via
/// `SessionStore.update`.
struct ReflectionEntryView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss

    let session: TherapeuticSession

    @State private var moodNow: Int
    @State private var reflectionText = ""
    @State private var usedPrompts: Set<String> = []
    @State private var saveError: String?
    @FocusState private var isEditorFocused: Bool

    private static let prompts = [
        "What emerged",
        "The hardest moment",
        "What I will carry",
        "In my body",
        "Someone I thought of"
    ]

    init(session: TherapeuticSession) {
        self.session = session
        _moodNow = State(initialValue: session.moodAfter ?? session.moodBefore)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignConstants.Spacing.lg) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How has it settled?")
                        .font(.afterflowDisplay(30))
                        .foregroundStyle(AF.text)
                    Text(self.contextLine)
                        .font(.afterflowBody(14))
                        .foregroundStyle(AF.neutral(600))
                }

                self.moodNowCard

                VStack(alignment: .leading, spacing: 8) {
                    KickerLabel("A place to start")
                    FlowLayout(spacing: 7) {
                        ForEach(Self.prompts, id: \.self) { prompt in
                            AFChip(
                                label: prompt,
                                isSelected: self.usedPrompts.contains(prompt),
                                style: .sage
                            ) {
                                self.applyPrompt(prompt)
                            }
                        }
                    }
                }

                self.reflectionField
            }
            .padding(.horizontal, DesignConstants.Spacing.large)
            .padding(.top, DesignConstants.Spacing.md)
            .padding(.bottom, DesignConstants.Spacing.xl)
        }
        .background(AF.bg)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Reflection")
                    .font(.afterflowBody(15, weight: .semibold))
                    .foregroundStyle(AF.text)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    self.save()
                } label: {
                    Text("Save")
                        .font(.afterflowBody(14, weight: .semibold))
                        .foregroundStyle(AF.onAccent)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 18)
                }
                .buttonStyle(AFCapsuleButtonStyle(fill: AF.accent, pressedFill: AF.accentPressed))
                .opacity(self.canSave ? 1 : 0.45)
                .disabled(!self.canSave)
                .accessibilityIdentifier("saveReflectionButton")
                .accessibilityHint("Saves your reflection and current mood")
            }
        }
        .errorAlert(title: "Save Failed", error: self.$saveError)
        .scrollDismissesKeyboard(.immediately)
    }

    // MARK: - Pieces

    private var contextLine: String {
        let treatment = self.session.treatmentType.displayName
        let dateText = self.session.sessionDate.formatted(.dateTime.month(.wide).day())
        let relative: String
        let calendar = Calendar.current
        if calendar.isDateInToday(self.session.sessionDate) {
            relative = "today"
        } else if calendar.isDateInYesterday(self.session.sessionDate) {
            relative = "yesterday"
        } else {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            relative = formatter.localizedString(for: self.session.sessionDate, relativeTo: Date())
        }
        return "\(treatment) · \(dateText) · \(relative)"
    }

    private var moodNowCard: some View {
        VStack(alignment: .leading, spacing: DesignConstants.Spacing.medium) {
            HStack {
                KickerLabel("Mood now")
                Spacer()
                Text("\(self.moodNow) · \(MoodRatingScale.descriptor(for: self.moodNow))")
                    .font(.afterflowBody(13, weight: .semibold))
                    .foregroundStyle(AF.accent(700))
            }

            MoodBars(value: self.$moodNow, style: .numbered)
                .accessibilityLabel("Mood now")
                .accessibilityIdentifier("moodNowBars")
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                .fill(AF.neutral(100))
        )
        .afShadow(.sm)
    }

    private var reflectionField: some View {
        TextEditor(text: self.$reflectionText)
            .font(.afterflowBody(16))
            .lineSpacing(16 * 0.65)
            .foregroundStyle(AF.text)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 150)
            .focused(self.$isEditorFocused)
            .accessibilityIdentifier("reflectionEntryEditor")
            .accessibilityLabel("Reflection")
            .overlay(alignment: .topLeading) {
                if self.reflectionText.isEmpty {
                    Text("Whatever is still with you — a phrase is enough.")
                        .font(.afterflowBody(16))
                        .foregroundStyle(AF.neutral(500))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.card, style: .continuous)
                    .fill(AF.neutral(100))
            )
            .afShadow(.sm)
    }

    // MARK: - Behavior

    private var canSave: Bool {
        !self.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Appends "<label> — " to the text (after a blank line when the field is
    /// non-empty) and marks the chip used. Never removes typed text.
    private func applyPrompt(_ prompt: String) {
        if self.reflectionText.isEmpty {
            self.reflectionText = "\(prompt) — "
        } else {
            self.reflectionText += "\n\n\(prompt) — "
        }
        self.usedPrompts.insert(prompt)
        self.isEditorFocused = true
    }

    private func save() {
        let text = self.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        self.session.addReflection(text)
        self.session.moodAfter = self.moodNow
        do {
            // Status flips to .complete via the computed property; the store's
            // scheduleReminderIfNeeded then cancels any pending reminder.
            try self.sessionStore.update(self.session)
            self.dismiss()
        } catch {
            self.saveError = "Failed to save reflection: \(error.localizedDescription)"
        }
    }
}
