import XCTest

@MainActor
final class MusicLinkDetailCardUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testTier1MusicLinkCardShowsMetadata() throws {
        let app = self.makeApp(arguments: ["-ui-musiclink-fixtures"])
        app.launch()

        self.openSession(named: "Tier1 Music Session", in: app)

        let card = app.otherElements["musicLinkDetailCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Lo-Fi Focus"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Spotify"].waitForExistence(timeout: 4))
    }

    func testLinkOnlyMusicLinkCardShowsFallbackTitle() throws {
        let app = self.makeApp(arguments: ["-ui-musiclink-fixtures"])
        app.launch()

        self.openSession(named: "Link Only Music Session", in: app)

        let card = app.otherElements["musicLinkDetailCard"]
        XCTAssertTrue(card.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Calm"].waitForExistence(timeout: 4))
        XCTAssertTrue(app.staticTexts["Apple Music"].waitForExistence(timeout: 4))
    }

    // MARK: - Helpers

    private func openSession(named intention: String, in app: XCUIApplication) {
        let list = app.collectionViews.firstMatch.exists ? app.collectionViews.firstMatch : app.tables.firstMatch
        let sessionCell = app.cells.containing(.staticText, identifier: intention).firstMatch
        XCTAssertTrue(sessionCell.waitForExistence(timeout: 8), "Session row should appear for \(intention)")
        list.scrollTo(element: sessionCell)
        sessionCell.waitForHittable()
        sessionCell.forceTap()
        XCTAssertTrue(app.navigationBars["Session"].waitForExistence(timeout: 5))
    }
}
