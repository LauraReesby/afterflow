import XCTest

@MainActor
final class ExportFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testExportSheetAndProgress() throws {
        let app = self.makeApp(arguments: ["-ui-testing"])
        app.launch()

        let exportButton = app.buttons["exportSessionsButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 5), "Export button should exist")
        exportButton.tap()

        let formatPicker = app.segmentedControls["exportFormatPicker"]
        XCTAssertTrue(formatPicker.waitForExistence(timeout: 2))
        formatPicker.buttons["CSV"].tap()

        let exportNavButton = app.navigationBars.buttons["Export"]
        XCTAssertTrue(exportNavButton.waitForExistence(timeout: 2))
        exportNavButton.tap()

        let progress = app.otherElements["exportProgressView"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5), "Progress overlay should appear")
    }
}
