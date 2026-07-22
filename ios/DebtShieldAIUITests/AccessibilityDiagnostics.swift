import XCTest

/// Diagnostic pass over every screen.
///
/// `performAccessibilityAudit()` on its own reports only a category — "Contrast
/// failed" — with no indication of which element is at fault, which makes the
/// findings almost impossible to act on. The closure form hands back each
/// `XCUIAccessibilityAuditIssue`, including the element, so this test collects
/// them all and prints them.
///
/// It returns `true` from the handler for every issue, meaning "ignore" — the
/// point is to enumerate, not to fail. `AccessibilityAuditTests` is what
/// actually enforces.
final class AccessibilityDiagnostics: XCTestCase {

    private var app: XCUIApplication!
    private var findings: [String] = []

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments += ["-debtshield.hasSeenOnboarding", "NO"]
        app.launch()
        let start = app.buttons["I understand — get started"]
        if start.waitForExistence(timeout: 15) { start.tap() }
    }

    private func audit(_ screen: String) {
        let viewport = DebtShieldAIUITests.unobstructedViewport(of: app)
        try? app.performAccessibilityAudit { issue in
            // Same viewport filter as the enforcing tests: off-screen elements
            // produce spurious contrast reports.
            if let f = issue.element?.frame, !f.isEmpty, !viewport.contains(f) { return true }
            let element = issue.element
            let label = element?.label ?? "—"
            let type = element.map { String(describing: $0.elementType) } ?? "—"
            let frame = element.map { "\(Int($0.frame.width))x\(Int($0.frame.height))" } ?? "—"
            self.findings.append(
                "AUDIT|\(screen)|\(issue.compactDescription)|type=\(type)|frame=\(frame)|label=\(label.prefix(90))"
            )
            return true // ignore — enumerate rather than fail
        }
    }

    private func openTab(_ name: String) {
        let button = app.tabBars.buttons[name]
        if button.waitForExistence(timeout: 10) { button.tap() }
    }

    private func selectCounty() {
        openTab("County")
        if app.buttons["Risk drivers"].waitForExistence(timeout: 3) { return }
        let suggestion = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] 'Financial Distress Index'")
        ).firstMatch
        if suggestion.waitForExistence(timeout: 10) { suggestion.tap() }
        _ = app.buttons["Risk drivers"].waitForExistence(timeout: 10)
    }

    func testEnumerateEveryAccessibilityIssue() throws {
        _ = app.staticTexts["3,144"].waitForExistence(timeout: 20)

        for tab in ["Dashboard", "County", "Compare", "Insights", "About"] {
            openTab(tab)
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
            audit(tab)
        }

        selectCounty()
        for link in ["Risk drivers", "Recommendations", "Scenario simulator"] {
            let row = app.buttons[link]
            if row.waitForExistence(timeout: 10) {
                row.tap()
                _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
                audit("County ▸ \(link)")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }

        openTab("Insights")
        for (link, title) in [("Every state", "Risk Map"),
                              ("Ask a question", "Ask DebtShield"),
                              ("Model performance", "Model Performance")] {
            let row = app.buttons[link]
            if row.waitForExistence(timeout: 10) {
                row.tap()
                _ = app.navigationBars[title].waitForExistence(timeout: 10)
                _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
                audit("Insights ▸ \(title)")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }

        openTab("About")
        for (link, title) in [("Methodology", "Methodology"), ("Glossary", "Glossary"),
                              ("Disclaimer", "Disclaimer"), ("Privacy", "Privacy")] {
            let row = app.buttons[link]
            if row.waitForExistence(timeout: 10) {
                row.tap()
                _ = app.navigationBars[title].waitForExistence(timeout: 10)
                _ = app.staticTexts.firstMatch.waitForExistence(timeout: 5)
                audit("About ▸ \(title)")
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }

        // Reported as a failure so the text lands in the .xcresult, where it
        // can be read back. stdout from the runner is not surfaced by
        // xcodebuild. This test is diagnostic — it is expected to "fail" while
        // any issue remains.
        if !findings.isEmpty {
            XCTFail("FINDINGS(\(findings.count))\n" + findings.joined(separator: "\n"))
        }
    }
}
