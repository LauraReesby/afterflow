import XCTest

final class SessionMoodRatingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMoodSlidersExposeVoiceOverFriendlyLabels() throws {
        let app = self.makeApp()
        self.presentSessionForm(app)

        self.revealMoodSection(in: app)

        let beforeSlider = self.sliderElement("moodBeforeSlider", in: app)
        XCTAssertTrue(beforeSlider.waitForExistence(timeout: 3), "Before mood slider should exist")
        XCTAssertEqual(beforeSlider.label, "Before Session mood rating")

        let afterSlider = self.sliderElement("moodAfterSlider", in: app)
        XCTAssertTrue(afterSlider.waitForExistence(timeout: 3), "After mood slider should exist")
        XCTAssertEqual(afterSlider.label, "After Session mood rating")

        if beforeSlider.exists {
            beforeSlider.adjust(toNormalizedSliderPosition: 0.8)
        }

        if afterSlider.exists {
            afterSlider.adjust(toNormalizedSliderPosition: 0.2)
        }
    }

    func testMoodSectionSupportsDynamicTypeXXXL() throws {
        let app = self.makeApp(arguments: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXXXL"])
        self.presentSessionForm(app)

        self.revealMoodSection(in: app)

        let beforeSlider = self.sliderElement("moodBeforeSlider", in: app)
        XCTAssertTrue(beforeSlider.waitForExistence(timeout: 3), "Before mood slider should remain visible")

        let afterSlider = self.sliderElement("moodAfterSlider", in: app)
        XCTAssertTrue(afterSlider.waitForExistence(timeout: 3), "After mood slider should remain visible")

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "MoodSection-XXXL"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Helpers

    @discardableResult private func presentSessionForm(_ app: XCUIApplication) -> XCUIElement {
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

    private func revealMoodSection(in app: XCUIApplication) {
        let container: XCUIElement = if app.collectionViews.firstMatch.exists {
            app.collectionViews.firstMatch
        } else if app.tables.firstMatch.exists {
            app.tables.firstMatch
        } else {
            app.scrollViews.firstMatch
        }

        var attempts = 0
        while !(app.sliders["moodBeforeSlider"].exists && app.sliders["moodAfterSlider"].exists), attempts < 30 {
            container.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            attempts += 1
        }
    }

    private func sliderElement(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.sliders[identifier]
    }
}
