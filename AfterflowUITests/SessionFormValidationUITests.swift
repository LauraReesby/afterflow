import XCTest

@MainActor
final class SessionFormValidationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSaveButtonEnablesAfterValidInput() throws {
        let app = self.makeApp()
        self.presentSessionForm(app)

        let dosageField = app.textFields["dosageField"]
        XCTAssertTrue(dosageField.waitForExistence(timeout: 2))
        dosageField.tap()
        dosageField.typeText("2g")
        if app.keyboards.buttons["Next"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["Next"].tap()
        }

        let intentionField = app.textFields["intentionField"]
        XCTAssertTrue(intentionField.waitForExistence(timeout: 2))
        intentionField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        intentionField.typeText("Grounding intention")

        let saveButton = app.navigationBars["New Session"].buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")

        let enabledPredicate = NSPredicate(format: "isEnabled == true")
        let enabledExpectation = XCTNSPredicateExpectation(predicate: enabledPredicate, object: saveButton)
        XCTAssertEqual(
            XCTWaiter.wait(for: [enabledExpectation], timeout: 3),
            .completed,
            "Save button should enable once required fields are valid"
        )

        saveButton.tap()
        if app.buttons["In 1 hour"].waitForExistence(timeout: 1) {
            app.buttons["In 1 hour"].tap()
        }
        XCTAssertFalse(app.navigationBars["New Session"].waitForExistence(timeout: 1))

        let sessionCell = app.cells.containing(.staticText, identifier: "Grounding intention").firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 3), "Session should appear in list")
        sessionCell.waitForHittable()
    }

    // MARK: - Helpers

    private func presentSessionForm(_ app: XCUIApplication) {
        app.launch()

        let addSessionButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addSessionButton.waitForExistence(timeout: 5), "Add Session button should appear on launch")
        addSessionButton.tap()

        let formNavBar = app.navigationBars["New Session"]
        XCTAssertTrue(formNavBar.waitForExistence(timeout: 3), "Session form should appear")
    }
}
