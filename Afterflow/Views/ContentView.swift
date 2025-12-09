import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Query(sort: \TherapeuticSession.sessionDate, order: .reverse)
    private var allSessions: [TherapeuticSession]

    @Environment(SessionStore.self) private var sessionStore

    // UI State
    @State private var showingSessionForm = false
    @State private var listViewModel = SessionListViewModel()

    // Undo State
    @State private var recentlyDeleted: (session: TherapeuticSession, index: Int)?
    @State private var showUndoBanner = false
    @State private var undoTask: Task<Void, Never>?

    // Export State
    @State private var showingExportSheet = false
    @State private var isExporting = false
    @State private var exportTask: Task<Void, Never>?
    @State private var exportDocument: BinaryFileDocument?
    @State private var exportContentType: UTType = .commaSeparatedText
    @State private var exportFilename: String = "Afterflow-Export"
    @State private var showingFileExporter = false
    @State private var exportError: String?

    var body: some View {
        NavigationSplitView {
            SessionListSection(
                sessions: self.filteredSessions,
                listViewModel: self.$listViewModel,
                onDelete: self.deleteSessions,
                onAdd: { self.showingSessionForm = true },
                onExport: { self.showingExportSheet = true }
            )
        } detail: {
            Text("Select a session")
        }
        // Add Session Sheet
        .sheet(isPresented: self.$showingSessionForm) {
            NavigationStack { SessionFormView() }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
                .toolbarBackground(.visible, for: .automatic)
        }
        // Export Options Sheet
        .sheet(isPresented: self.$showingExportSheet) {
            ExportSheetView(
                availableTreatmentTypes: PsychedelicTreatmentType.allCases,
                onCancel: { self.showingExportSheet = false },
                onExport: { request in
                    self.showingExportSheet = false
                    self.startExport(with: request)
                }
            )
        }
        // File Exporter
        .fileExporter(
            isPresented: self.$showingFileExporter,
            document: self.exportDocument,
            contentType: self.exportContentType,
            defaultFilename: self.exportFilename
        ) { result in
            self.isExporting = false
            self.exportTask = nil
            if case let .failure(error) = result {
                self.exportError = error.localizedDescription
            }
            self.exportDocument = nil
        }
        // Export Error Alert
        .alert("Export Error", isPresented: Binding(
            get: { self.exportError != nil },
            set: { if !$0 { self.exportError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(self.exportError ?? "")
        }
        // Export Overlay
        .overlay { ExportOverlay(isExporting: self.isExporting) { self.cancelExport() } }
    }

    private var filteredSessions: [TherapeuticSession] {
        self.listViewModel.applyFilters(to: self.allSessions)
    }

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            guard let index = offsets.first else { return }
            let session = self.filteredSessions[index]
            let snapshot = clone(session)
            try? self.sessionStore.delete(session)
            self.scheduleUndo(for: snapshot, originalIndex: index)
        }
    }

    private func scheduleUndo(for session: TherapeuticSession, originalIndex: Int) {
        self.undoTask?.cancel()
        self.recentlyDeleted = (session, originalIndex)
        self.showUndoBanner = true

        self.undoTask = Task {
            do {
                try await Task.sleep(for: .seconds(10))
                try Task.checkCancellation()
                await MainActor.run { self.finalizeDeletion() }
            } catch {
                // Cancelled or failed sleep; do nothing so user can still undo if needed
            }
        }
    }

    private func undoDelete() {
        guard let deleted = recentlyDeleted else { return }
        do {
            try self.sessionStore.create(deleted.session)
            self.recentlyDeleted = nil
            self.showUndoBanner = false
        } catch {
            // keep banner visible so user can try again
        }
        self.undoTask?.cancel()
        self.undoTask = nil
    }

    private func finalizeDeletion() {
        self.recentlyDeleted = nil
        self.showUndoBanner = false
        self.undoTask = nil
    }

    private func startExport(with request: ExportRequest) {
        self.isExporting = true
        self.exportError = nil
        self.exportTask?.cancel()

        let sessions = self.allSessions
        self.exportTask = Task {
            do {
                let result = try await performExport(for: sessions, request: request)
                if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                }
                await MainActor.run {
                    self.exportDocument = BinaryFileDocument(data: result.data, contentType: result.type)
                    self.exportContentType = result.type
                    self.exportFilename = result.filename
                    self.isExporting = false
                    self.showingFileExporter = true
                }
            } catch {
                await MainActor.run {
                    self.exportError = error.localizedDescription
                    self.isExporting = false
                }
            }
        }
    }

    private func cancelExport() {
        self.exportTask?.cancel()
        self.isExporting = false
    }

    private func performExport(
        for sessions: [TherapeuticSession],
        request: ExportRequest
    ) async throws -> ExportResult {
        try Task.checkCancellation()
        switch request.format {
        case .csv:
            let url = try CSVExportService().export(
                sessions: sessions,
                dateRange: request.dateRange,
                treatmentType: request.treatmentType
            )
            let data = try Data(contentsOf: url)
            try? FileManager.default.removeItem(at: url)
            try Task.checkCancellation()
            return ExportResult(data: data, type: .commaSeparatedText, filename: "Afterflow-Export")

        case .pdf:
            let url = try PDFExportService().export(
                sessions: sessions,
                dateRange: request.dateRange,
                treatmentType: request.treatmentType,
                options: .init(includeCoverPage: true, showPrivacyNote: true)
            )
            let data = try Data(contentsOf: url)
            try? FileManager.default.removeItem(at: url)
            try Task.checkCancellation()
            return ExportResult(data: data, type: .pdf, filename: "Afterflow-Export")
        }
    }
}

