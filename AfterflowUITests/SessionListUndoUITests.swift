import XCTest

@MainActor
final class SessionListUndoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDeleteAndUndoFlow() throws {
        let app = self.makeApp()
        app.launch()

        let intention = "Undo Flow"
        self.createSession(in: app, intention: intention)

        let cell = app.cells.containing(.staticText, identifier: intention).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 3), "Session cell should exist")
        cell.waitForHittable()

        cell.swipeLeft()
        if app.buttons["Delete"].waitForExistence(timeout: 2) {
            app.buttons["Delete"].tap()
        }

        let undoButton = app.buttons["undoBannerAction"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 2), "Undo banner should appear")
        undoButton.tap()

        XCTAssertTrue(cell.waitForExistence(timeout: 3), "Session should reappear after undo")
    }

    // MARK: - Helpers

    private func createSession(in app: XCUIApplication, intention: String) {
        let addSessionButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addSessionButton.waitForExistence(timeout: 5))
        addSessionButton.tap()

        let dosageField = app.textFields["dosageField"]
        XCTAssertTrue(dosageField.waitForExistence(timeout: 3))
        dosageField.tap()
        dosageField.typeText("1g")
        if app.keyboards.buttons["Next"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Next"].tap()
        }

        let intentionField = app.textFields["intentionField"]
        XCTAssertTrue(intentionField.waitForExistence(timeout: 3))
        intentionField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        intentionField.typeText(intention)

        app.navigationBars["New Session"].buttons["Save"].tap()
        if app.buttons["No thanks"].waitForExistence(timeout: 1) {
            app.buttons["No thanks"].tap()
        }
        XCTAssertFalse(app.navigationBars["New Session"].waitForExistence(timeout: 1))
    }
}
