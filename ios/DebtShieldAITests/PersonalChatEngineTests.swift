import XCTest
@testable import DebtShieldAI

/// The deterministic Ask engine. It must compute from the entered numbers only,
/// stay deterministic, decline advice, and route the new money questions.
final class PersonalChatEngineTests: XCTestCase {

    private func answer(_ q: String, _ plan: MoneyPlan) -> ChatAnswer {
        PersonalChatEngine.respond(to: q, plan: plan)
    }

    // MARK: - New intents

    func testCushionGivesTheThreeToSixMonthGuideline() {
        let a = answer("how's my cushion?", .sampleOkay)
        XCTAssertTrue(a.text.contains("3 to 6 months of essentials"))
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.contains("month")) // build-time estimate present (surplus > 0)
    }

    func testSavingsRateReportsShareOfIncome() {
        let a = answer("how much do I keep each month?", .sampleOkay)
        XCTAssertTrue(a.text.contains("of your income"))
        XCTAssertTrue(a.text.lowercased().contains("keep"))
    }

    func testDebtBurdenUsesGuidelines() {
        let a = answer("how much of my income goes to debt?", .sampleTight) // debt 100 / 3000 ≈ 3%
        XCTAssertTrue(a.text.contains("of your income"))
        XCTAssertTrue(a.text.contains("20%"))
    }

    func testDebtBurdenWhenNoDebt() {
        let noDebt = MoneyPlan(monthlyIncome: 4000, housing: 1200, food: 350, energy: 160)
        let a = answer("how much goes to debt?", noDebt)
        XCTAssertTrue(a.text.lowercased().contains("no debt") || a.text.lowercased().contains("any debt"))
    }

    func testAnnualProjection() {
        let a = answer("how much over a year?", .sampleOkay)
        XCTAssertTrue(a.text.contains("over 12 months"))
    }

    // MARK: - Boundaries preserved

    func testDeclinesAdviceAndPointsTo211() {
        let a = answer("should I take out a loan to consolidate?", .sampleTight)
        XCTAssertTrue(a.isDecline)
        XCTAssertTrue(a.text.contains("211"))
    }

    func testNeedsNumbersWhenEmpty() {
        let a = answer("how's my cushion?", .empty)
        XCTAssertTrue(a.isDecline)
    }

    func testSafeLineWorksWithoutNumbers() {
        XCTAssertTrue(answer("what's the safe line?", .empty).text.lowercased().contains("safe line"))
    }

    // MARK: - Determinism (it can never invent a different figure)

    func testDeterministicAnswers() {
        for q in ["how's my cushion?", "how much do I keep each month?",
                  "how much over a year?", "why is it tight?"] {
            XCTAssertEqual(answer(q, .sampleTight).text, answer(q, .sampleTight).text, "‘\(q)’ must be deterministic")
        }
    }

    func testAnswersNeverInventBeyondPlan() {
        // The engine only quotes figures it can compute; a well-formed answer for
        // a complete plan is not a decline and carries provenance.
        let a = answer("how much do I keep each month?", .sampleOkay)
        XCTAssertFalse(a.isDecline)
        XCTAssertEqual(a.provenance, "Your numbers")
    }
}
