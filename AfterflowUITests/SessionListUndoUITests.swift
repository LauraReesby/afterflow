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
        XCTAssertTrue(undoButton.waitForExistence(timeout: 4), "Undo banner should appear")
        undoButton.tap()

        XCTAssertTrue(cell.waitForExistence(timeout: 6), "Session should reappear after undo")
    }

    private func createSession(in app: XCUIApplication, intention: String) {
        let addSessionButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addSessionButton.waitForExistence(timeout: 5))
        addSessionButton.tap()

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }
        intentionField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        intentionField.typeText(intention)

        app.navigationBars["New Session"].buttons["Save"].tap()
        if app.buttons["None"].waitForExistence(timeout: 1) {
            app.buttons["None"].tap()
        }
        let rootAddButton = app.buttons["addSessionButton"]
        XCTAssertTrue(rootAddButton.waitForExistence(timeout: 5), "Main list should return after saving")
        rootAddButton.waitForHittable()
        let list = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.tables.firstMatch
        let cell = app.cells.containing(.staticText, identifier: intention).firstMatch
        if list.exists {
            list.scrollTo(element: cell)
        }
    }
}
