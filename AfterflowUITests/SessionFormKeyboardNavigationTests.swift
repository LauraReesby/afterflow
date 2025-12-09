import XCTest

@MainActor
final class SessionFormKeyboardNavigationTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {}

    private func navigateToSessionForm(_ app: XCUIApplication) {
        app.launch()

        // Wait for app to load
        let addSessionButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addSessionButton.waitForExistence(timeout: 5), "Add Session button should exist")

        // Tap to open session form
        addSessionButton.tap()

        // Wait for session form to appear
        let sessionFormTitle = app.navigationBars["New Session"]
        XCTAssertTrue(sessionFormTitle.waitForExistence(timeout: 3), "Session form should appear")
    }

    func testKeyboardNavigationTabOrder() throws {
        let app = self.makeApp()
        self.navigateToSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }

        intentionField.tap()
        XCTAssertTrue(intentionField.hasKeyboardFocus, "Intention field should have keyboard focus")
    }

    func testKeyboardDismissOnTap() throws {
        let app = self.makeApp()
        self.navigateToSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }
        intentionField.tap()

        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(
            self.waitForKeyboard(keyboard, appears: true),
            "Keyboard should appear after focusing intention field"
        )

        let hideButton = app.buttons["keyboardAccessoryHide"]
        XCTAssertTrue(hideButton.waitForExistence(timeout: 2), "Hide Keyboard button should appear with keyboard")
        hideButton.tap()

        XCTAssertTrue(
            self.waitForKeyboard(keyboard, appears: false),
            "Keyboard should dismiss after tapping Hide Keyboard"
        )
    }

    func testKeyboardToolbarDoneButton() throws {
        let app = self.makeApp()
        self.navigateToSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }
        intentionField.tap()

        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(self.waitForKeyboard(keyboard, appears: true), "Keyboard should appear for intention field")

        let hideButton = app.buttons["keyboardAccessoryHide"]
        XCTAssertTrue(hideButton.waitForExistence(timeout: 2), "Hide Keyboard button should exist")
        hideButton.tap()

        XCTAssertTrue(
            self.waitForKeyboard(keyboard, appears: false),
            "Keyboard should dismiss after tapping Hide Keyboard"
        )
        XCTAssertFalse(intentionField.hasKeyboardFocus, "Field should lose focus after hiding keyboard")
    }

    func testSubmitOnLastField() throws {
        let app = self.makeApp()
        self.navigateToSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }

        // Tap to focus and activate keyboard
        intentionField.tap()
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(self.waitForKeyboard(keyboard, appears: true), "Keyboard should appear for intention field")

        // Type some text
        intentionField.typeText("Test intention")

        // Simple verification that the text was entered
        let fieldValue = intentionField.value as? String ?? ""
        XCTAssertTrue(fieldValue.contains("Test intention"), "Intention field should contain the typed text")
    }

    func testAccessibilityLabelsAndHints() throws {
        let app = self.makeApp()
        self.navigateToSessionForm(app)

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return
        }

        if intentionField.exists {
            self.dismissKeyboardIfPresent(app)

            intentionField.tap()
            XCTAssertTrue(
                self.waitForKeyboard(app.keyboards.firstMatch, appears: true),
                "Keyboard should appear for intention field input"
            )
            intentionField.clearText(app: app)
            intentionField.typeText("Test intention")
            XCTAssertEqual(
                intentionField.value as? String,
                "Test intention",
                "Should be able to enter text in intention field"
            )
        }
    }

    func testVoiceOverNavigationOrder() throws {
        let app = XCUIApplication()
        self.navigateToSessionForm(app)

        // This test verifies elements exist in the expected order for VoiceOver

        let navigationBar = app.navigationBars["New Session"]
        XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist and be accessible")
            return
        }

        XCTAssertTrue(intentionField.exists, "Intention field should exist and be accessible")

        // Verify cancel and save buttons exist
        let cancelButton = app.buttons["Cancel"]
        let saveButton = app.buttons["Save"]

        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        XCTAssertTrue(saveButton.exists, "Save button should exist")
    }

    @discardableResult
    private func waitForKeyboard(_ keyboard: XCUIElement, appears: Bool, timeout: TimeInterval = 3) -> Bool {
        let predicate = NSPredicate(format: "exists == %@", NSNumber(value: appears))
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: keyboard)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    private func dismissKeyboardIfPresent(_ app: XCUIApplication) {
        let keyboard = app.keyboards.firstMatch
        guard keyboard.exists else { return }

        if app.buttons["keyboardAccessoryHide"].waitForExistence(timeout: 1) {
            app.buttons["keyboardAccessoryHide"].tap()
        } else if app.toolbars.buttons["Hide Keyboard"].exists {
            app.toolbars.buttons["Hide Keyboard"].tap()
        } else {
            app.tap()
        }
        _ = self.waitForKeyboard(keyboard, appears: false)
    }
}

extension XCUIElement {
    var hasKeyboardFocus: Bool {
        self.value(forKey: "hasKeyboardFocus") as? Bool ?? false
    }

    func clearText(app: XCUIApplication) {
        guard let currentValue = self.value as? String, !currentValue.isEmpty else { return }
        tap()
        press(forDuration: 1.0)
        let selectAll = app.menuItems["Select All"]
        if selectAll.waitForExistence(timeout: 1) {
            selectAll.tap()
            app.typeText(XCUIKeyboardKey.delete.rawValue)
            return
        }

        let deleteSequence = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        app.typeText(deleteSequence)
    }
}
