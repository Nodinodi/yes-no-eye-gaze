import XCTest

/// Taps through the app on an iPad simulator and keeps screenshots.
/// (A simulator has no camera: Eye Tracking itself can only be tried on a real iPad.)
final class YesNoUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func walkThrough(orientation: UIDeviceOrientation, tag: String) {
        XCUIDevice.shared.orientation = orientation
        let app = XCUIApplication()
        app.launch()

        let talk = app.buttons["Talk"]
        XCTAssertTrue(talk.waitForExistence(timeout: 15), "TALK screen appears")
        shot("\(tag)-1-talk-screen")

        talk.tap()
        let yes = app.buttons["YES"]
        XCTAssertTrue(yes.waitForExistence(timeout: 3), "TALK opens YES/NO")
        XCTAssertTrue(app.buttons["NO"].exists)
        XCTAssertTrue(app.buttons["Exit"].exists)
        shot("\(tag)-2-yes-no-waiting")

        sleep(4) // past the 3-second wait
        shot("\(tag)-3-yes-no-ready")

        yes.tap()
        sleep(1)
        shot("\(tag)-4-yes-chosen")
        XCTAssertTrue(app.buttons["YES"].exists, "stays on YES/NO after an answer")
        XCTAssertFalse(app.buttons["Talk"].exists)

        app.buttons["Exit"].tap()
        XCTAssertTrue(app.buttons["Talk"].waitForExistence(timeout: 3), "EXIT goes back to TALK")
        app.terminate()
    }

    func testLandscape() {
        walkThrough(orientation: .landscapeLeft, tag: "landscape")
    }

    func testPortrait() {
        walkThrough(orientation: .portrait, tag: "portrait")
    }

    func testSettingsOpensOnlyWhenHeld() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
        let settings = app.buttons["Settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 15), "Settings button on the TALK screen")
        XCTAssertFalse(app.buttons["Training"].exists, "TRAINING button is hidden until the family switches it on")
        shot("settings-1-talk-with-settings")

        settings.tap()
        sleep(1)
        XCTAssertFalse(app.buttons["Done"].exists, "a short tap (like a Dwell look) does not open Settings")

        settings.press(forDuration: 1.5)
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 3), "holding opens Settings")
        shot("settings-2-screen")

        app.switches.firstMatch.tap()
        XCTAssertTrue(app.buttons["Choose folder"].waitForExistence(timeout: 3), "Training mode shows Choose folder")
        XCTAssertFalse(app.buttons["Done"].isEnabled, "Done is blocked: Training on but no folder with pictures")
        shot("settings-3-training-on-no-folder")
        app.switches.firstMatch.tap() // back to off for the other tests
        XCTAssertTrue(app.buttons["Done"].isEnabled, "Done works again with Training off")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Talk"].waitForExistence(timeout: 3), "Done goes back to TALK")
    }

    /// Screenshot of the TALK screen with the TRAINING button (for the README).
    /// "-trainingMode YES" switches the button on for this launch only (no picture folder needed).
    func testTrainingButtonShown() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launchArguments += ["-trainingMode", "YES"]
        app.launch()
        XCTAssertTrue(app.buttons["Talk"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["Training"].exists, "TRAINING button shown when switched on")
        shot("readme-talk-with-training")

        // No picture folder in the simulator: TRAINING must do nothing (stay on TALK).
        app.buttons["Training"].tap()
        sleep(1)
        XCTAssertTrue(app.buttons["Talk"].exists, "TRAINING without pictures stays on TALK")
        app.terminate()
    }

    func testExitWorksDuringTheWait() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Talk"].waitForExistence(timeout: 15))
        app.buttons["Talk"].tap()
        XCTAssertTrue(app.buttons["Exit"].waitForExistence(timeout: 3))
        app.buttons["Exit"].tap()
        XCTAssertTrue(app.buttons["Talk"].waitForExistence(timeout: 3), "EXIT works during the 3-second wait")
    }
}
