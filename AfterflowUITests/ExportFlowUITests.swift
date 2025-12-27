import XCTest

@MainActor
final class ExportFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExportSheetAndProgress() throws {
        let app = self.makeApp(arguments: ["-ui-testing"])
        app.launch()

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 5))

        let menuPredicate =
            NSPredicate(format: "label IN {'More','ellipsis','Menu'} OR identifier IN {'More','ellipsis','Menu'}")
        var menuButton = navBar.buttons.matching(menuPredicate).firstMatch
        if !menuButton.exists {
            let candidates = navBar.buttons.allElementsBoundByIndex
            
            menuButton = candidates.last(where: { !$0.label.localizedCaseInsensitiveContains("filter") }) ?? navBar
                .buttons.element(boundBy: 0)
        }
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "Toolbar menu button should exist")
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

        let progress = app.otherElements["exportProgressView"]
        let progressAppeared = progress.waitForExistence(timeout: 2)
        let fileExporter = app.sheets.firstMatch
        let exporterAppeared = fileExporter.waitForExistence(timeout: 6) || app.buttons["Save"]
            .waitForExistence(timeout: 6)

        XCTAssertTrue(
            progressAppeared || exporterAppeared,
            "Either progress overlay should appear or file exporter should present"
        )

        if fileExporter.exists {
            let saveButton = app.buttons["Save"]
            if saveButton.waitForExistence(timeout: 2) {
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
        } else {
            
            XCTAssertTrue(fileExporter.waitForExistence(timeout: 6), "File exporter should appear for exports")
            let saveButton = app.buttons["Save"]
            if saveButton.waitForExistence(timeout: 2), saveButton.isEnabled {
                saveButton.tap()
            }
        }
    }
}
