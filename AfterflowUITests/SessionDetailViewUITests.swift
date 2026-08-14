import XCTest

@MainActor
final class SessionDetailViewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testEditingReflectionPersists() {
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

        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 2), "Detail view should appear")

        app.buttons["Edit"].tap()

        guard let reflectionEditor = app.waitForTextInput("reflectionEditor") else {
            XCTFail("Reflection editor should appear on edit screen")
            return
        }
        reflectionEditor.tap()
        reflectionEditor.typeText("Gentle integration notes for testing.")

        let doneButton = app.navigationBars.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2), "Done button should exist")
        doneButton.tap()

        XCTAssertFalse(doneButton.waitForExistence(timeout: 3))

        // The detail screen is a non-lazy ScrollView, so off-screen content is
        // still present in the accessibility tree — no scrolling needed.
        let reflectionText = app.staticTexts["Gentle integration notes for testing."]
        XCTAssertTrue(reflectionText.waitForExistence(timeout: 5), "Reflection should appear on detail view")
    }

    func testNeedsReflectionReminderMetadataVisible() {
        let app = self.makeApp()
        app.launch()

        let intention = "Needs Reflection Reminder"
        self.createSession(in: app, intention: intention, reminderChoice: "In 3 hours")

        let list = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.tables.firstMatch
        let sessionCell = app.cells.containing(.staticText, identifier: intention).firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 3))
        list.scrollTo(element: sessionCell)
        sessionCell.waitForHittable()

        let reminderBadge = sessionCell.staticTexts["needsReflectionReminderLabel"]
        XCTAssertTrue(reminderBadge.waitForExistence(timeout: 4))

        sessionCell.forceTap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["detailReminderLabel"].waitForExistence(timeout: 4))
    }

    private func createSession(
        in app: XCUIApplication,
        intention: String,
        reminderChoice: String = "None"
    ) {
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

        if app.buttons["saveDraftButton"].waitForExistence(timeout: 2) {
            app.buttons["saveDraftButton"].tap()
        } else {
            app.navigationBars.buttons["Save"].tap()
        }
        if app.buttons[reminderChoice].waitForExistence(timeout: 2) {
            app.buttons[reminderChoice].tap()
        }

        let rootAddButton = app.buttons["addSessionButton"]
        XCTAssertTrue(rootAddButton.waitForExistence(timeout: 5), "Main list should reappear after saving")
    }
}
