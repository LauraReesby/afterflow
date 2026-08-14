import XCTest

@MainActor
final class ReflectionFlowUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// The flagship journey: nudge → prompt chip → type → Save → session completes.
    func testReflectionSaveCompletesSession() throws {
        let app = self.makeApp()
        app.launch()

        let nudgeButton = app.buttons["reflectNudgeButton"]
        XCTAssertTrue(nudgeButton.waitForExistence(timeout: 8), "Reflect nudge should be visible with seeded data")
        nudgeButton.tap()

        XCTAssertTrue(
            app.staticTexts["How has it settled?"].waitForExistence(timeout: 4),
            "Reflection screen should appear"
        )

        let saveButton = app.buttons["saveReflectionButton"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        XCTAssertFalse(saveButton.isEnabled, "Save should be disabled until text is entered")

        // Prompt chips are additive: tapping seeds the field with "<label> — ".
        let promptChip = app.buttons["What emerged"]
        XCTAssertTrue(promptChip.waitForExistence(timeout: 3), "Prompt chips should be visible")
        promptChip.tap()

        let editor = app.textViews["reflectionEntryEditor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 3), "Reflection editor should exist")
        editor.tap()
        editor.typeText("felt grounded and clear.")

        XCTAssertTrue(saveButton.isEnabled, "Save should enable once text exists")
        saveButton.tap()

        // Saving pops back to the session detail, now complete.
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 5), "Should land on session detail")
        XCTAssertTrue(
            app.staticTexts["Complete"].waitForExistence(timeout: 4),
            "Session should be marked Complete after saving a reflection"
        )

        let savedText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "felt grounded and clear.")
        ).firstMatch
        XCTAssertTrue(savedText.waitForExistence(timeout: 4), "Saved reflection text should appear on the detail")
    }
}
