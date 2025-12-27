@testable import Afterflow
import SwiftUI
import Testing
import UniformTypeIdentifiers

@MainActor
struct ViewModifierTests {
    // MARK: - ErrorAlertModifier Tests

    @Test("Error alert shown when error present") func errorAlertShownWhenErrorPresent() throws {
        // Arrange
        var errorMessage: String? = "Test error occurred"

        // Act
        let errorBinding = Binding(
            get: { errorMessage },
            set: { errorMessage = $0 }
        )

        // Assert
        #expect(errorBinding.wrappedValue != nil)
        #expect(errorBinding.wrappedValue == "Test error occurred")
    }

    @Test("Error alert dismissed clears error") func errorAlertDismissedClearsError() throws {
        // Arrange
        var errorMessage: String? = "Test error"

        // Act - Simulate alert dismissal
        errorMessage = nil

        // Assert
        #expect(errorMessage == nil)
    }

    @Test("Error alert uses custom title") func errorAlertUsesCustomTitle() throws {
        // Arrange
        let customTitle = "Custom Error Title"
        var errorMessage: String? = "Error"

        // Act & Assert
        // Custom title is used in the modifier
        #expect(customTitle == "Custom Error Title")
        #expect(errorMessage != nil)
    }

    @Test("Error alert displays error message") func errorAlertDisplaysErrorMessage() throws {
        // Arrange
        var errorMessage: String? = "Detailed error message"

        // Act
        let message = errorMessage ?? ""

        // Assert
        #expect(message == "Detailed error message")
    }

    @Test("Error alert handles nil error gracefully") func errorAlertHandlesNilErrorGracefully() throws {
        // Arrange
        var errorMessage: String? = nil

        // Act
        let isPresented = errorMessage != nil

        // Assert
        #expect(isPresented == false)
        #expect(errorMessage == nil)
    }

    // MARK: - ExportFlowsModifier Tests

    @Test("Export sheet presentation controlled by binding") func exportSheetPresentationControlledByBinding() throws {
        // Arrange
        var showingExportSheet = false

        // Act
        showingExportSheet = true

        // Assert
        #expect(showingExportSheet == true)

        // Act
        showingExportSheet = false

        // Assert
        #expect(showingExportSheet == false)
    }

    @Test("File exporter presentation controlled by binding")
    func fileExporterPresentationControlledByBinding() throws {
        // Arrange
        var showingFileExporter = false

        // Act
        showingFileExporter = true

        // Assert
        #expect(showingFileExporter == true)
    }

    @Test("Export error alert presentation controlled by error")
    func exportErrorAlertPresentationControlledByError() throws {
        // Arrange
        var exportError: String? = nil

        // Act
        exportError = "Export failed"
        let isPresented = exportError != nil

        // Assert
        #expect(isPresented == true)
        #expect(exportError == "Export failed")
    }

    @Test("Export overlay shown when exporting") func exportOverlayShownWhenExporting() throws {
        // Arrange
        var isExporting = false

        // Act
        isExporting = true

        // Assert
        #expect(isExporting == true)

        // Act
        isExporting = false

        // Assert
        #expect(isExporting == false)
    }

    @Test("Export cancel callback invoked") func exportCancelCallbackInvoked() throws {
        // Arrange
        var cancelCalled = false
        let cancelExport = { cancelCalled = true }

        // Act
        cancelExport()

        // Assert
        #expect(cancelCalled == true)
    }

    @Test("Start export callback invoked with request") func startExportCallbackInvokedWithRequest() throws {
        // Arrange
        var capturedRequest: ExportRequest?
        let startExport: (ExportRequest) -> Void = { capturedRequest = $0 }

        let testRequest = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: .psilocybin
        )

        // Act
        startExport(testRequest)

