import SwiftUI
import UniformTypeIdentifiers

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

extension View {
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
