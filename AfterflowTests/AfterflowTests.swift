import Testing
import Foundation
@testable import Afterflow

struct AfterflowTests {
    
    @Test("App basic functionality")
    func testBasicApp() async throws {
        // Basic test to ensure the app module imports correctly
        let session = TherapeuticSession()
        #expect(session.id != UUID()) // Should have a unique ID
    }
}