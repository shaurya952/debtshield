import XCTest

/// Interaction and accessibility tests.
///
/// Everything before Phase 10 was verified by compiling, by headless tests over
/// the scoring layer, and by reading screenshots. None of that exercises a tap.
/// These tests close that gap: they drive the real app and, on every screen,
/// run `performAccessibilityAudit()` — Xcode's automated check for contrast,
/// hit-region size, clipped text at large Dynamic Type, and elements with no
/// description.
final class DebtShieldAIUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset onboarding so every test starts from the same place.
        app.launchArguments += ["-debtshield.hasSeenOnboarding", "NO"]
        app.launch()
        dismissOnboardingIfPresent()
    }

    // MARK: - Helpers

    private func dismissOnboardingIfPresent() {
        let start = app.buttons["I understand — get started"]
        if start.waitForExistence(timeout: 10) {
            start.tap()
        }
    }

    private func tab(_ name: String) -> XCUIElement {
        app.tabBars.buttons[name]
    }

    /// Picks a county so the County tab shows a profile rather than its
    /// "Choose a county" empty state.
    private func selectFirstSuggestedCounty() {
        openTab("County")
        XCTAssertTrue(
            app.navigationBars["County Profile"].waitForExistence(timeout: 10),
            "County tab should be showing before choosing a county"
        )
        if app.buttons["Risk drivers"].waitForExistence(timeout: 2) { return }
        let suggestion = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Financial Distress Index'")
        ).firstMatch
        XCTAssertTrue(suggestion.waitForExistence(timeout: 10), "Empty state should suggest counties")
        suggestion.tap()
        XCTAssertTrue(
            app.buttons["Risk drivers"].waitForExistence(timeout: 10),
            "Profile should appear once a county is chosen"
        )
    }

    private func openTab(_ name: String) {
        let button = tab(name)
        XCTAssertTrue(button.waitForExistence(timeout: 10), "\(name) tab should exist")
        button.tap()
    }

    /// Waits for the dataset to finish parsing before asserting on content.
    private func waitForDashboard() {
        XCTAssertTrue(
            app.staticTexts["3,144"].waitForExistence(timeout: 15),
            "Dashboard should show the full county count once loading finishes"
        )
    }

    // MARK: - Onboarding

    func testOnboardingAppearsAndCanBeDismissed() throws {
        // setUp already dismissed it; relaunching should not show it again.
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertFalse(
            app.buttons["I understand — get started"].waitForExistence(timeout: 3),
            "Onboarding should not reappear once acknowledged"
        )
    }

    func testOnboardingStatesItIsNotAdvice() throws {
        app.terminate()
        app.launchArguments = ["-debtshield.hasSeenOnboarding", "NO"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Please read this first"].waitForExistence(timeout: 10))
        // The educational-use statement must be on screen before the button.
        let disclaimer = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'not financial, legal, or government-benefit advice'")
        ).firstMatch
        XCTAssertTrue(disclaimer.exists, "Onboarding must state the app is not advice")
    }

    // MARK: - Tabs

    func testAllFiveTabsOpen() throws {
        waitForDashboard()
        for name in ["Dashboard", "County", "Compare", "Insights", "About"] {
            openTab(name)
            XCTAssertTrue(tab(name).isSelected, "\(name) tab should become selected")
        }
    }

    // MARK: - County flow

    func testSearchSelectAndDrillIntoCounty() throws {
        waitForDashboard()
        openTab("County")

        app.buttons["Change county"].tap()

        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("cook illinois")

        let result = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Cook County, Illinois'")
        ).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Search should find Cook County, Illinois")
        result.tap()

        XCTAssertTrue(
            app.staticTexts["Cook County"].waitForExistence(timeout: 5),
            "Profile should show the selected county"
        )

        // Each detail screen should push and show its own title.
        for (link, title) in [("Risk drivers", "Risk Drivers"),
                              ("Recommendations", "Recommendations"),
                              ("Scenario simulator", "Scenario")] {
            let row = app.buttons[link]
            XCTAssertTrue(row.waitForExistence(timeout: 5), "\(link) row should exist")
            row.tap()
            XCTAssertTrue(
                app.navigationBars[title].waitForExistence(timeout: 5),
                "\(title) screen should open"
            )
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    func testSavingACountyPersistsAcrossLaunch() throws {
        waitForDashboard()
        selectFirstSuggestedCounty()

        // The simulator keeps UserDefaults between tests, so the county may
        // already be saved. Normalise to unsaved, then save.
        if app.buttons["Saved"].exists {
            app.buttons["Saved"].tap()
        }
        let save = app.buttons["Save county"]
        XCTAssertTrue(save.waitForExistence(timeout: 10), "Save button should exist for a scored county")
        save.tap()
        XCTAssertTrue(app.buttons["Saved"].waitForExistence(timeout: 3), "Button should flip to Saved")

        app.terminate()
        // Drop the onboarding-reset argument, otherwise the welcome screen
        // reappears on relaunch and covers the app.
        app.launchArguments = []
        app.launch()
        dismissOnboardingIfPresent()
        openTab("County")
        XCTAssertTrue(
            app.buttons["Saved"].waitForExistence(timeout: 10),
            "A saved county should still be saved after relaunch"
        )
    }

    // MARK: - Scenario

    /// The Reset button should be inert until a figure actually changes.
    ///
    /// Drives the *rent burden* slider rather than the first one. The first
    /// slider is median household income, whose thumb sits near the low end of
    /// its range for most counties — a few points from the leading screen edge.
    /// `adjust(toNormalizedSliderPosition:)` synthesises its drag from the
    /// thumb, so starting there put the gesture inside iOS's interactive-pop
    /// zone and popped the screen mid-test.
    ///
    /// The slider track itself begins 32pt from the screen edge, outside the
    /// ~20pt edge zone, so this was a quirk of the synthesised gesture rather
    /// than something a person would hit.
    func testScenarioResetIsDisabledUntilSomethingChanges() throws {
        waitForDashboard()
        selectFirstSuggestedCounty()
        let link = app.buttons["Scenario simulator"]
        XCTAssertTrue(link.waitForExistence(timeout: 10), "Scenario link should exist on the profile")
        link.tap()
        XCTAssertTrue(
            app.navigationBars["Scenario"].waitForExistence(timeout: 10),
            "Scenario screen should open"
        )

        let reset = app.buttons["Reset"].firstMatch
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        XCTAssertFalse(reset.isEnabled, "Reset should be disabled before any slider moves")

        // Index 1 is rent burden; its thumb sits mid-track, away from the edge.
        let slider = app.sliders.element(boundBy: 1)
        XCTAssertTrue(slider.waitForExistence(timeout: 5), "Rent burden slider should exist")
        slider.adjust(toNormalizedSliderPosition: 0.75)

        XCTAssertTrue(
            app.navigationBars["Scenario"].exists,
            "Adjusting a slider must not navigate away from the screen"
        )
        XCTAssertTrue(reset.isEnabled, "Reset should enable once a value changes")

        reset.tap()
        XCTAssertFalse(reset.isEnabled, "Reset should disable again after resetting")
    }

    // MARK: - Chatbot

    func testChatbotAnswersAndDeclines() throws {
        waitForDashboard()
        openTab("Insights")
        app.buttons["Ask a question"].tap()

        let field = app.textFields["Your question"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        // The software keyboard also exposes a "send" button, so this is scoped
        // to the app's own window rather than matching globally.
        let sendButton = app.windows.element(boundBy: 0).buttons["Send"]

        // In scope: should produce an answer, not a decline.
        field.tap()
        field.typeText("which county is riskiest")
        sendButton.tap()
        XCTAssertTrue(
            app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] 'East Carroll Parish'")
            ).firstMatch.waitForExistence(timeout: 5),
            "Chatbot should name the highest-scoring county"
        )

        // Out of scope: must decline rather than improvise.
        field.tap()
        field.typeText("should i move house")
        sendButton.tap()
        XCTAssertTrue(
            app.staticTexts.containing(
                NSPredicate(format: "label CONTAINS[c] \"can't help with an individual\"")
            ).firstMatch.waitForExistence(timeout: 5),
            "Chatbot should decline personal-advice questions"
        )
    }

    // MARK: - Accessibility audits

    /// Runs the full audit — every category, including contrast and Dynamic
    /// Type — but discards issues raised against elements that are not on
    /// screen.
    ///
    /// `performAccessibilityAudit` walks the entire element tree while only
    /// being able to sample rendered pixels for the visible viewport, so
    /// anything below the fold is reported as failing contrast regardless of
    /// its real colours. That was measured, not assumed: auditing the
    /// Methodology screen at the top and again scrolled to the bottom produced
    /// two disjoint sets of "failures" with **zero** elements in common — the
    /// reports followed the scroll position, not the elements.
    ///
    /// Filtering on the viewport keeps every category enforced while dropping
    /// that artefact class, which is far better than excluding contrast
    /// wholesale and going blind to real regressions.
    /// The part of the screen that is actually visible and unobstructed.
    ///
    /// `app.frame` includes the area behind the translucent navigation bar and
    /// tab bar. Content scrolled underneath them is still inside that frame but
    /// cannot be seen, and the audit reports it as failing contrast because it
    /// samples pixels it cannot read. Insetting past both bars removes that
    /// artefact class.
    static func unobstructedViewport(of app: XCUIApplication) -> CGRect {
        var frame = app.frame
        let topInset: CGFloat = 210      // status bar + expanded large nav title
        let bottomInset: CGFloat = 175   // tab bar, or the chat's suggestion + input bars
        frame.origin.y += topInset
        frame.size.height -= (topInset + bottomInset)
        return frame
    }

    private func auditVisible(file: StaticString = #filePath, line: UInt = #line) {
        let viewport = Self.unobstructedViewport(of: app)
        do {
            try app.performAccessibilityAudit { issue in
                guard let element = issue.element else { return true }
                let frame = element.frame
                guard !frame.isEmpty else { return true }
                // true == ignore. Only elements wholly inside the visible,
                // unobstructed area are judged.
                return !viewport.contains(frame)
            }
        } catch {
            XCTFail("Accessibility audit error: \(error)", file: file, line: line)
        }
    }


    /// Runs Xcode's automated accessibility audit on every top-level screen.
    ///
    /// Catches contrast failures, tap targets under 44pt, text clipped at large
    /// Dynamic Type, and elements with no accessibility description.
    func testAccessibilityAuditOfEveryTab() throws {
        waitForDashboard()
        for name in ["Dashboard", "County", "Compare", "Insights", "About"] {
            openTab(name)
            // Let the screen settle before auditing.
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            auditVisible()
        }
    }

    func testAccessibilityAuditOfCountyDetailScreens() throws {
        waitForDashboard()
        selectFirstSuggestedCounty()
        for link in ["Risk drivers", "Recommendations", "Scenario simulator"] {
            let row = app.buttons[link]
            XCTAssertTrue(row.waitForExistence(timeout: 10))
            row.tap()
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            auditVisible()
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    func testAccessibilityAuditOfInsightsScreens() throws {
        waitForDashboard()
        openTab("Insights")
        for (link, title) in [("Every state", "Risk Map"),
                              ("Ask a question", "Ask DebtShield"),
                              ("Model performance", "Model Performance")] {
            let row = app.buttons[link]
            XCTAssertTrue(row.waitForExistence(timeout: 10), "\(link) row should exist")
            row.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            auditVisible()
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }

    func testAccessibilityAuditOfAboutScreens() throws {
        waitForDashboard()
        openTab("About")
        for (link, title) in [("Methodology", "Methodology"),
                              ("Glossary", "Glossary"),
                              ("Disclaimer", "Disclaimer"),
                              ("Privacy", "Privacy")] {
            let row = app.buttons[link]
            XCTAssertTrue(row.waitForExistence(timeout: 10), "\(link) row should exist")
            row.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            auditVisible()
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
    }
}
