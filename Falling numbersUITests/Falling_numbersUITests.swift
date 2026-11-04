import XCTest

@MainActor
final class Falling_numbersUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPlayFromMenuResumesPausedRun() {
        let app = launchGame()
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "Game Screen"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        tap(app.buttons["Pause game"])
        tap(app.buttons["Main Menu"])
        tap(app.buttons["Play"])
        XCTAssertTrue(app.buttons["Pause game"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Paused"].exists)
        tap(app.buttons["Pause game"])
        tap(app.buttons["New Game"])
        XCTAssertTrue(app.buttons["Pause game"].waitForExistence(timeout: 5))
    }

    func testModeSwitchFromMenuStartsExpertRun() {
        let app = launchGame()
        tap(app.buttons["Pause game"])
        tap(app.buttons["Main Menu"])
        tap(app.buttons["Expert"])
        tap(app.buttons["Play"])
        XCTAssertTrue(app.buttons["Pause game"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Play time 0:00"].exists ||
                      app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Play time ")).firstMatch.exists)
        XCTAssertFalse(app.staticTexts["Paused"].exists)
    }

    func testResetRecordRemainsZeroAfterResume() {
        let app = launchGame()
        // The board covers the middle/lower portion of the portrait game screen.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65)).doubleTap()
        let score = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label != %@", "Score ", "Score 0")).firstMatch
        XCTAssertTrue(score.waitForExistence(timeout: 5))
        tap(app.buttons["Pause game"])
        tap(app.buttons["Settings"])
        tap(app.buttons["Reset high score"])
        tap(app.buttons["Done"])
        tap(app.buttons["Resume"])
        XCTAssertTrue(app.staticTexts["High score 0"].waitForExistence(timeout: 5))
        tap(app.buttons["Pause game"])
        XCTAssertTrue(app.staticTexts["High score 0"].exists)
    }

    func testGameLayoutFitsLandscapeAndPortrait() {
        let app = launchGame()
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft
        let pause = app.buttons["Pause game"]
        XCTAssertTrue(pause.waitForExistence(timeout: 5))
        XCTAssertTrue(pause.isHittable)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Score ")).firstMatch.isHittable)
        // Interact after rotation so XCTest waits for the interface to settle
        // before recording the screenshot (existence alone can succeed mid-rotation).
        tap(pause)
        tap(app.buttons["Resume"])
        let next = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Next piece ")).firstMatch
        XCTAssertTrue(next.isHittable)
        XCTAssertTrue(app.windows.firstMatch.frame.contains(next.frame))
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Game - Landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(pause.isHittable)
        tap(pause)
        XCTAssertTrue(app.buttons["Resume"].isHittable)
    }

    private func launchGame() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        tap(app.buttons["Play"])
        XCTAssertTrue(app.buttons["Pause game"].waitForExistence(timeout: 5))
        return app
    }

    private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
        element.tap()
    }
}
