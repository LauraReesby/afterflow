import SwiftUI
import UniformTypeIdentifiers

struct BackupFlowsModifier: ViewModifier {
    @Bindable var state: BackupState
    @Environment(SessionStore.self) private var sessionStore

    func body(content: Content) -> some View {
        content
            // SwiftUI can present only one file exporter/importer per view, and the
            // CSV flows already attach theirs to the same hierarchy, so each of
            // these lives on its own background host.
            .background {
                Color.clear
                    .fileExporter(
                        isPresented: self.$state.showingBackupExporter,
                        document: self.state.backupDocument,
                        contentType: .json,
                        defaultFilename: self.state.backupFilename
                    ) { result in
                        self.state.handleBackupExport(result)
                    }
            }
            .background {
                Color.clear
                    .fileImporter(
                        isPresented: self.$state.showingRestorePicker,
                        allowedContentTypes: [.json]
                    ) { result in
                        self.state.handleRestorePick(result)
                    }
            }
            .alert("Backup Error", isPresented: self.isPresented(self.$state.backupError)) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.state.backupError ?? "")
            }
            .alert("Restore Error", isPresented: self.isPresented(self.$state.restoreError)) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.state.restoreError ?? "")
            }
            .alert("Restore Backup", isPresented: self.$state.showingRestoreConfirmation) {
                Button("Restore") {
                    self.state.confirmRestore(into: self.sessionStore)
                }
                Button("Cancel", role: .cancel) {
                    self.state.cancelRestore()
                }
            } message: {
                Text(self.state.restoreConfirmationMessage)
            }
            .alert("Restore Complete", isPresented: self.$state.showingRestoreResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.state.restoreResultMessage)
            }
    }

    private func isPresented(_ message: Binding<String?>) -> Binding<Bool> {
        Binding(
            get: { message.wrappedValue != nil },
            set: {
                if !$0 {
                    message.wrappedValue = nil
                }
            }
        )
    }
}

extension View {
    func applyBackupFlows(_ state: BackupState) -> some View {
        modifier(BackupFlowsModifier(state: state))
    }
}
