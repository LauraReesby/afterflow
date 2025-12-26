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

    @State private var exportState = ExportState()
    @State private var importState: ImportState?

    @State private var settingsError: String?
    @State private var deleteError: String?
    @State private var debugNotificationScheduled = false

    var body: some View {
        self.navigationLayout
            .onChange(of: self.notificationHandler.pendingDeepLink) { _, deepLink in
                guard let deepLink else { return }
                self.handleDeepLink(deepLink)
            }
            .onAppear {
                if self.importState == nil {
                    self.importState = ImportState(sessionStore: self.sessionStore)
                }
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
                    showingExportSheet: self.$exportState.showingExportSheet,
                    showingFileExporter: self.$exportState.showingFileExporter,
                    exportDocument: self.$exportState.exportDocument,
                    exportContentType: self.$exportState.exportContentType,
                    exportFilename: self.$exportState.exportFilename,
                    isExporting: self.$exportState.isExporting,
                    exportError: self.$exportState.exportError,
                    startExport: { request in self.exportState.startExport(sessions: self.allSessions, with: request) },
                    cancelExport: self.exportState.cancelExport
                )
            )
            .applyImportFlows(
                self.importFlowConfig
            )
            .applySettingsAlert(settingsError: self.$settingsError)
            .errorAlert(title: "Delete Failed", error: self.$deleteError)
            .overlay(alignment: .top) { self.bannerOverlay }
    }

    private var importFlowConfig: ImportFlowConfig {
        guard let importState = self.importState else {
            return ImportFlowConfig(
                showingImportPicker: .constant(false),
                importError: .constant(nil),
                showingImportConfirmation: .constant(false),
                pendingImportedSessions: .constant([]),
                confirmImport: {},
                importCSV: { _ in }
            )
        }

        return ImportFlowConfig(
            showingImportPicker: Binding(
                get: { importState.showingImportPicker },
                set: { importState.showingImportPicker = $0 }
            ),
            importError: Binding(
                get: { importState.importError },
                set: { importState.importError = $0 }
            ),
            showingImportConfirmation: Binding(
                get: { importState.showingImportConfirmation },
                set: { importState.showingImportConfirmation = $0 }
            ),
            pendingImportedSessions: Binding(
                get: { importState.pendingImportedSessions },
                set: { importState.pendingImportedSessions = $0 }
            ),
            confirmImport: { importState.confirmImport() },
            importCSV: { url in importState.importCSV(from: url) }
        )
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
        do {
            try self.sessionStore.delete(pending.session)
            self.sessionPendingDeletion = nil
        } catch {
            self.deleteError = "Failed to delete session: \(error.localizedDescription)"
        }
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
}

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
                onExport: { self.exportState.showingExportSheet = true },
                onImport: { self.importState?.showingImportPicker = true },
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
        VStack(spacing: DesignConstants.Spacing.small) {
            #if DEBUG
                if self.debugNotificationScheduled {
                    HStack(spacing: DesignConstants.Spacing.small) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.orange)
                        Text("Test notification scheduled (5 seconds)")
                            .font(.footnote)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, DesignConstants.Spacing.large)
                    .padding(.vertical, DesignConstants.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.medium, style: .continuous)
                            .fill(.regularMaterial)
                            .shadow(color: .black.opacity(DesignConstants.Shadow.standardOpacity), radius: DesignConstants.Shadow.standardRadius, x: DesignConstants.Shadow.standardX, y: DesignConstants.Shadow.standardY)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.medium, style: .continuous)
                            .strokeBorder(Color.orange.opacity(DesignConstants.Opacity.light + 0.05), lineWidth: 1)
                    )
                    .padding(.horizontal, DesignConstants.Spacing.large)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            #endif

            if !self.notificationHandler.confirmations.recentConfirmations.isEmpty {
                ForEach(self.notificationHandler.confirmations.recentConfirmations, id: \.self) { message in
                    ReflectionConfirmationBanner(message: message)
                }
            }
        }
        .padding(.top, DesignConstants.Spacing.small)
        .animation(.easeInOut(duration: DesignConstants.Animation.standardDuration), value: self.notificationHandler.confirmations.recentConfirmations)
        .animation(.easeInOut(duration: DesignConstants.Animation.standardDuration), value: self.debugNotificationScheduled)
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

                // Acceptable to ignore sleep error - cleanup/UI timing only
                try? await Task.sleep(for: .seconds(6))
                self.debugNotificationScheduled = false
            } catch {
                // Silent failure acceptable for debug-only feature
            }
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

    func exportExampleImport() {
        do {
            let url = try CSVExportService().exportExampleImport()
            let data = try Data(contentsOf: url)
            self.exportState.exportDocument = BinaryFileDocument(data: data, contentType: .commaSeparatedText)
            self.exportState.exportContentType = .commaSeparatedText
            self.exportState.exportFilename = "Afterflow-Example-Import"
            self.exportState.showingFileExporter = true
        } catch {
            self.exportState.exportError = error.localizedDescription
        }
    }
}


private struct ReflectionConfirmationBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: DesignConstants.Spacing.small) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .accessibilityHidden(true)

            Text(self.message)
                .font(.footnote)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(.horizontal, DesignConstants.Spacing.large)
        .padding(.vertical, DesignConstants.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.medium, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(DesignConstants.Shadow.standardOpacity), radius: DesignConstants.Shadow.standardRadius, x: DesignConstants.Shadow.standardX, y: DesignConstants.Shadow.standardY)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignConstants.CornerRadius.medium, style: .continuous)
                .strokeBorder(Color.green.opacity(DesignConstants.Opacity.faint + 0.05), lineWidth: 1)
        )
        .padding(.horizontal, DesignConstants.Spacing.large)
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
        // Acceptable to ignore errors in preview - non-critical seed data
        SeedDataFactory.makeSeedSessions().forEach { try? store.create($0) }
        return (container, store)
    } catch {
        fatalError("Failed to create preview container: \(error)")
    }
}
