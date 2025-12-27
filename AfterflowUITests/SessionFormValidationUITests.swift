import XCTest

@MainActor
final class SessionFormValidationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSaveButtonEnablesAfterValidInput() throws {
        let app = self.makeApp()
        self.presentSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }
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
        if app.buttons["In 3 hours"].waitForExistence(timeout: 1) {
            app.buttons["In 3 hours"].tap()
        }
        XCTAssertFalse(app.navigationBars["New Session"].waitForExistence(timeout: 1))

        let sessionCell = app.cells.containing(.staticText, identifier: "Grounding intention").firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 3), "Session should appear in list")
        sessionCell.waitForHittable()
    }

    func testAttachAndRemoveMusicLink() throws {
        let app = self.makeApp()
        self.presentSessionForm(app)

        let musicField = app.textFields["musicLinkField"]
        XCTAssertTrue(musicField.waitForExistence(timeout: 2), "Playlist link field should exist")
        musicField.tap()
        musicField.typeText("https://music.apple.com/us/playlist/calm/pl.u-123")

        let preview = app.otherElements["musicLinkPreview"].exists
            ? app.otherElements["musicLinkPreview"]
            : app.otherElements["musicLinkRawPreview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 8), "Preview should appear after entering a link")

        let removeButton = app.buttons["removeMusicLinkButton"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 2))
        removeButton.tap()

        XCTAssertFalse(preview.waitForExistence(timeout: 1), "Preview should disappear after removing link")
    }

    func testInlineValidationOutlineUpdates() throws {
        let app = self.makeApp()
        self.presentSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }

        XCTAssertTrue(intentionField.waitForExistence(timeout: 2))

        intentionField.tap()
        intentionField.typeText("Grounding intention")

        let saveButton = app.navigationBars["New Session"].buttons["Save"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 2), "Save button should exist")
        let enabledPredicate = NSPredicate(format: "isEnabled == true")
        let enabledExpectation = XCTNSPredicateExpectation(predicate: enabledPredicate, object: saveButton)
        XCTAssertEqual(
            XCTWaiter.wait(for: [enabledExpectation], timeout: 3),
            .completed,
            "Save should enable after valid input"
        )
    }

    private func presentSessionForm(_ app: XCUIApplication) {
        app.launch()

        let addSessionButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addSessionButton.waitForExistence(timeout: 5), "Add Session button should appear on launch")
        addSessionButton.tap()

        let formNavBar = app.navigationBars["New Session"]
        XCTAssertTrue(formNavBar.waitForExistence(timeout: 3), "Session form should appear")
    }
}
