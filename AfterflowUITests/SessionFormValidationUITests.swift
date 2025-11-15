import XCTest

final class SessionFormValidationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws { }

    func testSaveButtonEnablesAfterValidInput() throws {
        let app = XCUIApplication()
        let intentionField = presentSessionForm(app)

        let saveButton = app.navigationBars["New Session"].buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")

        intentionField.tap()
        intentionField.typeText("Grounding intention")

        let enabledPredicate = NSPredicate(format: "isEnabled == true")
        let enabledExpectation = XCTNSPredicateExpectation(predicate: enabledPredicate, object: saveButton)
        XCTAssertEqual(XCTWaiter.wait(for: [enabledExpectation], timeout: 3), .completed, "Save button should enable once required fields are valid")
    }

    // MARK: - Helpers

    @discardableResult
    private func presentSessionForm(_ app: XCUIApplication) -> XCUIElement {
        app.launch()

        let addSessionButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addSessionButton.waitForExistence(timeout: 5), "Add Session button should appear on launch")
        addSessionButton.tap()

        let formNavBar = app.navigationBars["New Session"]
        XCTAssertTrue(formNavBar.waitForExistence(timeout: 3), "Session form should appear")

        let intentionField = app.textFields["intentionField"]
        XCTAssertTrue(intentionField.waitForExistence(timeout: 2), "Intention field should exist")
        return intentionField
    }

}
