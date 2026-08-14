import XCTest

final class SessionMoodRatingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMoodSlidersExposeVoiceOverFriendlyLabels() {
        let app = self.makeApp()
        self.presentSessionForm(app)

        self.revealMoodSection(in: app)

        let beforeBars = self.moodElement("moodBeforeSlider", in: app)
        XCTAssertTrue(beforeBars.waitForExistence(timeout: 3), "Before mood control should exist")
        XCTAssertEqual(beforeBars.label, "Before Session mood rating")

        XCTAssertFalse(
            self.moodElement("moodAfterSlider", in: app).exists,
            "After mood control should be absent at creation"
        )

        if beforeBars.isHittable {
            beforeBars.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)).tap()
        }
    }

    func testMoodSectionSupportsDynamicTypeXXXL() {
        let app = self.makeApp(arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"])
        self.presentSessionForm(app)

        self.revealMoodSection(in: app)

        let beforeBars = self.moodElement("moodBeforeSlider", in: app)
        XCTAssertTrue(beforeBars.waitForExistence(timeout: 3), "Before mood control should remain visible")

        XCTAssertFalse(
            self.moodElement("moodAfterSlider", in: app).exists,
            "After mood control should not appear in creation form"
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "MoodSection-XXXL"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @discardableResult private func presentSessionForm(_ app: XCUIApplication) -> XCUIElement {
        app.launch()

        let addSessionButton = app.buttons["addSessionButton"]
        XCTAssertTrue(addSessionButton.waitForExistence(timeout: 5), "Add Session button should appear on launch")
        addSessionButton.tap()

        let formNavBar = app.navigationBars["New session"]
        XCTAssertTrue(formNavBar.waitForExistence(timeout: 3), "Session form should appear")

        guard let intentionField = app.waitForTextInput("intentionField") else {
            XCTFail("Intention field should exist")
            return app.textViews["intentionField"]
        }
        return intentionField
    }

    private func revealMoodSection(in app: XCUIApplication) {
        let container: XCUIElement = if app.collectionViews.firstMatch.exists {
            app.collectionViews.firstMatch
        } else if app.tables.firstMatch.exists {
            app.tables.firstMatch
        } else {
            app.scrollViews.firstMatch
        }

        var attempts = 0
        while !self.moodElement("moodBeforeSlider", in: app).exists, attempts < 40 {
            container.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            attempts += 1
        }
    }

    private func moodElement(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", identifier))
            .firstMatch
    }
}
