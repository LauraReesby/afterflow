//  Constitutional Compliance: Privacy-First, SwiftUI Native, Therapeutic Value-First

import SwiftData
import SwiftUI

struct SessionFormView: View {
    private enum Mode {
        case create
        case edit(TherapeuticSession)

        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }

        var session: TherapeuticSession? {
            switch self {
            case .create:
                nil
            case let .edit(session):
                session
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore

    private let mode: Mode

    // MARK: - Form State

    @State private var sessionDate: Date
    @State private var selectedTreatmentType: PsychedelicTreatmentType
    @State private var selectedAdministration: AdministrationMethod
    @State private var intention: String
    @State private var moodBefore: Int
    @State private var moodAfter: Int
    @State private var reflectionText: String

    // MARK: - Focus Management

    @FocusState private var focusedField: FormField?

    enum FormField: CaseIterable {
        case intention
        case reflection
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

    // MARK: - Init

    init(session: TherapeuticSession? = nil) {
        if let session {
            self.mode = .edit(session)
            _sessionDate = State(initialValue: session.sessionDate)
            _selectedTreatmentType = State(initialValue: session.treatmentType)
            _selectedAdministration = State(initialValue: session.administration)
            _intention = State(initialValue: session.intention)
            _moodBefore = State(initialValue: session.moodBefore)
            _moodAfter = State(initialValue: session.moodAfter)
            _reflectionText = State(initialValue: session.reflections)
        } else {
            self.mode = .create
            _sessionDate = State(initialValue: Date())
            _selectedTreatmentType = State(initialValue: .ketamine)
            _selectedAdministration = State(initialValue: .intravenous)
            _intention = State(initialValue: "")
            _moodBefore = State(initialValue: 5)
            _moodAfter = State(initialValue: 5)
            _reflectionText = State(initialValue: "")
        }
    }

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

    private var navigationTitle: String {
        self.mode.isEditing ? "Edit Session" : "New Session"
    }

    private var statusTitle: String {
        if let session = self.mode.session {
            return "\(session.treatmentType.displayName) • \(session.status.displayName)"
        }
        return "Draft • Capture your intention"
    }

    private var statusSubtitle: String {
        self.mode.isEditing ? "Update details and tap Done when finished." : "You can add mood and reflections later."
    }

    private var primaryButtonTitle: String {
        self.mode.isEditing ? "Done" : "Save"
    }

    private var showStickyFooter: Bool { !self.mode.isEditing }

    private var editingSession: TherapeuticSession? { self.mode.session }

    private var statusBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(self.statusTitle)
                .font(.headline)
            Text(self.statusSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var moodSection: some View {
        if self.mode.isEditing {
            Section("Mood") {
                VStack(alignment: .leading, spacing: 16) {
                    MoodRatingView(
                        value: self.$moodBefore,
                        title: "Before Session",
                        accessibilityIdentifier: "moodBeforeSlider"
                    )
                    MoodRatingView(
                        value: self.$moodAfter,
                        title: "After Session",
                        accessibilityIdentifier: "moodAfterSlider"
                    )
                }
                .onChange(of: self.moodBefore) { _, _ in
                    self.scheduleDraftSave()
                }
                .onChange(of: self.moodAfter) { _, _ in
                    self.scheduleDraftSave()
                }
            }
        } else {
            Section("Mood before") {
                VStack(alignment: .leading, spacing: 8) {
                    MoodRatingView(
                        value: self.$moodBefore,
                        title: "Before Session",
                        accessibilityIdentifier: "moodBeforeSlider"
                    )
                }
                .onChange(of: self.moodBefore) { _, _ in
                    self.scheduleDraftSave()
                }
            }
        }
    }

    @ViewBuilder
    private var reflectionSection: some View {
        if self.mode.isEditing {
            Section("Reflection") {
                TextEditor(text: self.$reflectionText)
                    .frame(minHeight: 140)
                    .focused(self.$focusedField, equals: .reflection)
                    .accessibilityIdentifier("reflectionEditor")
            }
        } else {
            Section("Reflection") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reflections are for after your session.")
                        .font(.subheadline)
                    Text("We'll remind you gently when you're ready.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    // MARK: - Body

    var body: some View {
        List {
            Section {
                self.statusBanner
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.init(top: 8, leading: 0, bottom: 0, trailing: 0))

            Section("When is this session?") {
                DatePicker(
                    "Date & Time",
                    selection: self.$sessionDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
                .onChange(of: self.sessionDate) { oldValue, newValue in
                    self.handleDateChange(from: oldValue, to: newValue)
                }
                .inlineValidation(self.dateValidation)

                if self.showDateNormalizationHint, !self.dateNormalizationMessage.isEmpty {
                    Text(self.dateNormalizationMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Treatment") {
                Picker("Treatment Type", selection: self.$selectedTreatmentType) {
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
            }

            Section("Intention") {
                TextField(
                    "What do you hope to explore or heal?",
                    text: self.$intention,
                    axis: .vertical
                )
                .lineLimit(3 ... 6)
                .focused(self.$focusedField, equals: .intention)
                .submitLabel(.done)
                .textInputAutocapitalization(.sentences)
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
            }

            self.moodSection

            Section("Music") {
                if let session = self.editingSession, session.hasMusicLink {
                    MusicLinkSummaryCard(session: session)
                } else {
                    Button {
                        // Placeholder action – handled in Feature 002
                    } label: {
                        Label("Attach music link", systemImage: "link")
                    }
                    .buttonStyle(.borderless)
                }
            }

            self.reflectionSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(self.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    self.cancel()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(self.primaryButtonTitle) {
                    self.saveSession()
                }
                .disabled(self.isLoading || !self.isFormValid)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Hide Keyboard") {
                    self.focusedField = nil
                }
                .accessibilityIdentifier("keyboardAccessoryHide")
                .disabled(self.focusedField == nil)
            }
        }
        .disabled(self.isLoading)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            if self.showStickyFooter {
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: self.saveSession) {
                        Text("Save Draft")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("saveDraftButton")
                }
                .padding()
                .background(.ultraThinMaterial)
                .overlay(Divider(), alignment: .top)
            }
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
            if !self.mode.isEditing {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if self.intention.isEmpty {
                        self.focusedField = .intention
                    }
                }
            }
        }
        .onDisappear {
            if !self.mode.isEditing {
                self.draftSaveTask?.cancel()
                if !self.isLoading, self.pendingSessionForReminder == nil {
                    self.sessionStore.clearDraft()
                }
            }
        }
    }

    // MARK: - Validation Methods

    private func handleDateChange(from oldDate: Date, to newDate: Date) {
        let normalizedDate = self.validator.normalizeSessionDate(newDate)
        if let message = validator.getDateNormalizationMessage(originalDate: newDate, normalizedDate: normalizedDate) {
            if abs(normalizedDate.timeIntervalSince(newDate)) > 60 {
                self.sessionDate = normalizedDate
            }

            self.dateNormalizationMessage = message
            self.showDateNormalizationHint = true

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(4))
                self.showDateNormalizationHint = false
            }
        }

        self.debounceValidation()
        self.scheduleDraftSave()
    }

    private func debounceValidation() {
        self.validationTask?.cancel()
        self.validationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self.performValidation()
        }
    }

    @MainActor private func performValidation() {
        self.intentionValidation = self.validator.validateIntention(self.intention)
        let normalizedDate = self.validator.normalizeSessionDate(self.sessionDate)
        self.dateValidation = self.validator.validateSessionDate(normalizedDate)
    }

    // MARK: - Lifecycle

    private func setupInitialState() {
        guard !self.mode.isEditing else { return }
        if let draft = self.sessionStore.recoverDraft() {
            self.applyDraft(draft)
            return
        }

        Task { @MainActor in
            self.performValidation()
        }
    }

    // MARK: - Actions

    private func cancel() {
        if !self.mode.isEditing {
            self.sessionStore.clearDraft()
        }
        self.dismiss()
    }

    private func saveSession() {
        guard self.isFormValid else {
            self.performValidation()
            return
        }

        let normalizedDate = self.validator.normalizeSessionDate(self.sessionDate)
        let trimmedIntention = self.intention.trimmingCharacters(in: .whitespacesAndNewlines)

        switch self.mode {
        case .create:
            self.isLoading = true
            let newSession = TherapeuticSession(
                sessionDate: normalizedDate,
                treatmentType: selectedTreatmentType,
                administration: self.selectedAdministration,
                intention: trimmedIntention,
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
                await MainActor.run {
                    self.isLoading = false
                }
            }

        case let .edit(session):
            session.sessionDate = normalizedDate
            session.treatmentType = self.selectedTreatmentType
            session.administration = self.selectedAdministration
            session.intention = trimmedIntention
            session.moodBefore = self.moodBefore
            session.moodAfter = self.moodAfter
            session.reflections = self.reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)

            do {
                try self.sessionStore.update(session)
                self.dismiss()
            } catch {
                self.showError(message: "Unable to update session: \(error.localizedDescription)")
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
        guard !self.mode.isEditing else { return }
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
            moodAfter: self.moodAfter
        )
    }

    private func handleReminderSelection(_ option: ReminderOption) {
        guard let session = self.pendingSessionForReminder else {
            self.dismiss()
            return
        }

        Task {
            do {
                try await self.sessionStore.setReminder(for: session, option: option)
            } catch {
                await MainActor.run {
                    self.showError(message: "Unable to schedule reminder: \(error.localizedDescription)")
                }
            }
            await MainActor.run {
                self.dismiss()
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: TherapeuticSession.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let store = SessionStore(modelContext: container.mainContext, owningContainer: container)

    return NavigationStack {
        SessionFormView()
            .environment(store)
    }
    .modelContainer(container)
}
