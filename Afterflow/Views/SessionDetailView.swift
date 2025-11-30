//  Constitutional Compliance: Privacy-First Reflections

import SwiftData
import SwiftUI

struct SessionDetailView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let session: TherapeuticSession

    @State private var showingEdit = false

    var body: some View {
        List {
            self.summarySection

            Section("When") {
                SessionDetailRow(title: "Date & Time", value: self.dateFormatter.string(from: self.session.sessionDate))
            }

            Section("Treatment") {
                SessionDetailRow(title: "Type", value: self.session.treatmentType.displayName)
                SessionDetailRow(title: "Administration", value: self.session.administration.displayName)
            }

            Section("Intention") {
                Text(self.session.intention.isEmpty ? "No intention captured." : self.session.intention)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("Mood") {
                self.moodRow(title: "Before", value: self.session.moodBefore)
                if self.hasAfterMood {
                    self.moodRow(title: "After", value: self.session.moodAfter)
                } else {
                    SessionDetailRow(title: "After", value: "Not added yet")
                }
            }

            Section("Music") {
                if self.session.hasMusicLink {
                    MusicLinkSummaryCard(session: self.session)
                    if let url = session.preferredOpenURL {
                        Button {
                            self.openURL(url)
                        } label: {
                            Label("Open link", systemImage: "arrow.up.right.square")
                                .font(.subheadline)
                        }
                    }
                } else {
                    Text("No playlist attached")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Reflection") {
                if self.session.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("You haven’t added reflections yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(self.session.reflections)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Edit") {
                    self.showingEdit = true
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .sheet(isPresented: self.$showingEdit) {
            NavigationStack {
                SessionFormView(session: self.session)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(16)
            .toolbarBackground(.visible, for: .automatic)
        }
    }

    private var summarySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text(
                    "\(self.session.treatmentType.displayName) • \(self.dateFormatter.string(from: self.session.sessionDate))"
                )
                .font(.headline)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Intention")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(self.session.intention.isEmpty ? "Not captured" : self.session.intention)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Label {
                        Text(self.session.status.displayName)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: self.session.status.symbolName)
                    }
                    .foregroundStyle(self.session.status.accentColor)

                    Text(self.moodSummaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if self.session.status == .needsReflection {
                    if let reminderLabel = self.session.reminderDisplayText {
                        Label("Reminder: \(reminderLabel)", systemImage: "bell")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("detailReminderLabel")
                    } else {
                        Label("No reminder scheduled", systemImage: "bell.slash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("detailReminderLabel")
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 8, leading: 0, bottom: 0, trailing: 0))
    }

    private func moodRow(title: String, value: Int, placeholder: String = "") -> some View {
        let descriptor = MoodRatingScale.descriptor(for: value)
        let emoji = MoodRatingScale.emoji(for: value)
        return AnyView(SessionDetailRow(title: title, value: "\(value) (\(descriptor)) \(emoji)"))
    }

    private var hasAfterMood: Bool {
        let reflectionSet = !self.session.reflections.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return reflectionSet || self.session.moodAfter != 5
    }

    private var moodSummaryText: String {
        let beforeDescriptor = MoodRatingScale.descriptor(for: self.session.moodBefore)
        let afterDescriptor = MoodRatingScale.descriptor(for: self.session.moodAfter)
        let before = "\(session.moodBefore) (\(beforeDescriptor))"

        if self.hasAfterMood {
            let after = "\(session.moodAfter) (\(afterDescriptor))"
            return "Mood • \(before) → \(after)"
        } else {
            return "Mood • \(before) → —"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

private struct SessionDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(self.title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(self.value)
                .multilineTextAlignment(.trailing)
        }
        .font(.body)
    }
}

private extension SessionLifecycleStatus {
    var symbolName: String {
        switch self {
        case .draft: "square.dashed"
        case .needsReflection: "hourglass"
        case .complete: "checkmark.seal.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .draft: .blue
        case .needsReflection: .orange
        case .complete: .green
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: TherapeuticSession.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
    let session = TherapeuticSession(intention: "Feel more open with my partner", moodBefore: 4, moodAfter: 7)
    try! store.create(session)
    return NavigationStack {
        SessionDetailView(session: session)
    }
    .modelContainer(container)
    .environment(store)
}
