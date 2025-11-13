import XCTest

final class AfterflowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Clean up code
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Basic test to ensure app launches without crashing
        XCTAssertTrue(app.exists)
    }
}