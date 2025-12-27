import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class ExportState {
    var showingExportSheet = false
    var isExporting = false
    var showingFileExporter = false
    var exportDocument: BinaryFileDocument?
    var exportContentType: UTType = .commaSeparatedText
    var exportFilename = "Afterflow-Export"
    var exportError: String?

    private var exportTask: Task<Void, Never>?

    func startExport(sessions: [TherapeuticSession], with request: ExportRequest) {
        self.isExporting = true
        self.exportError = nil
        self.exportTask?.cancel()

        self.exportTask = Task {
            do {
                let result = try await self.performExport(for: sessions, request: request)

                
                if ProcessInfo.processInfo.arguments.contains("-ui-testing") {
                    try? await Task.sleep(nanoseconds: DesignConstants.Testing.exportDelay)
                }

                self.exportDocument = BinaryFileDocument(data: result.data, contentType: result.type)
                self.exportContentType = result.type
                self.exportFilename = result.filename
                self.isExporting = false
                self.showingFileExporter = true
            } catch {
                self.exportError = error.localizedDescription
                self.isExporting = false
            }
        }
    }

    func cancelExport() {
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

struct ExportResult {
    let data: Data
    let type: UTType
    let filename: String
}
