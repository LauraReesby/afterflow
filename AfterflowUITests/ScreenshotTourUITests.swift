import XCTest

@MainActor
final class ScreenshotTourUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testScreenshotTour() throws {
        let app = self.makeApp()
        app.launch()

        let addButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 8), "Sessions list should load with seed data")
        self.attach(app, name: "01-sessions-list")

        self.tapByLabel(app, "Search sessions")
        let searchField = app.textFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 4), "Search field should appear")
        searchField.tap()
        searchField.typeText("Music")
        let returnKey = app.keyboards.buttons["Return"]
        if returnKey.waitForExistence(timeout: 2) {
            returnKey.tap()
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.6))
        self.attach(app, name: "02-search")

        let clearSearch = app.buttons.matching(NSPredicate(format: "label == %@", "Clear search")).firstMatch
        if clearSearch.waitForExistence(timeout: 1) {
            clearSearch.tap()
        }
        self.tapByLabel(app, "Done")
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))

        self.tapByLabel(app, "Calendar")
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))
        self.attach(app, name: "03-calendar")

        self.tapByLabel(app, "List")
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))

        let list = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.tables.firstMatch
        let sessionCell = app.cells.containing(.staticText, identifier: "Tier1 Music Session").firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 4), "Seeded session row should exist")
        list.scrollTo(element: sessionCell)
        sessionCell.waitForHittable()
        sessionCell.forceTap()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 4), "Detail view should appear")
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        self.attach(app, name: "04-session-detail")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(addButton.waitForExistence(timeout: 4), "Should return to sessions list")

        addButton.tap()
        XCTAssertTrue(app.waitForTextInput("intentionField") != nil, "New session form should appear")
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        self.attach(app, name: "05-new-session-form")
    }

    private func tapByLabel(_ app: XCUIApplication, _ label: String) {
        let byIdentifier = app.buttons[label]
        if byIdentifier.waitForExistence(timeout: 3) {
            byIdentifier.tap()
            return
        }
        let byLabel = app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
        XCTAssertTrue(byLabel.waitForExistence(timeout: 3), "Button with label '\(label)' should exist")
        byLabel.tap()
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        self.add(attachment)
    }
}
