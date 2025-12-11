// swiftlint:disable file_length
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
    import UIKit
#endif

struct ContentView: View {
    @Query(sort: \TherapeuticSession.sessionDate, order: .reverse)
    private var allSessions: [TherapeuticSession]

    @Environment(SessionStore.self) private var sessionStore
    @EnvironmentObject private var notificationHandler: NotificationHandler

    @State private var showingSessionForm = false
    @State private var listViewModel = SessionListViewModel()

    @State private var selectedSessionID: UUID?
    @State private var navigationPath = NavigationPath()
    @State private var deepLinkAlert: (title: String, message: String)?

    @State private var sessionPendingDeletion: (session: TherapeuticSession, index: Int)?
    @State private var showingDeleteConfirmation = false

    @State private var showingExportSheet = false
    @State private var isExporting = false
    @State private var exportTask: Task<Void, Never>?
    @State private var exportDocument: BinaryFileDocument?
    @State private var exportContentType: UTType = .commaSeparatedText
    @State private var exportFilename: String = "Afterflow-Export"
    @State private var showingFileExporter = false
    @State private var exportError: String?
    @State private var showingImportPicker = false
    @State private var importError: String?
    @State private var pendingImportedSessions: [TherapeuticSession] = []
    @State private var showingImportConfirmation = false
    @State private var settingsError: String?
    @State private var debugNotificationScheduled = false

    var body: some View {
        self.navigationLayout
            .onChange(of: self.notificationHandler.pendingDeepLink) { _, deepLink in
                guard let deepLink else { return }
                self.handleDeepLink(deepLink)
            }
            .applyNavigationAlerts(
                deepLinkAlert: self.$deepLinkAlert,
                showingDeleteConfirmation: self.$showingDeleteConfirmation,
                sessionPendingDeletion: self.$sessionPendingDeletion,
                confirmDelete: self.confirmDelete
            )
            .applyExportFlows(
                ExportFlowConfig(
                    showingSessionForm: self.$showingSessionForm,
                    showingExportSheet: self.$showingExportSheet,
                    showingFileExporter: self.$showingFileExporter,
                    exportDocument: self.$exportDocument,
                    exportContentType: self.$exportContentType,
                    exportFilename: self.$exportFilename,
                    isExporting: self.$isExporting,
                    exportError: self.$exportError,
                    startExport: self.startExport(with:),
                    cancelExport: self.cancelExport
                )
            )
            .applyImportFlows(
                ImportFlowConfig(
                    showingImportPicker: self.$showingImportPicker,
                    importError: self.$importError,
                    showingImportConfirmation: self.$showingImportConfirmation,
                    pendingImportedSessions: self.$pendingImportedSessions,
                    confirmImport: self.confirmImport,
                    importCSV: { url in self.importCSV(from: url) }
                )
            )
            .applySettingsAlert(settingsError: self.$settingsError)
            .overlay(alignment: .top) { self.bannerOverlay }
    }

    private var filteredSessions: [TherapeuticSession] {
        self.listViewModel.applyFilters(to: self.allSessions)
    }

    private func deleteSessions(offsets: IndexSet) {
        guard let index = offsets.first else { return }
        let session = self.filteredSessions[index]
        self.sessionPendingDeletion = (session, index)
        self.showingDeleteConfirmation = true
    }