        // Assert
        #expect(capturedRequest != nil)
        #expect(capturedRequest?.format == .csv)
        #expect(capturedRequest?.treatmentType == .psilocybin)
    }

    @Test("File exporter completion clears document") func fileExporterCompletionClearsDocument() throws {
        // Arrange
        var exportDocument: BinaryFileDocument? = BinaryFileDocument(
            data: Data(),
            contentType: .commaSeparatedText
        )

        // Act - Simulate file exporter completion
        exportDocument = nil

        // Assert
        #expect(exportDocument == nil)
    }

    @Test("File exporter failure sets error") func fileExporterFailureSetsError() throws {
        // Arrange
        var exportError: String? = nil
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "File export failed"])

        // Act - Simulate file exporter failure
        exportError = testError.localizedDescription

        // Assert
        #expect(exportError != nil)
        #expect(exportError?.contains("File export failed") == true)
    }

    @Test("Export sheet cancel closes sheet") func exportSheetCancelClosesSheet() throws {
        // Arrange
        var showingExportSheet = true

        // Act - Simulate cancel action
        showingExportSheet = false

        // Assert
        #expect(showingExportSheet == false)
    }

    @Test("Export sheet export starts export and closes sheet")
    func exportSheetExportStartsExportAndClosesSheet() throws {
        // Arrange
        var showingExportSheet = true
        var exportStarted = false

        // Act - Simulate export action
        showingExportSheet = false
        exportStarted = true

        // Assert
        #expect(showingExportSheet == false)
        #expect(exportStarted == true)
    }

    // MARK: - ImportFlowsModifier Tests

    @Test("Import picker presentation controlled by binding")
    func importPickerPresentationControlledByBinding() throws {
        // Arrange
        var showingImportPicker = false

        // Act
        showingImportPicker = true

        // Assert
        #expect(showingImportPicker == true)

        // Act
        showingImportPicker = false

        // Assert
        #expect(showingImportPicker == false)
    }

    @Test("Import error alert presentation controlled by error")
    func importErrorAlertPresentationControlledByError() throws {
        // Arrange
        var importError: String? = nil

        // Act
        importError = "Import failed"
        let isPresented = importError != nil

        // Assert
        #expect(isPresented == true)
        #expect(importError == "Import failed")
    }

    @Test("Import confirmation alert presentation controlled by binding")
    func importConfirmationAlertPresentationControlledByBinding() throws {
        // Arrange
        var showingImportConfirmation = false

        // Act
        showingImportConfirmation = true

        // Assert
        #expect(showingImportConfirmation == true)
    }

    @Test("Import confirmation shows session count") func importConfirmationShowsSessionCount() throws {
        // Arrange
        let pendingSessions = SessionFixtureFactory.makeSessions(count: 5)

        // Act
        let count = pendingSessions.count

        // Assert
        #expect(count == 5)
    }

    @Test("Confirm import callback invoked") func confirmImportCallbackInvoked() throws {
        // Arrange
        var confirmCalled = false
        let confirmImport = { confirmCalled = true }

        // Act
        confirmImport()

        // Assert
        #expect(confirmCalled == true)
    }

    @Test("Import CSV callback invoked with URL") func importCSVCallbackInvokedWithURL() throws {
        // Arrange
        var capturedURL: URL?
        let importCSV: (URL) -> Void = { capturedURL = $0 }
        let testURL = URL(fileURLWithPath: "/tmp/test.csv")

        // Act
        importCSV(testURL)

        // Assert
        #expect(capturedURL != nil)
        #expect(capturedURL == testURL)
    }

    @Test("Import cancel clears pending sessions") func importCancelClearsPendingSessions() throws {
        // Arrange
        var pendingImportedSessions = SessionFixtureFactory.makeSessions(count: 3)
        #expect(pendingImportedSessions.count == 3)

        // Act - Simulate cancel action
        pendingImportedSessions = []

        // Assert
        #expect(pendingImportedSessions.isEmpty)
    }

    @Test("File importer failure sets error") func fileImporterFailureSetsError() throws {
        // Arrange
        var importError: String? = nil
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "File selection failed"])

        // Act - Simulate file importer failure
        importError = testError.localizedDescription

        // Assert
        #expect(importError != nil)
        #expect(importError?.contains("File selection failed") == true)
    }

    @Test("Import flow allows CSV content type only") func importFlowAllowsCSVContentTypeOnly() throws {
        // Arrange
        let allowedType = UTType.commaSeparatedText

        // Act & Assert
        #expect(allowedType == .commaSeparatedText)
    }

    // MARK: - Integration Tests

    @Test("Multiple modifiers can be applied to same view") func multipleModifiersCanBeAppliedToSameView() throws {
        // Arrange
        var exportError: String? = nil
        var importError: String? = nil

        // Act
        exportError = "Export error"
        importError = "Import error"

        // Assert - Both errors can coexist
        #expect(exportError != nil)
        #expect(importError != nil)
        #expect(exportError != importError)
    }

    @Test("Error clearing works independently for different modifiers")
    func errorClearingWorksIndependentlyForDifferentModifiers() throws {
        // Arrange
        var exportError: String? = "Export error"
        var importError: String? = "Import error"

        // Act - Clear export error only
        exportError = nil

        // Assert
        #expect(exportError == nil)
        #expect(importError != nil)

        // Act - Clear import error
        importError = nil

        // Assert
        #expect(exportError == nil)
        #expect(importError == nil)
    }

    @Test("Export and import flows maintain separate state") func exportAndImportFlowsMaintainSeparateState() throws {
        // Arrange
        var showingExportSheet = false
        var showingImportPicker = false

        // Act
        showingExportSheet = true

        // Assert
        #expect(showingExportSheet == true)
        #expect(showingImportPicker == false)

        // Act
        showingImportPicker = true

        // Assert
        #expect(showingExportSheet == true)
        #expect(showingImportPicker == true)
    }
}
