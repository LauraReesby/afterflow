import SwiftData
import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif

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

    @State private var sessionDate: Date
    @State private var selectedTreatmentType: PsychedelicTreatmentType
    @State private var selectedAdministration: AdministrationMethod
    @State private var intention: String
    @State private var moodBefore: Int
    @State private var moodAfter: Int
    @State private var reflectionText: String
    @State private var musicLinkInput: String
    @State private var musicLinkMetadata: MusicLinkMetadata?
    @State private var isFetchingMusicLink = false
    @State private var musicLinkError: String?
    @State private var didClearMusicLink = false
    @State private var pendingMetadataRequest: UUID?
    @State private var metadataFetchTask: Task<Void, Never>?

    @FocusState private var focusedField: FormField?

    enum FormField: CaseIterable {
        case intention
        case reflection
    }

    @State private var validator = FormValidation()
    @State private var intentionValidation: FieldValidationState?
    @State private var dateValidation: FieldValidationState?
    @State private var validationTask: Task<Void, Never>?
    @State private var draftSaveTask: Task<Void, Never>?

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDateNormalizationHint = false
    @State private var dateNormalizationMessage = ""
    @State private var showReminderPrompt = false
    @State private var pendingSessionForReminder: TherapeuticSession?
    private let metadataService = MusicLinkMetadataService()

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
            _musicLinkInput = State(initialValue: session.musicLinkWebURL ?? session.musicLinkURL ?? "")
            _musicLinkMetadata = State(initialValue: SessionFormView.metadata(from: session))
            _isFetchingMusicLink = State(initialValue: false)
            _musicLinkError = State(initialValue: nil)
            _didClearMusicLink = State(initialValue: false)
            _pendingMetadataRequest = State(initialValue: nil)
        } else {
            self.mode = .create
            _sessionDate = State(initialValue: Date())
            _selectedTreatmentType = State(initialValue: .ketamine)
            _selectedAdministration = State(initialValue: .intravenous)
            _intention = State(initialValue: "")
            _moodBefore = State(initialValue: 5)
            _moodAfter = State(initialValue: 5)
            _reflectionText = State(initialValue: "")
            _musicLinkInput = State(initialValue: "")
            _musicLinkMetadata = State(initialValue: nil)
            _isFetchingMusicLink = State(initialValue: false)
            _musicLinkError = State(initialValue: nil)
            _didClearMusicLink = State(initialValue: false)
            _pendingMetadataRequest = State(initialValue: nil)
        }
    }

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

    private var editingSession: TherapeuticSession? { self.mode.session }

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
                RichTextEditor(
                    text: self.$reflectionText,
                    isFocused: Binding(
                        get: { self.focusedField == .reflection },
                        set: { if $0 { self.focusedField = .reflection } else if self.focusedField == .reflection { self.focusedField = nil } }
                    ),
                    accessibilityIdentifier: "reflectionEditor"
                )

                Text("Use formatting to emphasize key insights or organize your thoughts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

    var body: some View {
        List {
            FormStatusBanner(
                statusTitle: statusTitle,
                statusSubtitle: statusSubtitle
            )

            FormDateSection(
                sessionDate: $sessionDate,
                dateValidation: dateValidation,
                showNormalizationHint: showDateNormalizationHint,
                normalizationMessage: dateNormalizationMessage,
                onDateChange: handleDateChange
            )

            FormTreatmentSection(
                treatmentType: $selectedTreatmentType,
                administration: $selectedAdministration,
                onTreatmentChange: scheduleDraftSave,
                onAdministrationChange: scheduleDraftSave
            )

            FormIntentionSection(
                intention: $intention,
                focusedField: $focusedField,
                validation: intentionValidation,
                isFormValid: isFormValid,
                onSubmit: saveSession,
                onChange: {
                    debounceValidation()
                    scheduleDraftSave()
                }
            )

            self.moodSection

            FormMusicSection(
                musicLinkInput: $musicLinkInput,
                isFetching: isFetchingMusicLink,
                error: musicLinkError,
                metadata: musicLinkMetadata,
                shouldShowHelper: shouldShowMusicLinkHelper,
                hasAnyLink: hasAnyMusicLink,
                editingSession: editingSession,
                hasExistingLink: hasExistingSessionMusicLink,
                trimmedInput: trimmedMusicLinkInput,
                onInputChange: handleMusicLinkInputChange,
                onPasteFromClipboard: pasteMusicLinkFromClipboard,
                onRemoveLink: removeMusicLink
            )

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
        .scrollDismissesKeyboard(.immediately)
        .alert("Error", isPresented: self.$showError) {
            Button("OK") {}
        } message: {
            Text(self.errorMessage)
        }
        .alert(
            "Would you like a reminder to add reflections later?",
            isPresented: self.$showReminderPrompt
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
}

extension SessionFormView {
    private var trimmedMusicLinkInput: String {
        self.musicLinkInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasExistingSessionMusicLink: Bool {
        guard let session = self.editingSession else { return false }
        return session.hasMusicLink && !self.didClearMusicLink && self.musicLinkMetadata == nil
    }

    private var hasAnyMusicLink: Bool {
        self.musicLinkMetadata != nil || self.hasExistingSessionMusicLink || !self.trimmedMusicLinkInput.isEmpty
    }

    private var shouldShowMusicLinkHelper: Bool {
        self.trimmedMusicLinkInput.isEmpty && self.musicLinkMetadata == nil && !self.hasExistingSessionMusicLink
    }

    private func removeMusicLink() {
        self.musicLinkInput = ""
        self.musicLinkMetadata = nil
        self.didClearMusicLink = true
        self.musicLinkError = nil
        self.isFetchingMusicLink = false
        self.pendingMetadataRequest = nil
        self.metadataFetchTask?.cancel()
    }

    private func pasteMusicLinkFromClipboard() {
        #if canImport(UIKit)
            if let clipboard = UIPasteboard.general.string?
                .trimmingCharacters(in: .whitespacesAndNewlines),
                !clipboard.isEmpty {
                self.musicLinkInput = clipboard
            } else {
                self.musicLinkError = "Clipboard is empty."
            }
        #endif
    }

    private func handleMusicLinkInputChange() {
        let trimmed = self.trimmedMusicLinkInput
        self.metadataFetchTask?.cancel()
        if trimmed.isEmpty {
            self.isFetchingMusicLink = false
            self.musicLinkMetadata = nil
            self.musicLinkError = nil
            self.pendingMetadataRequest = nil
            return
        }

        self.isFetchingMusicLink = true
        self.musicLinkError = nil
        let requestID = UUID()
        self.pendingMetadataRequest = requestID

        self.metadataFetchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            do {
                let metadata = try await self.metadataService.fetchMetadata(for: trimmed)
                try Task.checkCancellation()
                await MainActor.run {
                    guard self.pendingMetadataRequest == requestID else { return }
                    self.musicLinkMetadata = metadata
                    self.didClearMusicLink = false
                    self.isFetchingMusicLink = false
                    self.persistFetchedMetadata(metadata)
                }
            } catch is CancellationError {
                return
            } catch {
                await MainActor.run {
                    guard self.pendingMetadataRequest == requestID else { return }
                    self.musicLinkError = "Couldn’t attach link. Please check the URL."
                    self.musicLinkMetadata = nil
                    self.isFetchingMusicLink = false
                }
            }
        }
    }

    private func applyMusicLink(to session: TherapeuticSession) {
        if self.didClearMusicLink {
            session.clearMusicLinkData()
            return
        }
        if let metadata = self.musicLinkMetadata {
            self.assign(metadata, to: session)
            return
        }
        let trimmed = self.trimmedMusicLinkInput
        guard !trimmed.isEmpty else { return }

        if let classification = self.metadataService.classify(urlString: trimmed) {
            session.musicLinkURL = classification.originalURL.absoluteString
            session.musicLinkWebURL = classification.canonicalURL.absoluteString
            session.musicLinkTitle = nil
            session.musicLinkAuthorName = nil
            session.musicLinkArtworkURL = nil
            session.musicLinkProvider = classification.provider
        } else {
            session.musicLinkURL = trimmed
            session.musicLinkWebURL = trimmed
            session.musicLinkTitle = nil
            session.musicLinkAuthorName = nil
            session.musicLinkArtworkURL = nil
            session.musicLinkProvider = .unknown
        }
    }

    private func assign(_ metadata: MusicLinkMetadata, to session: TherapeuticSession) {
        session.musicLinkURL = metadata.originalURL.absoluteString
        session.musicLinkWebURL = metadata.canonicalURL.absoluteString
        session.musicLinkTitle = metadata.title
        session.musicLinkAuthorName = metadata.authorName
        session.musicLinkArtworkURL = metadata.thumbnailURL?.absoluteString
        session.musicLinkDurationSeconds = metadata.durationSeconds
        session.musicLinkProvider = metadata.provider
    }

    private func persistFetchedMetadata(_ metadata: MusicLinkMetadata) {
        guard case let .edit(session) = self.mode else { return }
        self.assign(metadata, to: session)
        do {
            try self.sessionStore.update(session)
        } catch {
            // If persistence fails, keep in-memory state; user can retry saving.
        }
    }

    static func metadata(from session: TherapeuticSession) -> MusicLinkMetadata? {
        guard session.hasMusicLink else { return nil }
        guard let originalString = session.musicLinkURL ?? session.musicLinkWebURL,
              let canonicalString = session.musicLinkWebURL ?? session.musicLinkURL,
              let original = URL(string: originalString),
              let canonical = URL(string: canonicalString)
        else { return nil }
        return MusicLinkMetadata(
            provider: session.musicLinkProvider,
            originalURL: original,
            canonicalURL: canonical,
            title: session.musicLinkTitle,
            authorName: session.musicLinkAuthorName,
            thumbnailURL: session.musicLinkArtworkURL.flatMap(URL.init(string:)),
            durationSeconds: session.musicLinkDurationSeconds
        )
    }
}

private extension SessionFormView {
    func handleDateChange(from oldDate: Date, to newDate: Date) {
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

    func debounceValidation() {
        self.validationTask?.cancel()
        self.validationTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            self.performValidation()
        }
    }

    @MainActor func performValidation() {
        self.intentionValidation = self.validator.validateIntention(self.intention)
        let normalizedDate = self.validator.normalizeSessionDate(self.sessionDate)
        self.dateValidation = self.validator.validateSessionDate(normalizedDate)
    }

    func setupInitialState() {
        guard !self.mode.isEditing else { return }
        if let draft = self.sessionStore.recoverDraft() {
            self.applyDraft(draft)
            return
        }

        Task { @MainActor in
            self.performValidation()
        }
    }

    func cancel() {
        if !self.mode.isEditing {
            self.sessionStore.clearDraft()
        }
        self.dismiss()
    }

    func saveSession() {
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
            self.applyMusicLink(to: newSession)

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
            self.applyMusicLink(to: session)

            do {
                try self.sessionStore.update(session)
                self.dismiss()
            } catch {
                self.showError(message: "Unable to update session: \(error.localizedDescription)")
            }
        }
    }

    func showError(message: String) {
        self.errorMessage = message
        self.showError = true
    }

    func applyDraft(_ draft: TherapeuticSession) {
        self.sessionDate = draft.sessionDate
        self.selectedTreatmentType = draft.treatmentType
        self.selectedAdministration = draft.administration
        self.intention = draft.intention
        self.moodBefore = draft.moodBefore
        self.moodAfter = draft.moodAfter
        self.musicLinkInput = draft.musicLinkWebURL ?? draft.musicLinkURL ?? ""
        self.musicLinkMetadata = SessionFormView.metadata(from: draft)
        self.musicLinkError = nil
        self.didClearMusicLink = false
        self.isFetchingMusicLink = false
        self.pendingMetadataRequest = nil
    }

    func scheduleDraftSave() {
        guard !self.mode.isEditing else { return }
        self.draftSaveTask?.cancel()
        let snapshot = self.buildDraftSnapshot()
        self.draftSaveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            self.sessionStore.saveDraft(snapshot)
        }
    }

    func buildDraftSnapshot() -> TherapeuticSession {
        let normalizedDate = self.validator.normalizeSessionDate(self.sessionDate)
        let draft = TherapeuticSession(
            sessionDate: normalizedDate,
            treatmentType: self.selectedTreatmentType,
            administration: self.selectedAdministration,
            intention: self.intention,
            moodBefore: self.moodBefore,
            moodAfter: self.moodAfter
        )
        self.applyMusicLink(to: draft)
        return draft
    }

    func handleReminderSelection(_ option: ReminderOption) {
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

private struct FormStatusBanner: View {
    let statusTitle: String
    let statusSubtitle: String

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text(statusTitle)
                    .font(.headline)
                Text(statusSubtitle)
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
        .accessibilityElement(children: .contain)
        .listRowBackground(Color.clear)
        .listRowInsets(.init(top: 8, leading: 0, bottom: 0, trailing: 0))
    }
}

private struct FormDateSection: View {
    @Binding var sessionDate: Date
    let dateValidation: FieldValidationState?
    let showNormalizationHint: Bool
    let normalizationMessage: String
    let onDateChange: (Date, Date) -> Void

    var body: some View {
        Section("When is this session?") {
            DatePicker(
                "Date & Time",
                selection: $sessionDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .onChange(of: sessionDate) { oldValue, newValue in
                onDateChange(oldValue, newValue)
            }
            .inlineValidation(dateValidation)

            if showNormalizationHint, !normalizationMessage.isEmpty {
                Text(normalizationMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct FormTreatmentSection: View {
    @Binding var treatmentType: PsychedelicTreatmentType
    @Binding var administration: AdministrationMethod
    let onTreatmentChange: () -> Void
    let onAdministrationChange: () -> Void

    var body: some View {
        Section("Treatment") {
            Picker("Treatment Type", selection: $treatmentType) {
                ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: treatmentType) { _, _ in
                onTreatmentChange()
            }

            Picker("Administration", selection: $administration) {
                ForEach(AdministrationMethod.allCases, id: \.self) { method in
                    Text(method.displayName).tag(method)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: administration) { _, _ in
                onAdministrationChange()
            }
        }
        .accessibilityElement(children: .contain)
    }
}

private struct FormIntentionSection: View {
    @Binding var intention: String
    @FocusState.Binding var focusedField: SessionFormView.FormField?
    let validation: FieldValidationState?
    let isFormValid: Bool
    let onSubmit: () -> Void
    let onChange: () -> Void

    var body: some View {
        Section("Intention") {
            TextField(
                "What do you hope to explore or heal?",
                text: $intention,
                axis: .vertical
            )
            .lineLimit(3 ... 6)
            .focused($focusedField, equals: .intention)
            .submitLabel(.done)
            .textInputAutocapitalization(.sentences)
            .onSubmit {
                if isFormValid {
                    onSubmit()
                }
            }
            .onChange(of: intention) { _, _ in
                onChange()
            }
            .inlineValidation(validation)
            .accessibilityIdentifier("intentionField")
        }
        .accessibilityElement(children: .contain)
    }
}

private struct FormMusicSection: View {
    @Binding var musicLinkInput: String
    let isFetching: Bool
    let error: String?
    let metadata: MusicLinkMetadata?
    let shouldShowHelper: Bool
    let hasAnyLink: Bool
    let editingSession: TherapeuticSession?
    let hasExistingLink: Bool
    let trimmedInput: String
    let onInputChange: () -> Void
    let onPasteFromClipboard: () -> Void
    let onRemoveLink: () -> Void

    var body: some View {
        Section("Music") {
            VStack(alignment: .leading, spacing: 8) {
                if shouldShowHelper {
                    Text("Paste a link from Spotify, YouTube, or SoundCloud.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    #if canImport(UIKit)
                        Button {
                            onPasteFromClipboard()
                        } label: {
                            Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                        }
                        .buttonStyle(.bordered)
                    #endif
                }

                HStack(alignment: .center, spacing: 8) {
                    TextField(
                        "Playlist URL",
                        text: $musicLinkInput
                    )
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
                    .accessibilityIdentifier("musicLinkField")
                    .onChange(of: musicLinkInput) { _, _ in
                        onInputChange()
                    }

                    if isFetching {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if let metadata {
                    MusicLinkMetadataPreview(metadata: metadata)
                } else if hasExistingLink, let session = editingSession {
                    MusicLinkSummaryCard(session: session)
                } else if !trimmedInput.isEmpty {
                    MusicLinkRawPreview(urlString: trimmedInput)
                }

                if hasAnyLink {
                    Button("Remove link", role: .destructive) {
                        onRemoveLink()
                    }
                    .accessibilityIdentifier("removeMusicLinkButton")
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview {
    let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: TherapeuticSession.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
    let store = SessionStore(modelContext: container.mainContext, owningContainer: container)

    return NavigationStack {
        SessionFormView()
            .environment(store)
    }
    .modelContainer(container)
}