    private func confirmDelete() {
        guard let pending = sessionPendingDeletion else { return }
        try? self.sessionStore.delete(pending.session)
        self.sessionPendingDeletion = nil
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

    private func handleDeepLink(_ action: NotificationHandler.DeepLinkAction) {
        Task {
            do {
                try await self.notificationHandler.processDeepLink(action)

                if case let .openSession(sessionID) = action {
                    await MainActor.run {
                        self.selectedSessionID = sessionID
                        self.navigationPath = NavigationPath()
                        self.navigationPath.append(sessionID)
                        self.notificationHandler.clearPendingDeepLink()
                    }
                } else {
                    await MainActor.run {
                        self.notificationHandler.clearPendingDeepLink()
                    }
                }
            } catch {
                await MainActor.run {
                    self.deepLinkAlert = (
                        title: "Navigation Error",
                        message: error.localizedDescription
                    )
                    self.notificationHandler.clearPendingDeepLink()
                }
            }
        }
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

// MARK: - Subviews & Modifiers

private extension ContentView {
    var navigationLayout: some View {
        NavigationSplitView {
            SessionListSection(
                sessions: self.filteredSessions,
                listViewModel: self.$listViewModel,
                navigationPath: self.$navigationPath,
                sessionStore: self.sessionStore,
                onDelete: self.deleteSessions,
                onAdd: { self.showingSessionForm = true },
                onExport: { self.showingExportSheet = true },
                onImport: { self.showingImportPicker = true },
                onOpenSettings: { self.openAppSettings() },
                onExampleImport: { self.exportExampleImport() },
                onDebugNotification: { Task { await self.scheduleDebugNotification() } }
            )
        } detail: {
            if let sessionID = selectedSessionID,
               let session = allSessions.first(where: { $0.id == sessionID }) {
                SessionDetailView(session: session)
            } else {
                Text("Select a session")
                    .foregroundColor(.secondary)
            }
        }
    }

    var bannerOverlay: some View {
        VStack(spacing: 8) {
            #if DEBUG
                if self.debugNotificationScheduled {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.orange)
                        Text("Test notification scheduled (5 seconds)")
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            #endif

            if !self.notificationHandler.confirmations.recentConfirmations.isEmpty {
                ForEach(self.notificationHandler.confirmations.recentConfirmations, id: \.self) { message in
                    ReflectionConfirmationBanner(message: message)
                }
            }
        }
        .padding(.top, 8)
        .animation(.easeInOut(duration: 0.3), value: self.notificationHandler.confirmations.recentConfirmations)
        .animation(.easeInOut(duration: 0.3), value: self.debugNotificationScheduled)
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
    @Binding var navigationPath: NavigationPath
    let sessionStore: SessionStore
    let onDelete: (IndexSet) -> Void
    let onAdd: () -> Void
    let onExport: () -> Void
    let onImport: () -> Void
    let onOpenSettings: () -> Void
    let onExampleImport: () -> Void
    let onDebugNotification: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: self.$navigationPath) {
                List {
                    ForEach(Array(self.sessions.enumerated()), id: \.element.id) { index, session in
                        ZStack(alignment: .leading) {
                            SessionRowView(session: session, dateText: session.sessionDate.relativeSessionLabel)
                                .padding(.vertical, -4)
                                .accessibilityIdentifier("sessionRow-\(session.id.uuidString)")
                            NavigationLink(value: session.id) {
                                EmptyView()
                            }
                            .opacity(0)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                self.onDelete(IndexSet(integer: index))
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } preview: {
                            SessionDetailView(session: session)
                                .frame(width: 350, height: 600)
                                .environment(self.sessionStore)
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
                .navigationDestination(for: UUID.self) { sessionID in
                    if let session = self.sessions.first(where: { $0.id == sessionID }) {
                        SessionDetailView(session: session)
                            .environment(self.sessionStore)
                    }
                }
            }

            BottomControls(listViewModel: self.$listViewModel, onAdd: self.onAdd)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Button {
                    self.onOpenSettings()
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Button {
                    self.onExport()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                Button {
                    self.onImport()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                Menu {
                    Button {
                        self.onExampleImport()
                    } label: {
                        Label("Example Import", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Label("Help", systemImage: "questionmark.circle")
                }
                #if DEBUG
                    Divider()
                    Button {
                        self.onDebugNotification()
                    } label: {
                        Label("Test Notification (5s)", systemImage: "bell.badge")
                    }
                    .disabled(self.sessions.isEmpty)
                #endif
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .padding(.horizontal, 2)
            }
            .accessibilityLabel("More options")
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            FilterMenu(listViewModel: self.$listViewModel)
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
        HStack(alignment: .center, spacing: 12) {
            TreatmentAvatar(type: self.session.treatmentType)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(self.session.treatmentType.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 6) {
                        Text(self.dateText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
}

private struct TreatmentAvatar: View {
    let type: PsychedelicTreatmentType

    var body: some View {
        ZStack {
            Circle()
                .fill(self.backgroundColor)
            Text(self.initials)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 36, height: 36)
        .accessibilityIdentifier("treatmentAvatar")
    }

    private var backgroundColor: Color {
        switch self.type {
        case .ketamine: Color.cyan
        case .psilocybin: Color.purple
        case .lsd: Color.indigo
        case .mdma: Color.orange
        case .dmt: Color.teal
        case .ayahuasca: Color.brown
        case .mescaline: Color.green
        case .cannabis: Color.mint
        case .other: Color.gray
        }
    }

    private var initials: String {
        switch self.type {
        case .ketamine: "K"
        case .psilocybin: "P"
        case .lsd: "L"
        case .mdma: "MD"
        case .dmt: "D"
        case .ayahuasca: "A"
        case .mescaline: "ME"
        case .cannabis: "C"
        case .other: "O"
        }
    }
}

private extension ContentView {
    func scheduleDebugNotification() async {
        #if DEBUG
            guard let session = allSessions.first else { return }

            let scheduler = ReminderScheduler()
            do {
                _ = try await scheduler.scheduleImmediateTestNotification(for: session)
                self.debugNotificationScheduled = true

                try? await Task.sleep(for: .seconds(6))
                self.debugNotificationScheduled = false
            } catch {}
        #endif
    }

    func openAppSettings() {
        #if canImport(UIKit)
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                self.settingsError = "Unable to open Settings. Please open Settings > Afterflow manually."
                return
            }
            UIApplication.shared.open(url) { success in
                if !success {
                    self.settingsError = "Unable to open Settings. Please open Settings > Afterflow manually."
                }
            }
        #endif
    }

    func importCSV(from url: URL) {
        Task {
            let didStart = url.startAccessingSecurityScopedResource()
            defer { if didStart { url.stopAccessingSecurityScopedResource() } }

            do {
                try await self.downloadIfNeeded(url: url)
                let sessions = try CSVImportService().import(from: url)
                await MainActor.run {
                    self.pendingImportedSessions = sessions
                    self.showingImportConfirmation = !sessions.isEmpty
                }
            } catch {
                await MainActor.run {
                    self.importError = error.localizedDescription
                }
            }
        }
    }

    private func downloadIfNeeded(url: URL) async throws {
        let values = try url.resourceValues(forKeys: [.isUbiquitousItemKey])
        guard values.isUbiquitousItem == true else { return }

        try FileManager.default.startDownloadingUbiquitousItem(at: url)

        while true {
            let status = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
            if let downloadingStatus = status.ubiquitousItemDownloadingStatus,
               downloadingStatus == URLUbiquitousItemDownloadingStatus.current ||
               downloadingStatus == URLUbiquitousItemDownloadingStatus.downloaded {
                break
            }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    func confirmImport() {
        guard !self.pendingImportedSessions.isEmpty else { return }
        for session in self.pendingImportedSessions {
            try? self.sessionStore.create(session)
        }
        self.pendingImportedSessions = []
    }

    func exportExampleImport() {
        do {
            let url = try CSVExportService().exportExampleImport()
            let data = try Data(contentsOf: url)
            self.exportDocument = BinaryFileDocument(data: data, contentType: .commaSeparatedText)
            self.exportContentType = .commaSeparatedText
            self.exportFilename = "Afterflow-Example-Import"
            self.showingFileExporter = true
        } catch {
            self.exportError = error.localizedDescription
        }
    }
}

struct ExportFlowConfig {
    let showingSessionForm: Binding<Bool>
    let showingExportSheet: Binding<Bool>
    let showingFileExporter: Binding<Bool>
    let exportDocument: Binding<BinaryFileDocument?>
    let exportContentType: Binding<UTType>
    let exportFilename: Binding<String>
    let isExporting: Binding<Bool>
    let exportError: Binding<String?>
    let startExport: (ExportRequest) -> Void
    let cancelExport: () -> Void
}

struct ImportFlowConfig {
    let showingImportPicker: Binding<Bool>
    let importError: Binding<String?>
    let showingImportConfirmation: Binding<Bool>
    let pendingImportedSessions: Binding<[TherapeuticSession]>
    let confirmImport: () -> Void
    let importCSV: (URL) -> Void
}

private extension View {
    func applyNavigationAlerts(
        deepLinkAlert: Binding<(title: String, message: String)?>,
        showingDeleteConfirmation: Binding<Bool>,
        sessionPendingDeletion: Binding<(session: TherapeuticSession, index: Int)?>,
        confirmDelete: @escaping () -> Void
    ) -> some View {
        self
            .alert("Navigation Error", isPresented: Binding(
                get: { deepLinkAlert.wrappedValue != nil },
                set: { if !$0 { deepLinkAlert.wrappedValue = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deepLinkAlert.wrappedValue?.message ?? "")
            }
            .alert("Delete Session", isPresented: showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
                .accessibilityIdentifier("confirmDeleteButton")
                Button("Cancel", role: .cancel) {
                    sessionPendingDeletion.wrappedValue = nil
                }
                .accessibilityIdentifier("cancelDeleteButton")
            } message: {
                if let pending = sessionPendingDeletion.wrappedValue {
                    let treatmentName = pending.session.treatmentType.displayName
                    let sessionDateFormatted = pending.session.sessionDate.formatted(date: .abbreviated, time: .omitted)
                    Text(
                        "Are you sure you want to delete this \(treatmentName) session from \(sessionDateFormatted)? " +
                            "This action cannot be undone."
                    )
                }
            }
    }

    func applyExportFlows(_ config: ExportFlowConfig) -> some View {
        self
            .sheet(isPresented: config.showingSessionForm) {
                NavigationStack { SessionFormView() }
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(16)
                    .toolbarBackground(.visible, for: .automatic)
            }
            .sheet(isPresented: config.showingExportSheet) {
                ExportSheetView(
                    availableTreatmentTypes: PsychedelicTreatmentType.allCases,
                    onCancel: { config.showingExportSheet.wrappedValue = false },
                    onExport: { request in
                        config.showingExportSheet.wrappedValue = false
                        config.startExport(request)
                    }
                )
            }
            .fileExporter(
                isPresented: config.showingFileExporter,
                document: config.exportDocument.wrappedValue,
                contentType: config.exportContentType.wrappedValue,
                defaultFilename: config.exportFilename.wrappedValue
            ) { result in
                config.isExporting.wrappedValue = false
                if case let .failure(error) = result {
                    config.exportError.wrappedValue = error.localizedDescription
                }
                config.exportDocument.wrappedValue = nil
            }
            .alert("Export Error", isPresented: Binding(
                get: { config.exportError.wrappedValue != nil },
                set: { if !$0 { config.exportError.wrappedValue = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(config.exportError.wrappedValue ?? "")
            }
            .overlay { ExportOverlay(isExporting: config.isExporting.wrappedValue) { config.cancelExport() } }
    }

    func applyImportFlows(_ config: ImportFlowConfig) -> some View {
        self
            .alert("Import Error", isPresented: Binding(
                get: { config.importError.wrappedValue != nil },
                set: { if !$0 { config.importError.wrappedValue = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(config.importError.wrappedValue ?? "")
            }
            .fileImporter(
                isPresented: config.showingImportPicker,
                allowedContentTypes: [.commaSeparatedText]
            ) { result in
                do {
                    let url = try result.get()
                    config.importCSV(url)
                } catch {
                    config.importError.wrappedValue = error.localizedDescription
                }
            }
            .alert("Import Sessions", isPresented: config.showingImportConfirmation) {
                Button("Import \(config.pendingImportedSessions.wrappedValue.count) Sessions") {
                    config.confirmImport()
                }
                Button("Cancel", role: .cancel) {
                    config.pendingImportedSessions.wrappedValue = []
                }
            } message: {
                Text("Import \(config.pendingImportedSessions.wrappedValue.count) session(s) from the selected CSV?")
            }
    }

    func applySettingsAlert(settingsError: Binding<String?>) -> some View {
        self.alert("Settings", isPresented: Binding(
            get: { settingsError.wrappedValue != nil },
            set: { if !$0 { settingsError.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(settingsError.wrappedValue ?? "")
        }
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

private struct ReflectionConfirmationBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .accessibilityHidden(true)

            Text(self.message)
                .font(.footnote)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Success: \(self.message)")
        .accessibilityAddTraits(.isStaticText)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    let preview = makePreviewContainerAndStore()
    ContentView()
        .modelContainer(preview.container)
        .environment(preview.store)
        .environmentObject(NotificationHandler(modelContext: preview.container.mainContext, skipQueueReplay: true))
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