private struct ExportResult {
    let data: Data
    let type: UTType
    let filename: String
}

private struct SessionListSection: View {
    let sessions: [TherapeuticSession]
    @Binding var listViewModel: SessionListViewModel
    let onDelete: (IndexSet) -> Void
    let onAdd: () -> Void
    let onExport: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                ForEach(Array(self.sessions.enumerated()), id: \.element.id) { index, session in
                    ZStack(alignment: .leading) {
                        SessionRowView(session: session, dateText: session.sessionDate.relativeSessionLabel)
                            .accessibilityIdentifier("sessionRow-\(session.id.uuidString)")
                        NavigationLink(destination: SessionDetailView(session: session)) {
                            EmptyView()
                        }
                        .opacity(0.01)
                        .buttonStyle(.plain)
                        .accessibilityHidden(true)
                    }
                    .listRowSeparator(index == 0 ? .hidden : .visible, edges: .top)
                    .listRowSeparator(.visible, edges: .bottom)
                }
                .onDelete(perform: self.onDelete)
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listSectionSeparator(.hidden)
            .toolbar { self.toolbarContent }
            .navigationTitle("Sessions")
            .listStyle(.plain)
            .toolbarBackground(.visible, for: .automatic)
            .scrollDismissesKeyboard(.immediately)

            BottomControls(listViewModel: self.$listViewModel, onAdd: self.onAdd)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) { FilterMenu(listViewModel: self.$listViewModel) }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: self.onExport) {
                Label("Export", systemImage: "square.and.arrow.up")
                    .glassCapsule(cornerRadius: 18)
            }
            .accessibilityIdentifier("exportSessionsButton")
            .accessibilityLabel("Export Sessions")
        }
    }
}

private struct BottomControls: View {
    @Binding var listViewModel: SessionListViewModel
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                SearchField(text: self.$listViewModel.searchText)
                Button(action: self.onAdd) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.accentColor, in: Circle())
                }
                .accessibilityIdentifier("addSessionButton")
                .accessibilityLabel("Add Session")
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 2)
        .padding(.horizontal, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color(.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search", text: self.$text)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
            if !self.text.isEmpty {
                Button {
                    self.text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
        )
    }
}

private struct FilterMenu: View {
    @Binding var listViewModel: SessionListViewModel

    var body: some View {
        Menu {
            Picker("Sort", selection: self.$listViewModel.sortOption) {
                ForEach(SessionListViewModel.SortOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }

            Menu("Type") {
                Button("All Treatments") { self.listViewModel.treatmentFilter = nil }
                ForEach(PsychedelicTreatmentType.allCases, id: \.self) { type in
                    Button(type.displayName) { self.listViewModel.treatmentFilter = type }
                }
            }
        } label: {
            Label("Filters", systemImage: "line.3.horizontal.decrease")
                .glassCapsule(cornerRadius: 18)
        }
        .accessibilityLabel("Filter Sessions")
        .accessibilityHint("Change sort order or filter by treatment type")
    }
}

private struct ExportOverlay: View {
    let isExporting: Bool
    let onCancel: () -> Void

    var body: some View {
        Group {
            if self.isExporting {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView("Preparing export…")
                            .accessibilityIdentifier("exportProgressView")
                            .accessibilityLabel("Preparing export")
                        Button("Cancel", action: self.onCancel)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}

private struct SessionRowView: View {
    let session: TherapeuticSession
    let dateText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(self.session.treatmentType.displayName)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text(self.dateText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
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

private extension ContentView {
    func clone(_ session: TherapeuticSession) -> TherapeuticSession {
        let copy = TherapeuticSession(
            sessionDate: session.sessionDate,
            treatmentType: session.treatmentType,
            administration: session.administration,
            intention: session.intention,
            moodBefore: session.moodBefore,
            moodAfter: session.moodAfter,
            reflections: session.reflections,
            reminderDate: session.reminderDate
        )
        copy.id = session.id
        copy.createdAt = session.createdAt
        copy.updatedAt = session.updatedAt
        copy.musicLinkURL = session.musicLinkURL
        copy.musicLinkWebURL = session.musicLinkWebURL
        copy.musicLinkTitle = session.musicLinkTitle
        copy.musicLinkAuthorName = session.musicLinkAuthorName
        copy.musicLinkArtworkURL = session.musicLinkArtworkURL
        copy.musicLinkDurationSeconds = session.musicLinkDurationSeconds
        copy.musicLinkProvider = session.musicLinkProvider
        return copy
    }
}

private extension View {
    func glassCapsule(cornerRadius: CGFloat = 18) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
            )
    }
}

#Preview {
    let preview = makePreviewContainerAndStore()
    ContentView()
        .modelContainer(preview.container)
        .environment(preview.store)
}

private func makePreviewContainerAndStore() -> (container: ModelContainer, store: SessionStore) {
    do {
        let container = try ModelContainer(
            for: TherapeuticSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let store = SessionStore(modelContext: container.mainContext, owningContainer: container)
        SeedDataFactory.makeSeedSessions().forEach { try? store.create($0) }
        return (container, store)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}
