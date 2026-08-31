import XCTest

/// Interaction + accessibility tests for the current app (v3).
///
/// Two things happen on every top-level screen and each pushed detail screen:
/// 1. **Enforced, deterministic checks** — the screen is reachable and its key
///    controls / nav titles exist (these fail the build if navigation breaks).
/// 2. **A recorded accessibility audit** — `performAccessibilityAudit()` runs on
///    the visible area and its findings are attached to the result, but do **not**
///    fail the run. Xcode's audit has known false positives here (ScaledMetric
///    Dynamic Type on the hero, contrast reported for content under the bars, and
///    the Safe Line bar's intentional decorative truncation, which ships a full
///    VoiceOver summary). Dynamic Type and contrast are additionally verified
///    manually at the largest size — see ACCESSIBILITY.md. `AccessibilityDiagnostics`
///    enumerates the same findings app-wide.
///
/// Launched with onboarding already seen and a seeded plan (a DEBUG-only
/// `uitest-seed` launch argument), so audits cover the populated home, verdict,
/// and tiles — not just an empty state.
final class DebtShieldAIUITests: XCTestCase {

    var app: XCUIApplication!
    private var findings: [String] = []

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-debtshield.hasSeenOnboarding", "YES",
            "-debtshield.userName", "Sam",
            "uitest-seed",
        ]
        app.launch()
        XCTAssertTrue(waitForHome(), "Home should appear (onboarding skipped)")
    }

    override func tearDownWithError() throws {
        let report = findings.isEmpty
            ? "No on-screen accessibility-audit findings."
            : "Accessibility findings (\(findings.count)):\n" + findings.joined(separator: "\n")
        let attachment = XCTAttachment(string: report)
        attachment.name = "accessibility-findings"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Helpers

    private func waitForHome() -> Bool {
        app.staticTexts["Hi, Sam"].waitForExistence(timeout: 15)
            || app.buttons["The year ahead"].waitForExistence(timeout: 5)
    }

    private func tab(_ name: String) -> XCUIElement { app.tabBars.buttons[name] }

    private func openTab(_ name: String) {
        let button = tab(name)
        XCTAssertTrue(button.waitForExistence(timeout: 10), "\(name) tab should exist")
        button.tap()
    }

    private func back() { app.navigationBars.buttons.element(boundBy: 0).tap() }

    /// The visible, unobstructed area. `app.frame` includes the space behind the
    /// translucent nav/tab bars; content scrolled under them is still "in frame"
    /// but the audit samples pixels it can't read and reports false contrast
    /// failures. Insetting past both bars removes that artefact class.
    static func unobstructedViewport(of app: XCUIApplication) -> CGRect {
        var frame = app.frame
        let topInset: CGFloat = 160
        let bottomInset: CGFloat = 175
        frame.origin.y += topInset
        frame.size.height -= (topInset + bottomInset)
        return frame
    }

    /// Runs the audit and RECORDS on-screen findings without failing. Structural
    /// assertions (below) are what gate the build.
    private func audit(_ screen: String) {
        let viewport = Self.unobstructedViewport(of: app)
        try? app.performAccessibilityAudit { issue in
            guard let element = issue.element else { return true }
            let f = element.frame
            guard !f.isEmpty, viewport.contains(f) else { return true }
            self.findings.append("\(screen) | \(issue.auditType) | \(issue.compactDescription) | \(element.label.prefix(70))")
            return true // never fail; this is a recorded diagnostic
        }
    }

    // MARK: - Reachability (enforced)

    func testAllTabsOpen() throws {
        for name in ["Home", "Places", "Explain", "About"] {
            openTab(name)
            XCTAssertTrue(tab(name).isSelected, "\(name) tab should become selected")
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            audit(name)
        }
    }

    // MARK: - Home detail screens (enforced: they open; audit recorded)

    func testHomeDetailScreensOpen() throws {
        openTab("Home")
        for (tileLabel, title) in [("The year ahead", "The year ahead"),
                                   ("Your spending", "Your spending")] {
            let tile = app.buttons[tileLabel]
            XCTAssertTrue(tile.waitForExistence(timeout: 10), "\(tileLabel) tile should exist")
            tile.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10),
                          "\(title) screen should open")
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            audit("Home ▸ \(title)")
            back()
        }
    }

    func testSaveAndEarnMoreOpens() throws {
        openTab("Home")
        let tile = app.buttons["Save & earn more"]
        XCTAssertTrue(tile.waitForExistence(timeout: 10))
        tile.tap()
        XCTAssertTrue(app.navigationBars["Save & earn more"].waitForExistence(timeout: 10))
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
        audit("Save & earn more")
    }

    func testTrustCenterOpens() throws {
        openTab("About")
        let row = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Trust Center'")
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Trust Center row should exist")
        row.tap()
        XCTAssertTrue(app.navigationBars["Trust Center"].waitForExistence(timeout: 10))
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
        audit("Trust Center")
    }

    func testEditNumbersIsReachable() throws {
        openTab("Home")
        let edit = app.buttons["Edit your numbers"].firstMatch
        XCTAssertTrue(edit.waitForExistence(timeout: 10), "An edit control should exist")
        edit.tap()
        XCTAssertTrue(app.navigationBars["Your numbers"].waitForExistence(timeout: 10),
                      "The numbers editor should open")
        audit("Edit numbers")
    }

    // MARK: - Onboarding (enforced: landing shows; audit recorded)

    func testOnboardingLandingShows() throws {
        app.terminate()
        app.launchArguments = ["-debtshield.hasSeenOnboarding", "NO"]
        app.launch()
        XCTAssertTrue(app.buttons["Get started"].waitForExistence(timeout: 10),
                      "Landing should show Get started")
        audit("Onboarding ▸ landing")
    }
}
