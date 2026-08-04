import XCTest
@testable import DebtShieldAI

/// The synthesized verdict (good → watch → tight → heading/going/deep in debt).
final class SituationEngineTests: XCTestCase {

    private func months(_ plans: [MoneyPlan]) -> [MonthRecord] {
        plans.enumerated().map {
            MonthRecord(monthKey: String(format: "2026-%02d", $0.offset + 1), plan: $0.element)
        }
    }

    func testGoodShape() {
        let p = MoneyPlan.sampleOkay
        XCTAssertEqual(SituationEngine.assess(plan: p, months: months([p]))?.situation, .good)
    }

    func testTight() {
        let p = MoneyPlan.sampleTight
        XCTAssertEqual(SituationEngine.assess(plan: p, months: months([p]))?.situation, .tight)
    }

    func testOverBudgetGoesIntoDebt() {
        let p = MoneyPlan.sampleOver
        let read = SituationEngine.assess(plan: p, months: months([p]))
        XCTAssertNotNil(read)
        XCTAssertTrue([Situation.goingIntoDebt, .deepInDebt].contains(read!.situation))
    }

    func testHeavyDebtWhileCoveredIsNotGood() {
        // Debt at ~37% of income (over the 36% heavy line) but the month is covered.
        let p = MoneyPlan(monthlyIncome: 4000, housing: 800, food: 300, energy: 150, debtPayments: 1500)
        let read = SituationEngine.assess(plan: p, months: months([p]))
        XCTAssertNotNil(read)
        XCTAssertNotEqual(read?.situation, .good)
    }

    func testNilWhenIncomplete() {
        XCTAssertNil(SituationEngine.assess(plan: .empty, months: []))
    }

    func testHeadlineAndDetailPresent() {
        let read = SituationEngine.assess(plan: .sampleTight, months: months([.sampleTight]))
        XCTAssertFalse(read?.headline.isEmpty ?? true)
        XCTAssertFalse(read?.detail.isEmpty ?? true)
    }
}
