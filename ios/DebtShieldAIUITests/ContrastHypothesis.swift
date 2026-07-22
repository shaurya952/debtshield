import XCTest

/// Decides whether the audit's "Contrast failed" reports on primary-coloured
/// text are real or an artefact of content being outside the viewport.
///
/// Hypothesis: `performAccessibilityAudit` walks the whole element tree but can
/// only sample rendered pixels for what is on screen, so off-screen text is
/// reported as failing regardless of its actual colours.
///
/// Method: audit the Methodology screen twice — once at the top, once scrolled
/// to the bottom — and compare which steps are reported. If the failures follow
/// the scroll position rather than the elements, the reports are an artefact.
final class ContrastHypothesis: XCTestCase {

    func testContrastFailuresFollowScrollPosition() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-debtshield.hasSeenOnboarding", "NO"]
        app.launch()
        let start = app.buttons["I understand — get started"]
        if start.waitForExistence(timeout: 15) { start.tap() }

        app.tabBars.buttons["About"].tap()
        app.buttons["Methodology"].tap()
        XCTAssertTrue(app.navigationBars["Methodology"].waitForExistence(timeout: 10))

        func failingLabels() -> Set<String> {
            var labels = Set<String>()
            try? app.performAccessibilityAudit { issue in
                if issue.compactDescription.contains("Contrast failed"),
                   let label = issue.element?.label, !label.isEmpty {
                    labels.insert(String(label.prefix(40)))
                }
                return true
            }
            return labels
        }

        let atTop = failingLabels()

        // Scroll to the bottom and audit the same screen again.
        app.swipeUp(velocity: .fast)
        app.swipeUp(velocity: .fast)
        app.swipeUp(velocity: .fast)
        Thread.sleep(forTimeInterval: 1)
        let atBottom = failingLabels()

        let report = """
        HYPOTHESIS RESULTS
        at top    (\(atTop.count)): \(atTop.sorted().joined(separator: " ~ "))
        at bottom (\(atBottom.count)): \(atBottom.sorted().joined(separator: " ~ "))
        common    (\(atTop.intersection(atBottom).count)): \(atTop.intersection(atBottom).sorted().joined(separator: " ~ "))
        """
        XCTFail(report)
    }
}
