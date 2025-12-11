import XCTest

@MainActor
final class AfterflowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Clean up code
    }

    @MainActor func testAppLaunches() throws {
        let app = self.makeApp()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    @MainActor func testCreateAndOpenSessionFromList() throws {
        let app = self.makeApp()
        app.launch()

        let addSessionButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addSessionButton.waitForExistence(timeout: 5))
        addSessionButton.tap()

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }
        intentionField.tap()
        intentionField.typeText("UI nav smoke test")
        app.navigationBars.buttons["Save"].tap()

        if app.buttons["In 3 hours"].waitForExistence(timeout: 1) {
            app.buttons["In 3 hours"].tap()
        }

        let sessionCell = app.cells.containing(.staticText, identifier: "UI nav smoke test").firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 5))
        sessionCell.forceTap()

        XCTAssertTrue(
            app.navigationBars["Session"].waitForExistence(timeout: 3),
            "Detail view should show after tapping session"
        )
    }
}
