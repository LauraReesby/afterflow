import XCTest

@MainActor
final class SessionFormValidationUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSaveButtonEnablesAfterValidInput() {
        let app = self.makeApp()
        self.presentSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }
        intentionField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        intentionField.typeText("Grounding intention")

        let saveButton = app.navigationBars["New session"].buttons["Save"]
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
        XCTAssertFalse(app.navigationBars["New session"].waitForExistence(timeout: 1))

        let sessionCell = app.cells.containing(.staticText, identifier: "Grounding intention").firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 3), "Session should appear in list")
        sessionCell.waitForHittable()
    }

    func testAttachAndRemoveMusicLink() {
        let app = self.makeApp()
        self.presentSessionForm(app)

        // The form is a lazy List; the music row below the fold isn't in the
        // accessibility tree until scrolled into view.
        let form = app.collectionViews.firstMatch
        let musicField = app.textFields["musicLinkField"]
        if !musicField.waitForExistence(timeout: 2) {
            form.scrollTo(element: musicField)
        }
        XCTAssertTrue(musicField.waitForExistence(timeout: 2), "Playlist link field should exist")
        musicField.tap()
        musicField.typeText("https://music.apple.com/us/playlist/calm/pl.u-123")

        let preview = app.descendants(matching: .any)
            .matching(NSPredicate(
                format: "identifier == %@ OR identifier == %@",
                "musicLinkPreview",
                "musicLinkRawPreview"
            ))
            .firstMatch
        if !preview.waitForExistence(timeout: 8) {
            form.scrollTo(element: preview)
        }
        XCTAssertTrue(preview.waitForExistence(timeout: 2), "Preview should appear after entering a link")

        let removeButton = app.buttons["removeMusicLinkButton"]
        XCTAssertTrue(removeButton.waitForExistence(timeout: 2))
        removeButton.tap()

        XCTAssertFalse(preview.waitForExistence(timeout: 1), "Preview should disappear after removing link")
    }

    func testInlineValidationOutlineUpdates() {
        let app = self.makeApp()
        self.presentSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }

        XCTAssertTrue(intentionField.waitForExistence(timeout: 2))

        intentionField.tap()
        intentionField.typeText("Grounding intention")

        let saveButton = app.navigationBars["New session"].buttons["Save"]
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

        let formNavBar = app.navigationBars["New session"]
        XCTAssertTrue(formNavBar.waitForExistence(timeout: 3), "Session form should appear")
    }
}
