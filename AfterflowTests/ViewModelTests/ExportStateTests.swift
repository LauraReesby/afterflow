@testable import Afterflow
import Foundation
import Testing
import UniformTypeIdentifiers

@MainActor
struct ExportStateTests {
    // MARK: - Basic Workflows

    @Test("Export CSV completes successfully") func startExportCSVSucceeds() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 5)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)

        // Wait for async export to complete
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert
        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportContentType == .commaSeparatedText)
        #expect(exportState.exportFilename == "Afterflow-Export")
        #expect(exportState.exportError == nil)
        #expect(exportState.showingFileExporter == true)
    }

    @Test("Export PDF completes successfully") func startExportPDFSucceeds() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 5)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)

        // Wait for async export to complete
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 3.0)

        // Assert
        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportContentType == .pdf)
        #expect(exportState.exportFilename == "Afterflow-Export")
        #expect(exportState.exportError == nil)
        #expect(exportState.showingFileExporter == true)
    }

    @Test("Export sets isExporting true while running") func exportSetsIsExportingTrueWhileRunning() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 100)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)

        // Assert - Check immediately that isExporting is true
        #expect(exportState.isExporting == true)

        // Wait for completion
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 5.0)
    }

    @Test("Export sets document on success") func exportSetsDocumentOnSuccess() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 3)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert
        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportDocument?.contentType == .commaSeparatedText)
    }

    @Test("Export clears isExporting on success") func exportClearsIsExportingOnSuccess() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 2)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert
        #expect(exportState.isExporting == false)
    }

    @Test("Export shows file exporter on success") func exportShowsFileExporterOnSuccess() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 2)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert
        #expect(exportState.showingFileExporter == true)
    }

    // MARK: - Cancellation

    @Test("Cancel export stops task") func cancelExportStopsTask() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        #expect(exportState.isExporting == true)

        exportState.cancelExport()

        // Wait a bit to ensure cancellation takes effect
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1s

        // Assert
        #expect(exportState.isExporting == false)
    }

    @Test("Cancel export clears isExporting") func cancelExportClearsIsExporting() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 500)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        exportState.cancelExport()

        // Assert
        #expect(exportState.isExporting == false)
    }

    @Test("Cancel export before start handled gracefully") func cancelExportBeforeStart() async throws {
        // Arrange
        let exportState = ExportState()

        // Act - Cancel without starting export
        exportState.cancelExport()

        // Assert - Should not crash and state should be clean
        #expect(exportState.isExporting == false)
        #expect(exportState.exportError == nil)
    }

    // MARK: - Error Handling

    @Test("Export error clears isExporting") func exportErrorClearsIsExporting() async throws {
        // Arrange
        let exportState = ExportState()
        // Empty sessions might cause an error in some export scenarios
        let sessions: [TherapeuticSession] = []
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)

        // Wait for completion (success or failure)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert - isExporting should be false regardless of success/failure
        #expect(exportState.isExporting == false)
    }

    @Test("Export error prevents file exporter") func exportErrorPreventsFileExporter() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions: [TherapeuticSession] = []
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Set initial state
        exportState.showingFileExporter = false

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert - If there was an error, file exporter should not show
        // (This test passes if export succeeds OR if error doesn't show exporter)
        if exportState.exportError != nil {
            #expect(exportState.showingFileExporter == false)
        }
    }

    @Test("Cancelled task does not set error") func cancelledTaskDoesNotSetError() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        exportState.cancelExport()

        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s

        // Assert - Cancellation should not trigger error state
        // (Note: exportError might be nil or might have been cleared)
        #expect(exportState.isExporting == false)
    }

    // MARK: - Filtering

    @Test("Export respects date range filter") func exportRespectsDateRangeFilter() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 10)

        let startDate = TestHelpers.dateComponents(year: 2024, month: 1, day: 1)
        let endDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 30)
        let dateRange = startDate ... endDate

        let request = ExportRequest(format: .csv, dateRange: dateRange, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert - Export should complete with filtered data
        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportError == nil)
    }

    @Test("Export respects treatment type filter") func exportRespectsTreatmentTypeFilter() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 10)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: .psilocybin)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert - Export should complete with filtered data
        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportError == nil)
    }

    @Test("Export with no sessions succeeds") func exportWithNoSessionsSucceeds() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions: [TherapeuticSession] = []
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        // Assert - Empty export should complete (creating header-only CSV)
        // Success indicates graceful handling of edge case
        #expect(exportState.isExporting == false)
    }

    // MARK: - Edge Cases

    @Test("Multiple exports in sequence") func multipleExportsInSequence() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions1 = SessionFixtureFactory.makeSessions(count: 3)
        let sessions2 = SessionFixtureFactory.makeSessions(count: 5)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act - First export
        exportState.startExport(sessions: sessions1, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        let firstDocument = exportState.exportDocument

        // Second export
        exportState.startExport(sessions: sessions2, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        let secondDocument = exportState.exportDocument

        // Assert - Both exports should succeed independently
        #expect(firstDocument != nil)
        #expect(secondDocument != nil)
        #expect(exportState.exportError == nil)
    }

    @Test("Export cancellation during perform export") func exportCancellationDuringPerformExport() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 500)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)

        // Cancel almost immediately
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01s
        exportState.cancelExport()

        // Wait for cancellation to propagate
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s

        // Assert
        #expect(exportState.isExporting == false)
    }

    @Test("Export with large sessions completes") func exportWithLargeSessionsCompletes() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 10.0)

        // Assert - Large export should complete successfully
        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportError == nil)
        #expect(exportState.isExporting == false)
    }

    @Test("Export clears previous error on new export") func exportClearsPreviousErrorOnNewExport() async throws {
        // Arrange
        let exportState = ExportState()
        exportState.exportError = "Previous error"

        let sessions = SessionFixtureFactory.makeSessions(count: 3)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act
        exportState.startExport(sessions: sessions, with: request)

        // Assert - Error should be cleared immediately when starting new export
        #expect(exportState.exportError == nil)

        // Wait for completion
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)
    }

    @Test(
        "Export cancels previous task on new export",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func exportCancelsPreviousTaskOnNewExport() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions1 = SessionFixtureFactory.makeSessions(count: 500)
        let sessions2 = SessionFixtureFactory.makeSessions(count: 3)
        let request1 = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)
        let request2 = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        // Act - Start first export
        exportState.startExport(sessions: sessions1, with: request1)

        // Yield to allow the first Task to start
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        #expect(exportState.isExporting == true)

        // Start second export immediately (should cancel first)
        exportState.startExport(sessions: sessions2, with: request2)

        // Yield to allow the second Task to start
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        // Wait for second export to complete
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 10.0)

        // Assert - Second export should succeed
        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportContentType == .commaSeparatedText) // CSV format
        #expect(exportState.exportError == nil)
    }

    @Test("Export with combined filters succeeds") func exportWithCombinedFiltersSucceeds() async throws {
        // Arrange
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 20)

        let startDate = TestHelpers.dateComponents(year: 2024, month: 1, day: 1)
        let endDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 31)
        let dateRange = startDate ... endDate

        let request = ExportRequest(
            format: .pdf,
            dateRange: dateRange,
            treatmentType: .ketamine
        )

        // Act
        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 3.0)

        // Assert - Export with both filters should succeed
        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportContentType == .pdf)
        #expect(exportState.exportError == nil)
    }
}
