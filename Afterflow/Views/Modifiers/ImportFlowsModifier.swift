import SwiftUI
import UniformTypeIdentifiers

struct ImportFlowConfig {
    let showingImportPicker: Binding<Bool>
    let importError: Binding<String?>
    let showingImportConfirmation: Binding<Bool>
    let pendingImportedSessions: Binding<[TherapeuticSession]>
    let confirmImport: () -> Void
    let importCSV: (URL) -> Void
}

extension View {
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
}
