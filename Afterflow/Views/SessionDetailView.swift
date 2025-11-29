//  Constitutional Compliance: Privacy-First Reflections

import SwiftData
import SwiftUI

struct SessionDetailView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss

    let session: TherapeuticSession

    @State private var viewModel: SessionDetailViewModel?
    @FocusState private var editorFocused: FormField?

    enum FormField: Hashable {
        case reflection
    }

    init(session: TherapeuticSession) {
        self.session = session
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Time")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(self.session.sessionDate.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Type")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(self.session.treatmentType.displayName)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Session context")
            }

            Section {
                Picker("Administration", selection: Binding(
                    get: { self.viewModel?.administration ?? .oral },
                    set: { self.viewModel?.administration = $0 }
                )) {
                    ForEach(AdministrationMethod.allCases, id: \.self) { method in
                        Text(method.displayName).tag(method)
                    }
                }

                TextField("Environment", text: Binding(
                    get: { self.viewModel?.environmentNotes ?? "" },
                    set: { self.viewModel?.environmentNotes = $0 }
                ), axis: .vertical)

                TextField("Music", text: Binding(
                    get: { self.viewModel?.musicNotes ?? "" },
                    set: { self.viewModel?.musicNotes = $0 }
                ), axis: .vertical)

                MoodRatingView(
                    value: Binding(
                        get: { self.viewModel?.moodBefore ?? self.session.moodBefore },
                        set: { self.viewModel?.moodBefore = $0 }
                    ),
                    title: "Before Session",
                    accessibilityIdentifier: "detailMoodBefore"
                )

                MoodRatingView(
                    value: Binding(
                        get: { self.viewModel?.moodAfter ?? self.session.moodAfter },
                        set: { self.viewModel?.moodAfter = $0 }
                    ),
                    title: "After Session",
                    accessibilityIdentifier: "detailMoodAfter"
                )
            } header: {
                Text("Session details")
            }

            Section("Intention") {
                TextField(
                    "Intention",
                    text: .constant(self.session.intention),
                    axis: .vertical
                )
                .disabled(true)
            }

            Section("Reflections") {
                TextEditor(text: Binding(
                    get: { self.viewModel?.reflectionText ?? "" },
                    set: { self.viewModel?.reflectionText = $0 }
                ))
                .frame(minHeight: 160)
                .focused(self.$editorFocused, equals: .reflection)
                .accessibilityIdentifier("reflectionEditor")

                if let errorMessage = self.viewModel?.errorMessage {
                    ValidationErrorView(message: errorMessage)
                        .padding(.top, 4)
                        .accessibilityIdentifier("reflectionErrorBanner")
                }
            }
        }
        .navigationTitle(
            self.session.sessionDate.formatted(date: .abbreviated, time: .omitted)
        )
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.visible)
        .scrollDismissesKeyboard(.immediately)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    self.saveReflection()
                    self.dismiss()
                }
                .disabled(!(self.viewModel?.hasChanges ?? false) || (self.viewModel?.isSaving ?? true))
            }
        }
        .onAppear {
            self.prepareViewModelIfNeeded()
        }
    }

    private func saveReflection() {
        guard let viewModel = self.viewModel else { return }
        viewModel.saveReflection()
    }

    private func prepareViewModelIfNeeded() {
        guard self.viewModel == nil else { return }
        self.viewModel = SessionDetailViewModel(session: self.session, persistence: self.sessionStore)
    }
}

#Preview {
    let container: ModelContainer
    do {
        container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
    let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
    let previewSession = TherapeuticSession(
        treatmentType: .psilocybin,
        intention: "Integrate recent therapy insights",
        moodBefore: 4,
        moodAfter: 8,
        reflections: "Felt a deeper sense of clarity around recurring patterns."
    )
    do {
        try store.create(previewSession)
    } catch {
        fatalError("Failed to insert preview session: \(error)")
    }
    return SessionDetailView(session: previewSession)
        .modelContainer(container)
        .environment(store)
}
