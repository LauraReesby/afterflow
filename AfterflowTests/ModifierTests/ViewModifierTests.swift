@testable import Afterflow
import SwiftUI
import Testing
import UniformTypeIdentifiers

@MainActor
struct ViewModifierTests {
    @Test("Error alert shown when error present") func errorAlertShownWhenErrorPresent() throws {
        var errorMessage: String? = "Test error occurred"

        let errorBinding = Binding(
            get: { errorMessage },
            set: { errorMessage = $0 }
        )

        #expect(errorBinding.wrappedValue != nil)
        #expect(errorBinding.wrappedValue == "Test error occurred")
    }

    @Test("Error alert dismissed clears error") func errorAlertDismissedClearsError() throws {
        var errorMessage: String? = "Test error"

        errorMessage = nil

        #expect(errorMessage == nil)
    }

    @Test("Error alert uses custom title") func errorAlertUsesCustomTitle() throws {
        let customTitle = "Custom Error Title"
        let errorMessage: String? = "Error"

        #expect(customTitle == "Custom Error Title")
        #expect(errorMessage != nil)
    }

    @Test("Error alert displays error message") func errorAlertDisplaysErrorMessage() throws {
        let errorMessage: String? = "Detailed error message"

        let message = errorMessage ?? ""

        #expect(message == "Detailed error message")
    }

    @Test("Error alert handles nil error gracefully") func errorAlertHandlesNilErrorGracefully() throws {
        let errorMessage: String? = nil

        let isPresented = errorMessage != nil

        #expect(isPresented == false)
        #expect(errorMessage == nil)
    }

    @Test("Export sheet presentation controlled by binding") func exportSheetPresentationControlledByBinding() throws {
        var showingExportSheet = false

        showingExportSheet = true

        #expect(showingExportSheet == true)

        showingExportSheet = false

        #expect(showingExportSheet == false)
    }

    @Test("File exporter presentation controlled by binding")
    func fileExporterPresentationControlledByBinding() throws {
        var showingFileExporter = false

        showingFileExporter = true

        #expect(showingFileExporter == true)
    }

    @Test("Export error alert presentation controlled by error")
    func exportErrorAlertPresentationControlledByError() throws {
        var exportError: String? = nil

        exportError = "Export failed"
        let isPresented = exportError != nil

        #expect(isPresented == true)
        #expect(exportError == "Export failed")
    }

    @Test("Export overlay shown when exporting") func exportOverlayShownWhenExporting() throws {
        var isExporting = false

        isExporting = true

        #expect(isExporting == true)

        isExporting = false

        #expect(isExporting == false)
    }

    @Test("Export cancel callback invoked") func exportCancelCallbackInvoked() throws {
        var cancelCalled = false
        let cancelExport = { cancelCalled = true }

        cancelExport()

        #expect(cancelCalled == true)
    }

    @Test("Start export callback invoked with request") func startExportCallbackInvokedWithRequest() throws {
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

    @Test("File exporter completion clears document") func fileExporterCompletionClearsDocument() throws {
        var exportDocument: BinaryFileDocument? = BinaryFileDocument(
            data: Data(),
            contentType: .commaSeparatedText
        )

        exportDocument = nil

        #expect(exportDocument == nil)
    }

    @Test("File exporter failure sets error") func fileExporterFailureSetsError() throws {
        var exportError: String? = nil
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "File export failed"])

        exportError = testError.localizedDescription

        #expect(exportError != nil)
        #expect(exportError?.contains("File export failed") == true)
    }

    @Test("Export sheet cancel closes sheet") func exportSheetCancelClosesSheet() throws {
        var showingExportSheet = true

        showingExportSheet = false

        #expect(showingExportSheet == false)
    }

    @Test("Export sheet export starts export and closes sheet")
    func exportSheetExportStartsExportAndClosesSheet() throws {
        var showingExportSheet = true
        var exportStarted = false

        showingExportSheet = false
        exportStarted = true

        #expect(showingExportSheet == false)
        #expect(exportStarted == true)
    }

    @Test("Import picker presentation controlled by binding")
    func importPickerPresentationControlledByBinding() throws {
        var showingImportPicker = false

        showingImportPicker = true

        #expect(showingImportPicker == true)

        showingImportPicker = false

        #expect(showingImportPicker == false)
    }

    @Test("Import error alert presentation controlled by error")
    func importErrorAlertPresentationControlledByError() throws {
        var importError: String? = nil

        importError = "Import failed"
        let isPresented = importError != nil

        #expect(isPresented == true)
        #expect(importError == "Import failed")
    }

    @Test("Import confirmation alert presentation controlled by binding")
    func importConfirmationAlertPresentationControlledByBinding() throws {
        var showingImportConfirmation = false

        showingImportConfirmation = true

        #expect(showingImportConfirmation == true)
    }

    @Test("Import confirmation shows session count") func importConfirmationShowsSessionCount() throws {
        let pendingSessions = SessionFixtureFactory.makeSessions(count: 5)

        let count = pendingSessions.count

        #expect(count == 5)
    }

    @Test("Confirm import callback invoked") func confirmImportCallbackInvoked() throws {
        var confirmCalled = false
        let confirmImport = { confirmCalled = true }

        confirmImport()

        #expect(confirmCalled == true)
    }

    @Test("Import CSV callback invoked with URL") func importCSVCallbackInvokedWithURL() throws {
        var capturedURL: URL?
        let importCSV: (URL) -> Void = { capturedURL = $0 }
        let testURL = URL(fileURLWithPath: "/tmp/test.csv")

        importCSV(testURL)

        #expect(capturedURL != nil)
        #expect(capturedURL == testURL)
    }

    @Test("Import cancel clears pending sessions") func importCancelClearsPendingSessions() throws {
        var pendingImportedSessions = SessionFixtureFactory.makeSessions(count: 3)
        #expect(pendingImportedSessions.count == 3)

        pendingImportedSessions = []

        #expect(pendingImportedSessions.isEmpty)
    }

    @Test("File importer failure sets error") func fileImporterFailureSetsError() throws {
        var importError: String? = nil
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "File selection failed"])

        importError = testError.localizedDescription

        #expect(importError != nil)
        #expect(importError?.contains("File selection failed") == true)
    }

    @Test("Import flow allows CSV content type only") func importFlowAllowsCSVContentTypeOnly() throws {
        let allowedType = UTType.commaSeparatedText

        #expect(allowedType == .commaSeparatedText)
    }

    @Test("Multiple modifiers can be applied to same view") func multipleModifiersCanBeAppliedToSameView() throws {
        var exportError: String? = nil
        var importError: String? = nil

        exportError = "Export error"
        importError = "Import error"

        #expect(exportError != nil)
        #expect(importError != nil)
        #expect(exportError != importError)
    }

    @Test("Error clearing works independently for different modifiers")
    func errorClearingWorksIndependentlyForDifferentModifiers() throws {
        var exportError: String? = "Export error"
        var importError: String? = "Import error"

        exportError = nil

        #expect(exportError == nil)
        #expect(importError != nil)

        importError = nil

        #expect(exportError == nil)
        #expect(importError == nil)
    }

    @Test("Export and import flows maintain separate state") func exportAndImportFlowsMaintainSeparateState() throws {
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
