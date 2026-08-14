import XCTest

@MainActor
final class ExportFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExportSheetAndProgress() {
        let app = self.makeApp(arguments: ["-ui-testing"])
        app.launch()

        let menuButton = app.buttons["overflowMenuButton"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "Overflow menu button should exist")
        menuButton.tap()

        let exportButton = app.buttons["Export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 2), "Export menu item should exist")
        exportButton.tap()

        let formatPicker = app.segmentedControls["exportFormatPicker"]
        XCTAssertTrue(formatPicker.waitForExistence(timeout: 2))
        formatPicker.buttons["CSV"].tap()

        let dateFilterToggle = app.switches["exportFilterToggle"]
        if dateFilterToggle.waitForExistence(timeout: 1) {
            dateFilterToggle.tap()
        }

        let treatmentPicker = app.pickers["exportTreatmentPicker"]
        if treatmentPicker.exists {
            treatmentPicker.pickerWheels.firstMatch.adjust(toPickerWheelValue: "All Treatments")
        }

        let exportNavButton = app.navigationBars.buttons["Export"]
        XCTAssertTrue(exportNavButton.waitForExistence(timeout: 2))
        exportNavButton.tap()

        // The system file exporter (Save to Files) hosts a DocumentsUI/FileProvider extension embedded
        // in-process under a different pid, as a plain UIKit UI with no accessibilityIdentifiers set —
        // only labels. So it must be queried by label across all element types, not app.sheets/app.buttons["Save"].
        let saveButton = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Save"))
            .firstMatch

        let progress = app.otherElements["exportProgressView"]
        let progressAppeared = progress.waitForExistence(timeout: 2)
        let exporterAppeared = saveButton.waitForExistence(timeout: 6)

        XCTAssertTrue(
            progressAppeared || exporterAppeared,
            "Either progress overlay should appear or file exporter should present"
        )

        if saveButton.exists {
            if !saveButton.isEnabled {
                let firstDestination = app.cells.allElementsBoundByIndex.first ?? app.cells.firstMatch
                if firstDestination.waitForExistence(timeout: 2) {
                    firstDestination.tap()
                }
            }
            if saveButton.isEnabled {
                saveButton.tap()
            }
        }
    }
}
