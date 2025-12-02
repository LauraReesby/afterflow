import XCTest

extension XCTestCase {
    func makeApp(arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        var launchArguments = ["-ui-testing"]
        launchArguments.append(contentsOf: arguments)
        app.launchArguments = launchArguments
        return app
    }
}

extension XCUIApplication {
    func waitForTextInput(_ identifier: String, timeout: TimeInterval = 5) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)

        func locateElement() -> XCUIElement? {
            let match = self.descendants(matching: .any).matching(identifier: identifier).firstMatch
            return match.exists ? match : nil
        }

        while Date() < deadline {
            if let element = locateElement() {
                if element.isHittable {
                    return element
                }

                for container in self.scrollContainers {
                    container.scrollTo(element: element)
                    if element.isHittable { break }
                }

                if element.isHittable {
                    return element
                }
            }

            for container in self.scrollContainers {
                container.swipeUp()
                RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return nil
    }

    private var scrollContainers: [XCUIElement] {
        var containers: [XCUIElement] = []
        containers.append(contentsOf: self.collectionViews.allElementsBoundByIndex)
        containers.append(contentsOf: self.tables.allElementsBoundByIndex)
        containers.append(contentsOf: self.scrollViews.allElementsBoundByIndex)
        return containers.filter(\.exists)
    }
}

extension XCUIElement {
    func waitForHittable(timeout: TimeInterval = 3) {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        _ = XCTWaiter.wait(for: [expectation], timeout: timeout)
    }

    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }

    func scrollTo(element: XCUIElement, maxSwipes: Int = 20) {
        var swipes = 0
        while !element.isHittable, swipes < maxSwipes {
            self.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            swipes += 1
        }
    }

    func forceTap() {
        if self.isHittable {
            self.tap()
            return
        }
        
        // Wait a bit for layout to settle
        if !self.exists {
            return
        }
        
        // Give the view time to get a valid frame
        let deadline = Date().addingTimeInterval(2)
        while Date() < deadline {
            if self.isHittable {
                self.tap()
                return
            }
            
            let frame = self.frame
            // Check if frame is valid (not negative, not NaN, not infinite)
            if frame.width > 0, frame.height > 0,
               frame.width.isFinite, frame.height.isFinite,
               frame.origin.x.isFinite, frame.origin.y.isFinite {
                let center = frame.integral.center
                let coord = XCUIApplication().coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: center.x, dy: center.y))
                coord.tap()
                return
            }
            
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
    }
}

private extension CGRect {
    var center: CGPoint { CGPoint(x: midX, y: midY) }
}
