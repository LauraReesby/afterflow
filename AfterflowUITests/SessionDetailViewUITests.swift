import XCTest

@MainActor
final class SessionDetailViewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEditingReflectionPersists() throws {
        let app = self.makeApp()
        app.launch()

        let intention = "Reflection Flow"
        self.createSession(in: app, intention: intention)

        let list = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.tables.firstMatch
        let sessionCell = app.cells.containing(.staticText, identifier: intention).firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 3), "Session row should show the intention text")
        list.scrollTo(element: sessionCell)
        sessionCell.waitForHittable()
        sessionCell.forceTap()

        XCTAssertTrue(app.navigationBars["Session Details"].waitForExistence(timeout: 2), "Detail view should appear")

        let reflectionEditor = app.textViews["reflectionEditor"]
        if !reflectionEditor.waitForExistence(timeout: 3) {
            list.scrollTo(element: reflectionEditor)
        }
        XCTAssertTrue(reflectionEditor.waitForExistence(timeout: 3), "Reflection editor should appear")
        reflectionEditor.tap()
        reflectionEditor.typeText("Gentle integration notes for testing.")

        let saveButton = app.navigationBars.buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist on detail view")
        saveButton.tap()

        XCTAssertFalse(app.navigationBars["Session Details"].waitForExistence(timeout: 1))

        // Reopen to ensure persistence
        let reopenedCell = app.cells.containing(.staticText, identifier: intention).firstMatch
        XCTAssertTrue(reopenedCell.waitForExistence(timeout: 2))
        list.scrollTo(element: reopenedCell)
        reopenedCell.waitForHittable()
        reopenedCell.forceTap()
        XCTAssertTrue(reflectionEditor.waitForExistence(timeout: 2))
        XCTAssertTrue((reflectionEditor.value as? String)?.contains("Gentle integration notes") == true)
    }

    // MARK: - Helpers

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
    }
}
