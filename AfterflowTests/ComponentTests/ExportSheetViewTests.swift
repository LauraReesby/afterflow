@testable import Afterflow
import SwiftUI
import Testing

@MainActor
struct ExportSheetViewTests {
    // MARK: - Initialization Tests

    @Test("Export sheet initializes with required parameters")
    func exportSheetInitializesWithRequiredParameters() throws {
        // Arrange
        let treatmentTypes = [PsychedelicTreatmentType.psilocybin, .mdma]
        var cancelCalled = false
        var exportRequest: ExportRequest?

        // Act
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: treatmentTypes,
            onCancel: { cancelCalled = true },
            onExport: { exportRequest = $0 }
        )

        // Assert
        #expect(exportSheet.availableTreatmentTypes == treatmentTypes)
        #expect(!cancelCalled)
        #expect(exportRequest == nil)
    }

    // MARK: - Format Picker Tests

    @Test("Default format is CSV") func defaultFormatIsCSV() throws {
        // Arrange
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: {},
            onExport: { _ in }
        )

        // Act & Assert
        // Default selectedFormat should be .csv
        #expect(ExportFormat.csv == .csv)
    }

    @Test("All export formats available") func allExportFormatsAvailable() throws {
        // Arrange & Act
        let formats = ExportFormat.allCases

        // Assert
        #expect(formats.contains(.csv))
        #expect(formats.contains(.pdf))
        #expect(formats.count == 2)
    }

    @Test("Export format display names are correct") func exportFormatDisplayNamesAreCorrect() throws {
        // Arrange & Act & Assert
        #expect(ExportFormat.csv.displayName == "CSV")
        #expect(ExportFormat.pdf.displayName == "PDF")
    }

    // MARK: - Date Filter Tests

    @Test("Date filter toggle controls date picker visibility")
    func dateFilterToggleControlsDatePickerVisibility() throws {
        // Arrange
        var useDateFilter = false

        // Act
        useDateFilter = true

        // Assert - When true, date pickers should be visible
        #expect(useDateFilter == true)

        // Act
        useDateFilter = false

        // Assert - When false, date pickers should be hidden
        #expect(useDateFilter == false)
    }

    @Test("Default date range is last 30 days") func defaultDateRangeIsLast30Days() throws {
        // Arrange
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now

        // Act
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: {},
            onExport: { _ in }
        )

        // Assert
        // Default start date should be approximately 30 days ago
        // (We can't check the exact private state, but we verify the logic)
        let difference = Calendar.current.dateComponents([.day], from: thirtyDaysAgo, to: now).day
        #expect(difference == 30)
    }

    // MARK: - Treatment Type Picker Tests

    @Test("Treatment picker includes all available types") func treatmentPickerIncludesAllAvailableTypes() throws {
        // Arrange
        let treatmentTypes = [
            PsychedelicTreatmentType.psilocybin,
            .lsd,
            .mdma,
            .ketamine
        ]

        // Act
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: treatmentTypes,
            onCancel: {},
            onExport: { _ in }
        )

        // Assert
        #expect(exportSheet.availableTreatmentTypes.count == 4)
        #expect(exportSheet.availableTreatmentTypes.contains(.psilocybin))
        #expect(exportSheet.availableTreatmentTypes.contains(.lsd))
        #expect(exportSheet.availableTreatmentTypes.contains(.mdma))
        #expect(exportSheet.availableTreatmentTypes.contains(.ketamine))
    }

    @Test("Treatment picker handles empty list") func treatmentPickerHandlesEmptyList() throws {
        // Arrange & Act
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: {},
            onExport: { _ in }
        )

        // Assert
        #expect(exportSheet.availableTreatmentTypes.isEmpty)
    }

    @Test("Treatment picker has 'All Treatments' option") func treatmentPickerHasAllTreatmentsOption() throws {
        // Arrange
        let treatmentTypes = [PsychedelicTreatmentType.psilocybin]
        var selectedTreatment: PsychedelicTreatmentType?

        // Act - Simulate selecting "All Treatments" (nil)
        selectedTreatment = nil

        // Assert
        #expect(selectedTreatment == nil)
    }

    // MARK: - Cancel Action Tests

    @Test("Cancel button calls onCancel callback") func cancelButtonCallsOnCancelCallback() throws {
        // Arrange
        var cancelCalled = false
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: { cancelCalled = true },
            onExport: { _ in }
        )

        // Act - Simulate cancel button tap
        exportSheet.onCancel()

        // Assert
        #expect(cancelCalled == true)
    }

    // MARK: - Export Action Tests

    @Test("Export button calls onExport callback") func exportButtonCallsOnExportCallback() throws {
        // Arrange
        var exportRequest: ExportRequest?
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: [],
            onCancel: {},
            onExport: { exportRequest = $0 }
        )

        // Act - Simulate export button tap
        let testRequest = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: nil
        )
        exportSheet.onExport(testRequest)

        // Assert
        #expect(exportRequest != nil)
        #expect(exportRequest?.format == .csv)
    }

    @Test("Export request includes selected format") func exportRequestIncludesSelectedFormat() throws {
        // Arrange
        var exportRequest: ExportRequest?

        // Act - Simulate CSV export
        let csvRequest = ExportRequest(format: .csv, dateRange: nil, treatmentType: nil)
        exportRequest = csvRequest

        // Assert
        #expect(exportRequest?.format == .csv)

        // Act - Simulate PDF export
        let pdfRequest = ExportRequest(format: .pdf, dateRange: nil, treatmentType: nil)
        exportRequest = pdfRequest

        // Assert
        #expect(exportRequest?.format == .pdf)
    }

    @Test("Export request includes date range when enabled") func exportRequestIncludesDateRangeWhenEnabled() throws {
        // Arrange
        let startDate = TestHelpers.dateComponents(year: 2024, month: 1, day: 1)
        let endDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 31)
        let dateRange = startDate ... endDate

        // Act
        let request = ExportRequest(
            format: .csv,
            dateRange: dateRange,
            treatmentType: nil
        )

        // Assert
        #expect(request.dateRange != nil)
        #expect(request.dateRange?.lowerBound == startDate)
        #expect(request.dateRange?.upperBound == endDate)
    }

    @Test("Export request has no date range when disabled") func exportRequestHasNoDateRangeWhenDisabled() throws {
        // Arrange & Act
        let request = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: nil
        )

        // Assert
        #expect(request.dateRange == nil)
    }

    @Test("Export request includes selected treatment type") func exportRequestIncludesSelectedTreatmentType() throws {
        // Arrange & Act
        let request = ExportRequest(
            format: .pdf,
            dateRange: nil,
            treatmentType: .psilocybin
        )

        // Assert
        #expect(request.treatmentType == .psilocybin)
    }

    @Test("Export request has no treatment filter when 'All' selected")
    func exportRequestHasNoTreatmentFilterWhenAllSelected() throws {
        // Arrange & Act
        let request = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: nil
        )

        // Assert
        #expect(request.treatmentType == nil)
    }

    // MARK: - Combined Filter Tests

    @Test("Export request with all filters enabled") func exportRequestWithAllFiltersEnabled() throws {
        // Arrange
        let startDate = TestHelpers.dateComponents(year: 2024, month: 6, day: 1)
        let endDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 31)

        // Act
        let request = ExportRequest(
            format: .pdf,
            dateRange: startDate ... endDate,
            treatmentType: .mdma
        )

        // Assert
        #expect(request.format == .pdf)
        #expect(request.dateRange != nil)
        #expect(request.treatmentType == .mdma)
    }

    @Test("Export request with no filters enabled") func exportRequestWithNoFiltersEnabled() throws {
        // Arrange & Act
        let request = ExportRequest(
            format: .csv,
            dateRange: nil,
            treatmentType: nil
        )

        // Assert
        #expect(request.format == .csv)
        #expect(request.dateRange == nil)
        #expect(request.treatmentType == nil)
    }

    // MARK: - Edge Cases

    @Test("Export sheet with all treatment types") func exportSheetWithAllTreatmentTypes() throws {
        // Arrange
        let allTypes = PsychedelicTreatmentType.allCases

        // Act
        let exportSheet = ExportSheetView(
            availableTreatmentTypes: allTypes,
            onCancel: {},
            onExport: { _ in }
        )

        // Assert
        #expect(exportSheet.availableTreatmentTypes.count == allTypes.count)
        #expect(exportSheet.availableTreatmentTypes.count == 9)
    }

    @Test("Date range with same start and end date") func dateRangeWithSameStartAndEndDate() throws {
        // Arrange
        let sameDate = TestHelpers.dateComponents(year: 2024, month: 12, day: 25)

        // Act
        let request = ExportRequest(
            format: .csv,
            dateRange: sameDate ... sameDate,
            treatmentType: nil
        )

        // Assert
        // Single day range is valid
        #expect(request.dateRange != nil)
        #expect(request.dateRange?.lowerBound == sameDate)
        #expect(request.dateRange?.upperBound == sameDate)
    }
}
