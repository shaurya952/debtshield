import XCTest

/// Enumerates every accessibility-audit issue across the current app and records
/// them as an attachment, without failing.
///
/// `performAccessibilityAudit()` alone reports only a category ("Contrast
/// failed") with no element, which is hard to act on. The closure form hands
/// back each issue (with its element), so this collects them all for review.
/// It returns `true` for every issue ("ignore"), so the test stays green — it's
/// a diagnostic; `DebtShieldAIUITests` does the enforcing (viewport-filtered).
final class AccessibilityDiagnostics: XCTestCase {

    private var app: XCUIApplication!
    private var findings: [String] = []

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments += [
            "-debtshield.hasSeenOnboarding", "YES",
            "-debtshield.userName", "Sam",
            "uitest-seed",
        ]
        app.launch()
        _ = app.staticTexts["Hi, Sam"].waitForExistence(timeout: 15)
    }

    private func audit(_ screen: String) {
        try? app.performAccessibilityAudit { issue in
            let element = issue.element
            let label = element?.label ?? "—"
            let type = element.map { String(describing: $0.elementType) } ?? "—"
            let frame = element.map { "\(Int($0.frame.width))x\(Int($0.frame.height))" } ?? "—"
            self.findings.append("\(screen) | \(issue.compactDescription) | \(type) | \(frame) | \(label.prefix(80))")
            return true // ignore — enumerate, never fail
        }
    }

    private func openTab(_ name: String) {
        let b = app.tabBars.buttons[name]
        if b.waitForExistence(timeout: 10) { b.tap() }
    }

    private func back() { app.navigationBars.buttons.element(boundBy: 0).tap() }

    func testEnumerateAccessibilityIssuesAcrossTheApp() throws {
        for name in ["Home", "Places", "Explain", "About"] {
            openTab(name)
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            audit(name)
        }

        openTab("Home")
        for (tile, title) in [("The year ahead", "The year ahead"),
                              ("Your spending", "Your spending"),
                              ("Save & earn more", "Save & earn more")] {
            let t = app.buttons[tile]
            if t.waitForExistence(timeout: 8) {
                t.tap()
                _ = app.navigationBars[title].waitForExistence(timeout: 8)
                audit("Home ▸ \(title)")
                back()
            }
        }

        openTab("About")
        if app.buttons["Trust Center"].waitForExistence(timeout: 8) {
            app.buttons["Trust Center"].tap()
            _ = app.navigationBars["Trust Center"].waitForExistence(timeout: 8)
            audit("Trust Center")
            back()
        }

        let report = findings.isEmpty
            ? "No accessibility-audit issues found on the audited screens."
            : "Accessibility findings (\(findings.count)):\n" + findings.joined(separator: "\n")
        let attachment = XCTAttachment(string: report)
        attachment.name = "accessibility-findings"
        attachment.lifetime = .keepAlways
        add(attachment)
        print(report)
    }
}
