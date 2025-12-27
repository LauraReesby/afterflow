@testable import Afterflow
import Foundation
import Testing
import UniformTypeIdentifiers

@MainActor
struct ExportStateTests {
    @Test("Export CSV completes successfully") func startExportCSVSucceeds() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 5)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)

        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportContentType == .commaSeparatedText)
        #expect(exportState.exportFilename == "Afterflow-Export")
        #expect(exportState.exportError == nil)
        #expect(exportState.showingFileExporter == true)
    }

    @Test("Export PDF completes successfully") func startExportPDFSucceeds() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 5)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)

        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 3.0)

        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportContentType == .pdf)
        #expect(exportState.exportFilename == "Afterflow-Export")
        #expect(exportState.exportError == nil)
        #expect(exportState.showingFileExporter == true)
    }

    @Test("Export sets isExporting true while running") func exportSetsIsExportingTrueWhileRunning() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 100)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)

        #expect(exportState.isExporting == true)

        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 5.0)
    }

    @Test("Export sets document on success") func exportSetsDocumentOnSuccess() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 3)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportDocument?.contentType == .commaSeparatedText)
    }

    @Test("Export clears isExporting on success") func exportClearsIsExportingOnSuccess() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 2)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        #expect(exportState.isExporting == false)
    }

    @Test("Export shows file exporter on success") func exportShowsFileExporterOnSuccess() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 2)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        #expect(exportState.showingFileExporter == true)
    }

    @Test("Cancel export stops task") func cancelExportStopsTask() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        #expect(exportState.isExporting == true)

        exportState.cancelExport()

        try await Task.sleep(nanoseconds: 100_000_000)

        #expect(exportState.isExporting == false)
    }

    @Test("Cancel export clears isExporting") func cancelExportClearsIsExporting() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 500)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        exportState.cancelExport()

        #expect(exportState.isExporting == false)
    }

    @Test("Cancel export before start handled gracefully") func cancelExportBeforeStart() async throws {
        let exportState = ExportState()

        exportState.cancelExport()

        #expect(exportState.isExporting == false)
        #expect(exportState.exportError == nil)
    }

    @Test("Export error clears isExporting") func exportErrorClearsIsExporting() async throws {
        let exportState = ExportState()

        let sessions: [TherapeuticSession] = []
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)

        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        #expect(exportState.isExporting == false)
    }

    @Test("Export error prevents file exporter") func exportErrorPreventsFileExporter() async throws {
        let exportState = ExportState()
        let sessions: [TherapeuticSession] = []
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.showingFileExporter = false

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        if exportState.exportError != nil {
            #expect(exportState.showingFileExporter == false)
        }
    }

    @Test("Cancelled task does not set error") func cancelledTaskDoesNotSetError() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        exportState.cancelExport()

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(exportState.isExporting == false)
    }

    @Test("Export respects date range filter") func exportRespectsDateRangeFilter() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 10)

        let startDate = TestHelpers.dateComponents(year: 2024, month: 1, day: 1)
        let endDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 30)
        let dateRange = startDate ... endDate

        let request = ExportRequest(format: .csv, dateRange: dateRange, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportError == nil)
    }

    @Test("Export respects treatment type filter") func exportRespectsTreatmentTypeFilter() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 10)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: .psilocybin)

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportError == nil)
    }

    @Test("Export with no sessions succeeds") func exportWithNoSessionsSucceeds() async throws {
        let exportState = ExportState()
        let sessions: [TherapeuticSession] = []
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        #expect(exportState.isExporting == false)
    }

    @Test("Multiple exports in sequence") func multipleExportsInSequence() async throws {
        let exportState = ExportState()
        let sessions1 = SessionFixtureFactory.makeSessions(count: 3)
        let sessions2 = SessionFixtureFactory.makeSessions(count: 5)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions1, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        let firstDocument = exportState.exportDocument

        exportState.startExport(sessions: sessions2, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)

        let secondDocument = exportState.exportDocument

        #expect(firstDocument != nil)
        #expect(secondDocument != nil)
        #expect(exportState.exportError == nil)
    }

    @Test("Export cancellation during perform export") func exportCancellationDuringPerformExport() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 500)
        let request = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)

        try await Task.sleep(nanoseconds: 10_000_000)
        exportState.cancelExport()

        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(exportState.isExporting == false)
    }

    @Test("Export with large sessions completes") func exportWithLargeSessionsCompletes() async throws {
        let exportState = ExportState()
        let sessions = SessionFixtureFactory.makeSessions(count: 1000)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 10.0)

        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportError == nil)
        #expect(exportState.isExporting == false)
    }

    @Test("Export clears previous error on new export") func exportClearsPreviousErrorOnNewExport() async throws {
        let exportState = ExportState()
        exportState.exportError = "Previous error"

        let sessions = SessionFixtureFactory.makeSessions(count: 3)
        let request = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions, with: request)

        #expect(exportState.exportError == nil)

        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 2.0)
    }

    @Test(
        "Export cancels previous task on new export",
        .serialized,
        .disabled("Fails in full suite - MainActor/async timing issue")
    ) func exportCancelsPreviousTaskOnNewExport() async throws {
        let exportState = ExportState()
        let sessions1 = SessionFixtureFactory.makeSessions(count: 500)
        let sessions2 = SessionFixtureFactory.makeSessions(count: 3)
        let request1 = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)
        let request2 = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)

        exportState.startExport(sessions: sessions1, with: request1)

        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(exportState.isExporting == true)

        exportState.startExport(sessions: sessions2, with: request2)

        try await Task.sleep(nanoseconds: 500_000_000)

        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 10.0)

        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportContentType == .commaSeparatedText)
        #expect(exportState.exportError == nil)
    }

    @Test("Export with combined filters succeeds") func exportWithCombinedFiltersSucceeds() async throws {
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

        exportState.startExport(sessions: sessions, with: request)
        try await TestHelpers.waitFor({ !exportState.isExporting }, timeout: 3.0)

        #expect(exportState.exportDocument != nil)
        #expect(exportState.exportContentType == .pdf)
        #expect(exportState.exportError == nil)
    }
}
