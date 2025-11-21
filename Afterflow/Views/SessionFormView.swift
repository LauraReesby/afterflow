//  Constitutional Compliance: Privacy-First, SwiftUI Native, Therapeutic Value-First

//  Constitutional Compliance: Privacy-First, SwiftUI Native, Therapeutic Value-First

import SwiftData
import SwiftUI

struct SessionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var sessionDataService: SessionDataService?

    // MARK: - Form State

    @State private var sessionDate = Date()
    @State private var selectedTreatmentType = PsychedelicTreatmentType.psilocybin
    @State private var dosage = ""
    @State private var selectedAdministration = AdministrationMethod.oral
    @State private var intention = ""
    @State private var moodBefore = 5
    @State private var moodAfter = 5

    // MARK: - Focus Management

    @FocusState private var focusedField: FormField?

    enum FormField: CaseIterable {
        case dosage
        case intention
    }

    // MARK: - Validation

    @State private var validator = FormValidation()
    @State private var intentionValidation: ValidationResult?
    @State private var dateValidation: ValidationResult?
    @State private var dosageValidation: ValidationResult?
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
    private let reminderScheduler = ReminderScheduler()

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        let formData = SessionFormData(
            sessionDate: sessionDate,
            treatmentType: selectedTreatmentType,
            dosage: dosage,
            administration: selectedAdministration,
            intention: intention
        )
        let formValidation = self.validator.validateForm(formData)
        return formValidation.isValid
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
                    Picker("Treatment Type", selection: self.$selectedTreatmentType) {
                        ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: self.selectedTreatmentType) { _, _ in
                        self.scheduleDraftSave()
                    }

                    TextField("Dosage (e.g., 3.5g, 100μg)", text: self.$dosage)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                        .focused(self.$focusedField, equals: .dosage)
                        .submitLabel(.next)
                        .onSubmit {
                            self.focusedField = .intention
                        }
                        .onChange(of: self.dosage) { _, _ in
                            self.debounceValidation()
                            self.scheduleDraftSave()
                        }
                        .inlineValidation(self.dosageValidation)
                        .accessibilityIdentifier("dosageField")
                        .accessibilityLabel("Dosage")
                        .accessibilityHint("Enter the amount taken, for example 3.5g or 100μg")

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
                } footer: {
                    Text("Take a moment to reflect on your hopes for this session")
                        .font(.caption)
                        .foregroundColor(.secondary)
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

                    MoodRatingView(
                        value: self.$moodAfter,
                        title: "After Session",
                        accessibilityIdentifier: "moodAfterSlider"
                    )
                    .onChange(of: self.moodAfter) { _, _ in
                        self.scheduleDraftSave()
                    }
                } header: {
                    Text("4 · Track your mood")
                        .font(.headline)
                        .foregroundColor(.primary)
                } footer: {
                    Text("Notice how your mood shifts before and after.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan for reflections later")
                            .font(.headline)
                        Text(
                            "Once you save this draft we’ll highlight it as “Needs Reflection” and you can capture environment notes, reflections, and reminders."
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Later · Needs Reflection")
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
                        self.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        self.saveSession()
                    }
                    .disabled(self.isLoading || !self.isFormValid)
                }

                // Keyboard toolbar for better UX
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        self.dismissKeyboard()
                    }
                }
            }
            .disabled(self.isLoading)
            .contentShape(Rectangle())
            .onTapGesture {
                self.dismissKeyboard()
            }
        }
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
            Button("In 1 hour") { self.handleReminderSelection(.oneHour) }
            Button("Later today") { self.handleReminderSelection(.laterToday) }
            Button("Tomorrow morning") { self.handleReminderSelection(.tomorrowMorning) }
            Button("No thanks", role: .cancel) { self.handleReminderSelection(.none) }
        }
        .onAppear {
            self.setupInitialState()

            // Auto-focus first text field for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.dosage.isEmpty {
                    self.focusedField = .dosage
                } else if self.intention.isEmpty {
                    self.focusedField = .intention
                }
            }
        }
        .onDisappear {
            self.draftSaveTask?.cancel()
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

        self.dosageValidation = self.validator.validateDosage(self.dosage)
    }

    // MARK: - Lifecycle

    private func setupInitialState() {
        let service = self.ensureDataService()
        if let draft = service.recoverDraft() {
            self.applyDraft(draft)
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
            dosage: dosage,
            administration: selectedAdministration,
            intention: intention
        )

        let formValidation = self.validator.validateForm(formData)

        guard formValidation.isValid else {
            self.showError(message: formValidation.errors.first ?? "Please check your inputs")
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
            dosage: dosage.trimmingCharacters(in: .whitespacesAndNewlines),
            administration: self.selectedAdministration,
            intention: self.intention.trimmingCharacters(in: .whitespacesAndNewlines),
            moodBefore: self.moodBefore,
            moodAfter: self.moodAfter,
            status: .needsReflection
        )

        Task {
            do {
                await self.reminderScheduler.requestPermissionIfNeeded()
                let service = self.ensureDataService()
                try service.createSession(newSession)
                service.clearDraft()
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

    @discardableResult private func ensureDataService() -> SessionDataService {
        if let service = sessionDataService {
            return service
        }

        let service = SessionDataService(modelContext: modelContext)
        self.sessionDataService = service
        return service
    }

    private func applyDraft(_ draft: TherapeuticSession) {
        self.sessionDate = draft.sessionDate
        self.selectedTreatmentType = draft.treatmentType
        self.dosage = draft.dosage
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
            self.ensureDataService().saveDraft(snapshot)
        }
    }

    private func buildDraftSnapshot() -> TherapeuticSession {
        let normalizedDate = self.validator.normalizeSessionDate(self.sessionDate)
        return TherapeuticSession(
            sessionDate: normalizedDate,
            treatmentType: self.selectedTreatmentType,
            dosage: self.dosage,
            administration: self.selectedAdministration,
            intention: self.intention,
            moodBefore: self.moodBefore,
            moodAfter: self.moodAfter,
            status: self.sessionPhase,
            reminderDate: nil
        )
    }

    private func handleReminderSelection(_ selection: ReminderOption) {
        guard let session = self.pendingSessionForReminder else {
            self.dismiss()
            return
        }

        let service = self.ensureDataService()

        session.reminderDate = selection.targetDate(from: Date())

        Task {
            do {
                try service.updateSession(session)
                if let reminderDate = session.reminderDate, reminderDate > Date() {
                    try await self.reminderScheduler.scheduleReminder(for: session)
                } else {
                    self.reminderScheduler.cancelReminder(for: session)
                }
            } catch {
                await MainActor.run {
                    self.showError(message: "Reminder preference could not be saved: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                self.pendingSessionForReminder = nil
                self.dismiss()
            }
        }
    }
}

#Preview {
    SessionFormView()
        .modelContainer(for: TherapeuticSession.self, inMemory: true)
}
