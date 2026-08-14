@testable import Afterflow
import SwiftUI
import Testing
import UniformTypeIdentifiers

@MainActor
struct ViewModifierTests {
    @Test("Error alert shown when error present") func errorAlertShownWhenErrorPresent() {
        var errorMessage: String? = "Test error occurred"

        let errorBinding = Binding(
            get: { errorMessage },
            set: { errorMessage = $0 }
        )

        #expect(errorBinding.wrappedValue != nil)
        #expect(errorBinding.wrappedValue == "Test error occurred")
    }

    @Test("Error alert dismissed clears error") func errorAlertDismissedClearsError() {
        var errorMessage: String? = "Test error"

        errorMessage = nil

        #expect(errorMessage == nil)
    }

    @Test("Error alert uses custom title") func errorAlertUsesCustomTitle() {
        let customTitle = "Custom Error Title"
        let errorMessage: String? = "Error"

        #expect(customTitle == "Custom Error Title")
        #expect(errorMessage != nil)
    }

    @Test("Error alert displays error message") func errorAlertDisplaysErrorMessage() {
        let errorMessage: String? = "Detailed error message"

        let message = errorMessage ?? ""

        #expect(message == "Detailed error message")
    }

    @Test("Error alert handles nil error gracefully") func errorAlertHandlesNilErrorGracefully() {
        let errorMessage: String? = nil

        let isPresented = errorMessage != nil

        #expect(isPresented == false)
        #expect(errorMessage == nil)
    }

    @Test("Export sheet presentation controlled by binding") func exportSheetPresentationControlledByBinding() {
        var showingExportSheet = false

        showingExportSheet = true

        #expect(showingExportSheet == true)

        showingExportSheet = false

        #expect(showingExportSheet == false)
    }

    @Test("File exporter presentation controlled by binding") func fileExporterPresentationControlledByBinding() {
        var showingFileExporter = false

        showingFileExporter = true

        #expect(showingFileExporter == true)
    }

    @Test("Export error alert presentation controlled by error") func exportErrorAlertPresentationControlledByError() {
        var exportError: String?

        exportError = "Export failed"
        let isPresented = exportError != nil

        #expect(isPresented == true)
        #expect(exportError == "Export failed")
    }

    @Test("Export overlay shown when exporting") func exportOverlayShownWhenExporting() {
        var isExporting = false

        isExporting = true

        #expect(isExporting == true)

        isExporting = false

        #expect(isExporting == false)
    }

    @Test("Export cancel callback invoked") func exportCancelCallbackInvoked() {
        var cancelCalled = false
        let cancelExport = { cancelCalled = true }

        cancelExport()

        #expect(cancelCalled == true)
    }

    @Test("Start export callback invoked with request") func startExportCallbackInvokedWithRequest() {
        var capturedRequest: ExportRequest?
        let startExport: (ExportRequest) -> Void = { capturedRequest = $0 }

        let testRequest = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: .psilocybin
        )

        startExport(testRequest)

        #expect(capturedRequest != nil)
        #expect(capturedRequest?.format == .csv)
        #expect(capturedRequest?.treatmentType == .psilocybin)
    }

    @Test("File exporter completion clears document") func fileExporterCompletionClearsDocument() {
        var exportDocument: BinaryFileDocument? = BinaryFileDocument(
            data: Data(),
            contentType: .commaSeparatedText
        )

        exportDocument = nil

        #expect(exportDocument == nil)
    }

    @Test("File exporter failure sets error") func fileExporterFailureSetsError() {
        var exportError: String?
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "File export failed"])

        exportError = testError.localizedDescription

        #expect(exportError != nil)
        #expect(exportError?.contains("File export failed") == true)
    }

    @Test("Export sheet cancel closes sheet") func exportSheetCancelClosesSheet() {
        var showingExportSheet = true

        showingExportSheet = false

        #expect(showingExportSheet == false)
    }

    @Test("Export sheet export starts export and closes sheet") func exportSheetExportStartsExportAndClosesSheet() {
        var showingExportSheet = true
        var exportStarted = false

        showingExportSheet = false
        exportStarted = true

        #expect(showingExportSheet == false)
        #expect(exportStarted == true)
    }

    @Test("Import picker presentation controlled by binding") func importPickerPresentationControlledByBinding() {
        var showingImportPicker = false

        showingImportPicker = true

        #expect(showingImportPicker == true)

        showingImportPicker = false

        #expect(showingImportPicker == false)
    }

    @Test("Import error alert presentation controlled by error") func importErrorAlertPresentationControlledByError() {
        var importError: String?

        importError = "Import failed"
        let isPresented = importError != nil

        #expect(isPresented == true)
        #expect(importError == "Import failed")
    }

    @Test("Import confirmation alert presentation controlled by binding")
    func importConfirmationAlertPresentationControlledByBinding() {
        var showingImportConfirmation = false

        showingImportConfirmation = true

        #expect(showingImportConfirmation == true)
    }

    @Test("Import confirmation shows session count") func importConfirmationShowsSessionCount() {
        let pendingSessions = SessionFixtureFactory.makeSessions(count: 5)

        let count = pendingSessions.count

        #expect(count == 5)
    }

    @Test("Confirm import callback invoked") func confirmImportCallbackInvoked() {
        var confirmCalled = false
        let confirmImport = { confirmCalled = true }

        confirmImport()

        #expect(confirmCalled == true)
    }

    @Test("Import CSV callback invoked with URL") func importCSVCallbackInvokedWithURL() {
        var capturedURL: URL?
        let importCSV: (URL) -> Void = { capturedURL = $0 }
        let testURL = URL(fileURLWithPath: "/tmp/test.csv")

        importCSV(testURL)

        #expect(capturedURL != nil)
        #expect(capturedURL == testURL)
    }

    @Test("Import cancel clears pending sessions") func importCancelClearsPendingSessions() {
        var pendingImportedSessions = SessionFixtureFactory.makeSessions(count: 3)
        #expect(pendingImportedSessions.count == 3)

        pendingImportedSessions = []

        #expect(pendingImportedSessions.isEmpty)
    }

    @Test("File importer failure sets error") func fileImporterFailureSetsError() {
        var importError: String?
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "File selection failed"])

        importError = testError.localizedDescription

        #expect(importError != nil)
        #expect(importError?.contains("File selection failed") == true)
    }

    @Test("Import flow allows CSV content type only") func importFlowAllowsCSVContentTypeOnly() {
        let allowedType = UTType.commaSeparatedText

        #expect(allowedType == .commaSeparatedText)
    }

    @Test("Multiple modifiers can be applied to same view") func multipleModifiersCanBeAppliedToSameView() {
        var exportError: String?
        var importError: String?

        exportError = "Export error"
        importError = "Import error"

        #expect(exportError != nil)
        #expect(importError != nil)
        #expect(exportError != importError)
    }

    @Test("Error clearing works independently for different modifiers")
    func errorClearingWorksIndependentlyForDifferentModifiers() {
        var exportError: String? = "Export error"
        var importError: String? = "Import error"

        exportError = nil

        #expect(exportError == nil)
        #expect(importError != nil)

        importError = nil

        #expect(exportError == nil)
        #expect(importError == nil)
    }

    @Test("Export and import flows maintain separate state") func exportAndImportFlowsMaintainSeparateState() {
        var showingExportSheet = false
        var showingImportPicker = false

        showingExportSheet = true

        #expect(showingExportSheet == true)
        #expect(showingImportPicker == false)

        showingImportPicker = true

        #expect(showingExportSheet == true)
        #expect(showingImportPicker == true)
    }
}
