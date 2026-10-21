import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
@Observable
final class ExportState {
    /// Kept from the previous standalone backup flow so recorded dates carry over.
    static let lastBackupDateKey = "afterflow.backup.lastBackupDate"

    var showingExportSheet = false
    var isExporting = false
    var showingFileExporter = false
    var exportDocument: BinaryFileDocument?
    var exportContentType: UTType = .commaSeparatedText
    var exportFilename = "Afterflow-Export"
    var exportError: String?
    private(set) var lastBackupDate: Date?

    private let defaults: UserDefaults
    private var exportTask: Task<Void, Never>?
    /// The format of the document the file exporter is about to save. `nil` for
    /// documents that didn't come from `startExport`, such as the example import.
    private var pendingFormat: ExportFormat?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.lastBackupDate = defaults.object(forKey: Self.lastBackupDateKey) as? Date
    }

    func startExport(sessions: [TherapeuticSession], with request: ExportRequest) {
        self.isExporting = true
        self.exportError = nil
        self.pendingFormat = nil
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
                self.pendingFormat = request.format
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

    /// Handles the file exporter's result. A backup counts as "last backed up" only
    /// once the exporter reports that the file was actually saved.
    func handleFileExporterResult(_ result: Result<URL, Error>, at date: Date = Date()) {
        let format = self.pendingFormat
        self.pendingFormat = nil
        self.isExporting = false
        self.exportDocument = nil

        switch result {
        case .success:
            if format == .backup {
                self.defaults.set(date, forKey: Self.lastBackupDateKey)
                self.lastBackupDate = date
            }
        case let .failure(error):
            if (error as? CocoaError)?.code != .userCancelled {
                self.exportError = error.localizedDescription
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

        case .backup:
            // A backup always holds every session, so the request's filters are ignored.
            let data = try BackupService().encode(sessions: sessions)
            try Task.checkCancellation()
            return ExportResult(data: data, type: .json, filename: BackupService.filename(for: Date()))
        }
    }
}

struct ExportResult {
    let data: Data
    let type: UTType
    let filename: String
}
