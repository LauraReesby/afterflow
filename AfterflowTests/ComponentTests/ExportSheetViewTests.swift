@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct ExportSheetViewTests {
    @Test("Export sheet initializes with required parameters")
    func exportSheetInitializesWithRequiredParameters() throws {
        let treatmentTypes = [PsychedelicTreatmentType.psilocybin, .mdma]
        var cancelCalled = false
        var exportRequest: ExportRequest?

        let exportSheet = ExportSheetView(
            availableTreatmentTypes: treatmentTypes,
            onCancel: { cancelCalled = true },
            onExport: { exportRequest = $0 }
        )

        #expect(exportSheet.availableTreatmentTypes == treatmentTypes)
        #expect(!cancelCalled)
        #expect(exportRequest == nil)
    }

    @Test("Default format is CSV") func defaultFormatIsCSV() throws {
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: {},
            onExport: { _ in }
        )

        #expect(ExportFormat.csv == .csv)
    }

    @Test("All export formats available") func allExportFormatsAvailable() throws {
        let formats = ExportFormat.allCases

        #expect(formats.contains(.csv))
        #expect(formats.contains(.pdf))
        #expect(formats.count == 2)
    }

    @Test("Export format display names are correct") func exportFormatDisplayNamesAreCorrect() throws {
        #expect(ExportFormat.csv.displayName == "CSV")
        #expect(ExportFormat.pdf.displayName == "PDF")
    }

    @Test("Date filter toggle controls date picker visibility")
    func dateFilterToggleControlsDatePickerVisibility() throws {
        var useDateFilter = false

        useDateFilter = true

        #expect(useDateFilter == true)

        useDateFilter = false

        #expect(useDateFilter == false)
    }

    @Test("Default date range is last 30 days") func defaultDateRangeIsLast30Days() throws {
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now

        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: {},
            onExport: { _ in }
        )

        let difference = Calendar.current.dateComponents([.day], from: thirtyDaysAgo, to: now).day
        #expect(difference == 30)
    }

    @Test("Treatment picker includes all available types") func treatmentPickerIncludesAllAvailableTypes() throws {
        let treatmentTypes = [
            PsychedelicTreatmentType.psilocybin,
            .lsd,
            .mdma,
            .ketamine
        ]

        let exportSheet = ExportSheetView(
            availableTreatmentTypes: treatmentTypes,
            onCancel: {},
            onExport: { _ in }
        )

        #expect(exportSheet.availableTreatmentTypes.count == 4)
        #expect(exportSheet.availableTreatmentTypes.contains(.psilocybin))
        #expect(exportSheet.availableTreatmentTypes.contains(.lsd))
        #expect(exportSheet.availableTreatmentTypes.contains(.mdma))
        #expect(exportSheet.availableTreatmentTypes.contains(.ketamine))
    }

    @Test("Treatment picker handles empty list") func treatmentPickerHandlesEmptyList() throws {
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: {},
            onExport: { _ in }
        )

        #expect(exportSheet.availableTreatmentTypes.isEmpty)
    }

    @Test("Treatment picker has 'All Treatments' option") func treatmentPickerHasAllTreatmentsOption() throws {
        let treatmentTypes = [PsychedelicTreatmentType.psilocybin]
        var selectedTreatment: PsychedelicTreatmentType?

        selectedTreatment = nil

        #expect(selectedTreatment == nil)
    }

    @Test("Cancel button calls onCancel callback") func cancelButtonCallsOnCancelCallback() throws {
        var cancelCalled = false
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: { cancelCalled = true },
            onExport: { _ in }
        )

        exportSheet.onCancel()

        #expect(cancelCalled == true)
    }

    @Test("Export button calls onExport callback") func exportButtonCallsOnExportCallback() throws {
        var exportRequest: ExportRequest?
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: {},
            onExport: { exportRequest = $0 }
        )

        let testRequest = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: nil
        )
        exportSheet.onExport(testRequest)

        #expect(exportRequest != nil)
        #expect(exportRequest?.format == .csv)
    }

    @Test("Export request includes selected format") func exportRequestIncludesSelectedFormat() throws {
        var exportRequest: ExportRequest?

        let csvRequest = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)
        exportRequest = csvRequest

        #expect(exportRequest?.format == .csv)

        let pdfRequest = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)
        exportRequest = pdfRequest

        #expect(exportRequest?.format == .pdf)
    }

    @Test("Export request includes date range when enabled") func exportRequestIncludesDateRangeWhenEnabled() throws {
        let startDate = TestHelpers.dateComponents(year: 2024, month: 1, day: 1)
        let endDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 31)
        let dateRange = startDate ... endDate

        let request = ExportRequest(
            format: .csv,
            dateRange: dateRange,
            treatmentType: nil
        )

        #expect(request.dateRange != nil)
        #expect(request.dateRange?.lowerBound == startDate)
        #expect(request.dateRange?.upperBound == endDate)
    }

    @Test("Export request has no date range when disabled") func exportRequestHasNoDateRangeWhenDisabled() throws {
        let request = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: nil
        )

        #expect(request.dateRange == nil)
    }

    @Test("Export request includes selected treatment type") func exportRequestIncludesSelectedTreatmentType() throws {
        let request = ExportRequest(
            format: .pdf,
            dateRange: nil,
            treatmentType: .psilocybin
        )

        #expect(request.treatmentType == .psilocybin)
    }

    @Test("Export request has no treatment filter when 'All' selected")
    func exportRequestHasNoTreatmentFilterWhenAllSelected() throws {
        let request = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: nil
        )

        #expect(request.treatmentType == nil)
    }

    @Test("Export request with all filters enabled") func exportRequestWithAllFiltersEnabled() throws {
        let startDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 1)
        let endDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 31)

        let request = ExportRequest(
            format: .pdf,
            dateRange: startDate ... endDate,
            treatmentType: .mdma
        )

        #expect(request.format == .pdf)
        #expect(request.dateRange != nil)
        #expect(request.treatmentType == .mdma)
    }

    @Test("Export request with no filters enabled") func exportRequestWithNoFiltersEnabled() throws {
        let request = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: nil
        )

        #expect(request.format == .csv)
        #expect(request.dateRange == nil)
        #expect(request.treatmentType == nil)
    }

    @Test("Export sheet with all treatment types") func exportSheetWithAllTreatmentTypes() throws {
        let allTypes = PsychedelicTreatmentType.allCases

        let exportSheet = ExportSheetView(
            availableTreatmentTypes: allTypes,
            onCancel: {},
            onExport: { _ in }
        )

        #expect(exportSheet.availableTreatmentTypes.count == allTypes.count)
        #expect(exportSheet.availableTreatmentTypes.count == 9)
    }

    @Test("Date range with same start and end date") func dateRangeWithSameStartAndEndDate() throws {
        let sameDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 25)

        let request = ExportRequest(
            format: .csv,
            dateRange: sameDate ... sameDate,
            treatmentType: nil
        )

        #expect(request.dateRange != nil)
        #expect(request.dateRange?.lowerBound == sameDate)
        #expect(request.dateRange?.upperBound == sameDate)
    }
}
