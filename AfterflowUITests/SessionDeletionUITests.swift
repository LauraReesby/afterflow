import XCTest

@MainActor
final class SessionDeletionUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testContextMenuDeleteRemovesSession() {
        let app = self.makeApp()
        app.launch()

        let targetIntention = "Link Only Music Session"
        let sessionCell = app.cells.containing(.staticText, identifier: targetIntention).firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 8), "Seeded session row should exist")

        sessionCell.press(forDuration: 1.2)

        let deleteMenuItem = app.buttons["Delete"]
        XCTAssertTrue(deleteMenuItem.waitForExistence(timeout: 4), "Context menu Delete should appear")
        deleteMenuItem.tap()

        let confirmButton = app.buttons.matching(identifier: "confirmDeleteButton").firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 4), "Delete confirmation alert should appear")
        confirmButton.tap()

        XCTAssertTrue(
            sessionCell.waitForNonExistence(timeout: 5),
            "Deleted session's row should disappear from the list"
        )
    }

    func testCancelDeleteKeepsSession() {
        let app = self.makeApp()
        app.launch()

        let targetIntention = "Tier1 Music Session"
        let sessionCell = app.cells.containing(.staticText, identifier: targetIntention).firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 8), "Seeded session row should exist")

        sessionCell.press(forDuration: 1.2)

        let deleteMenuItem = app.buttons["Delete"]
        XCTAssertTrue(deleteMenuItem.waitForExistence(timeout: 4), "Context menu Delete should appear")
        deleteMenuItem.tap()

        let cancelButton = app.buttons.matching(identifier: "cancelDeleteButton").firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 4), "Delete confirmation alert should appear")
        cancelButton.tap()

        XCTAssertTrue(
            sessionCell.waitForExistence(timeout: 4),
            "Cancelling the confirmation should keep the session"
        )
    }
}
