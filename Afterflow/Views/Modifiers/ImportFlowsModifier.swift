import SwiftUI
import UniformTypeIdentifiers

/// `ContentView` creates its `ImportState` in `onAppear` (it needs the environment's
/// store), so the state is optional here; until it exists every binding is inert.
struct ImportFlowsModifier: ViewModifier {
    let state: ImportState?

    func body(content: Content) -> some View {
        content
            .alert("Import Error", isPresented: Binding(
                get: { self.state?.importError != nil },
                set: {
                    if !$0 {
                        self.state?.importError = nil
                    }
                }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.state?.importError ?? "")
            }
            .fileImporter(
                isPresented: Binding(
                    get: { self.state?.showingImportPicker ?? false },
                    set: { self.state?.showingImportPicker = $0 }
                ),
                allowedContentTypes: [.commaSeparatedText, .json]
            ) { result in
                self.state?.handleFilePick(result)
            }
            .alert("Import Sessions", isPresented: Binding(
                get: { self.state?.showingImportConfirmation ?? false },
                set: { self.state?.showingImportConfirmation = $0 }
            )) {
                Button(self.state?.importButtonTitle ?? "Import") {
                    self.state?.confirmImport()
                }
                Button("Cancel", role: .cancel) {
                    self.state?.cancelImport()
                }
            } message: {
                Text(self.state?.importConfirmationMessage ?? "")
            }
            .alert("Import Complete", isPresented: Binding(
                get: { self.state?.showingImportResult ?? false },
                set: { self.state?.showingImportResult = $0 }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.state?.importResultMessage ?? "")
            }
            .alert("Restore Backup", isPresented: Binding(
                get: { self.state?.showingRestoreConfirmation ?? false },
                set: { self.state?.showingRestoreConfirmation = $0 }
            )) {
                Button("Restore") {
                    self.state?.confirmRestore()
                }
                Button("Cancel", role: .cancel) {
                    self.state?.cancelRestore()
                }
            } message: {
                Text(self.state?.restoreConfirmationMessage ?? "")
            }
            .alert("Restore Complete", isPresented: Binding(
                get: { self.state?.showingRestoreResult ?? false },
                set: { self.state?.showingRestoreResult = $0 }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.state?.restoreResultMessage ?? "")
            }
    }
}

extension View {
    func applyImportFlows(_ state: ImportState?) -> some View {
        modifier(ImportFlowsModifier(state: state))
    }
}
