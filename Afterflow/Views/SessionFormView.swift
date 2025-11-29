//  Constitutional Compliance: Privacy-First, SwiftUI Native, Therapeutic Value-First

//  Constitutional Compliance: Privacy-First, SwiftUI Native, Therapeutic Value-First

import SwiftData
import SwiftUI

struct SessionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore

    // MARK: - Form State

    @State private var sessionDate = Date()
    @State private var selectedTreatmentType = PsychedelicTreatmentType.ketamine
    @State private var selectedAdministration = AdministrationMethod.intravenous
    @State private var intention = ""
    @State private var moodBefore = 5
    @State private var moodAfter = 5

    // MARK: - Focus Management

    @FocusState private var focusedField: FormField?

    enum FormField: CaseIterable {
        case intention
    }

    // MARK: - Validation

    @State private var validator = FormValidation()
    @State private var intentionValidation: FieldValidationState?
    @State private var dateValidation: FieldValidationState?
    @State private var validationTask: Task<Void, Never>?
    @State private var draftSaveTask: Task<Void, Never>?

    // MARK: - UI State

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDateNormalizationHint = false
    @State private var dateNormalizationMessage = ""
    @State private var showReminderPrompt = false
    @State private var pendingSessionForReminder: TherapeuticSession?

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        let formData = SessionFormData(
            sessionDate: sessionDate,
            treatmentType: selectedTreatmentType,
            administration: selectedAdministration,
            intention: intention
        )
        return self.validator.validateForm(formData)
    }

    private var sessionPhase: SessionLifecycleStatus {
        let intentionComplete = !self.intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return intentionComplete ? .needsReflection : .draft
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SessionStatusIndicatorView(status: self.sessionPhase)
                        .listRowBackground(Color.clear)
                }

                Section {
                    DatePicker(
                        "Session Date",
                        selection: self.$sessionDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .onChange(of: self.sessionDate) { oldValue, newValue in
                        self.handleDateChange(from: oldValue, to: newValue)
                    }
                    .inlineValidation(self.dateValidation)

                    // Show date normalization hint if needed - use more stable layout
                    if self.showDateNormalizationHint, !self.dateNormalizationMessage.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                    .font(.caption)

                                Text(self.dateNormalizationMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                        }
                        .padding(.horizontal, 4)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: self.showDateNormalizationHint)
                    }
                } header: {
                    Text("1 · When is this session?")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Section {
                    Picker("Type", selection: self.$selectedTreatmentType) {
                        ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: self.selectedTreatmentType) { _, _ in
                        self.scheduleDraftSave()
                    }

                    Picker("Administration", selection: self.$selectedAdministration) {
                        ForEach(AdministrationMethod.allCases, id: \.self) { method in
                            Text(method.displayName).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: self.selectedAdministration) { _, _ in
                        self.scheduleDraftSave()
                    }
                } header: {
                    Text("2 · Treatment details")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Section {
                    TextField(
                        "What do you hope to explore or heal?",
                        text: self.$intention,
                        axis: .vertical
                    )
                    .lineLimit(3 ... 6)
                    .textContentType(.none)
                    .focused(self.$focusedField, equals: .intention)
                    .submitLabel(.done)
                    .onSubmit {
                        if self.isFormValid {
                            self.saveSession()
                        }
                    }
                    .onChange(of: self.intention) { _, _ in
                        self.debounceValidation()
                        self.scheduleDraftSave()
                    }
                    .inlineValidation(self.intentionValidation)
                    .accessibilityIdentifier("intentionField")
                    .accessibilityLabel("Intention")
                    .accessibilityHint("Describe what you hope to explore or heal during this session")
                } header: {
                    Text("3 · Set your intention")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

                Section {
                    MoodRatingView(
                        value: self.$moodBefore,
                        title: "Before Session",
                        accessibilityIdentifier: "moodBeforeSlider"
                    )
                    .onChange(of: self.moodBefore) { _, _ in
                        self.scheduleDraftSave()
                    }
                } header: {
                    Text("4 · Track your mood")
                        .font(.headline)
                        .foregroundColor(.primary)
                }

            }
            .navigationTitle("New Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        self.dismissKeyboard()
                        self.sessionStore.clearDraft()
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        self.saveSession()
                    }
                    .disabled(self.isLoading || !self.isFormValid)
                }
            }
            .disabled(self.isLoading)
            .contentShape(Rectangle())
            .onTapGesture {
                self.dismissKeyboard()
            }
            .scrollContentBackground(.visible)
        }
        .scrollDismissesKeyboard(.immediately)
        .alert("Error", isPresented: self.$showError) {
            Button("OK") {}
        } message: {
            Text(self.errorMessage)
        }
        .confirmationDialog(
            "Would you like a reminder to add reflections later?",
            isPresented: self.$showReminderPrompt,
            titleVisibility: .visible
        ) {
            Button("In 3 hours") { self.handleReminderSelection(.threeHours) }
            Button("Tomorrow") { self.handleReminderSelection(.tomorrow) }
            Button("None") { self.handleReminderSelection(.none) }
        }
        .onAppear {
            self.setupInitialState()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.intention.isEmpty {
                    self.focusedField = .intention
                }
            }
        }
        .onDisappear {
            self.draftSaveTask?.cancel()
            if !self.isLoading, self.pendingSessionForReminder == nil {
                self.sessionStore.clearDraft()
            }
        }
    }

    // MARK: - Validation Methods

    private func handleDateChange(from oldDate: Date, to newDate: Date) {
        // Normalize the date
        let normalizedDate = self.validator.normalizeSessionDate(newDate)

        // Check if normalization changed the date significantly
        if let message = validator.getDateNormalizationMessage(originalDate: newDate, normalizedDate: normalizedDate) {
            // Update the date to normalized version if significantly different
            if abs(normalizedDate.timeIntervalSince(newDate)) > 60 {
                self.sessionDate = normalizedDate
            }

            // Show hint message
            self.dateNormalizationMessage = message
            self.showDateNormalizationHint = true

            // Hide hint after 4 seconds
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                self.showDateNormalizationHint = false
            }
        }

        self.debounceValidation()
        self.scheduleDraftSave()
    }

    private func debounceValidation() {
        // Cancel previous validation task
        self.validationTask?.cancel()

        // Start new validation task with 300ms delay
        self.validationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))

            guard !Task.isCancelled else { return }

            self.performValidation()
        }
    }

    @MainActor private func performValidation() {
        // Validate individual fields with enhanced date validation
        self.intentionValidation = self.validator.validateIntention(self.intention)

        // Use normalized date for validation
        let normalizedDate = self.validator.normalizeSessionDate(self.sessionDate)
        self.dateValidation = self.validator.validateSessionDate(normalizedDate)
    }

    // MARK: - Lifecycle

    private func setupInitialState() {
        if let draft = self.sessionStore.recoverDraft() {
            self.applyDraft(draft)
            return
        }

        if let lastSession = self.sessionStore.sessions.first {
            self.selectedTreatmentType = lastSession.treatmentType
            self.selectedAdministration = lastSession.administration
        } else {
            self.selectedTreatmentType = .ketamine
            self.selectedAdministration = .intravenous
        }

        // Perform initial validation
        Task { @MainActor in
            self.performValidation()
        }
    }

    // MARK: - Actions

    private func dismissKeyboard() {
        self.focusedField = nil
    }

    private func saveSession() {
        // Normalize date before final validation and saving
        let normalizedDate = self.validator.normalizeSessionDate(self.sessionDate)

        // Final validation before saving
        let formData = SessionFormData(
            sessionDate: normalizedDate,
            treatmentType: selectedTreatmentType,
            administration: selectedAdministration,
            intention: intention
        )

        guard self.validator.validateForm(formData) else {
            self.performValidation()
            return
        }

        guard self.sessionPhase == .needsReflection else {
            self.showError(message: "Finish the intention and mood before saving.")
            return
        }

        self.isLoading = true
        defer { isLoading = false }

        let newSession = TherapeuticSession(
            sessionDate: normalizedDate,
            treatmentType: selectedTreatmentType,
            administration: self.selectedAdministration,
            intention: self.intention.trimmingCharacters(in: .whitespacesAndNewlines),
            moodBefore: self.moodBefore,
            moodAfter: self.moodAfter
        )

        Task {
            do {
                try self.sessionStore.create(newSession)
                self.sessionStore.clearDraft()
                await MainActor.run {
                    self.pendingSessionForReminder = newSession
                    self.showReminderPrompt = true
                }
            } catch {
                await MainActor.run {
                    self.showError(message: "Unable to save session: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showError(message: String) {
        self.errorMessage = message
        self.showError = true
    }

    private func applyDraft(_ draft: TherapeuticSession) {
        self.sessionDate = draft.sessionDate
        self.selectedTreatmentType = draft.treatmentType
        self.selectedAdministration = draft.administration
        self.intention = draft.intention
        self.moodBefore = draft.moodBefore
        self.moodAfter = draft.moodAfter
    }

    private func scheduleDraftSave() {
        self.draftSaveTask?.cancel()
        let snapshot = self.buildDraftSnapshot()
        self.draftSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self.sessionStore.saveDraft(snapshot)
        }
    }

    private func buildDraftSnapshot() -> TherapeuticSession {
        let normalizedDate = self.validator.normalizeSessionDate(self.sessionDate)
        return TherapeuticSession(
            sessionDate: normalizedDate,
            treatmentType: self.selectedTreatmentType,
            administration: self.selectedAdministration,
            intention: self.intention,
            moodBefore: self.moodBefore,
            moodAfter: self.moodAfter,
            reminderDate: nil
        )
    }

    private func handleReminderSelection(_ selection: ReminderOption) {
        guard let session = self.pendingSessionForReminder else {
            self.dismiss()
            return
        }

        Task { @MainActor in
            do {
                try await self.sessionStore.setReminder(for: session, option: selection)
                self.pendingSessionForReminder = nil
                self.dismiss()
            } catch {
                self.showError(message: "Reminder preference could not be saved: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: TherapeuticSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
    return SessionFormView()
        .modelContainer(container)
        .environment(store)
}
