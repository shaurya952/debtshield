import XCTest
@testable import DebtShieldAI

/// The year-ahead simulation: determinism, valid ranges, no NaN/∞, mode
/// selection, and sensitivity behaviour. Nothing here tunes assumptions to make
/// risk look worse — it only checks the maths is well-formed and reproducible.
final class MonteCarloEngineTests: XCTestCase {

    private func months(_ plans: [MoneyPlan]) -> [MonthRecord] {
        plans.enumerated().map {
            MonthRecord(monthKey: String(format: "2026-%02d", $0.offset + 1), plan: $0.element)
        }
    }

    func testDeterministicWithSameSeed() {
        let p = MoneyPlan.sampleTight
        let a = MonteCarloEngine.simulate(plan: p, history: [], seed: 42)
        let b = MonteCarloEngine.simulate(plan: p, history: [], seed: 42)
        XCTAssertNotNil(a); XCTAssertNotNil(b)
        XCTAssertEqual(a!.probNegativeWithin6mo, b!.probNegativeWithin6mo)
        XCTAssertEqual(a!.probNegativeWithin12mo, b!.probNegativeWithin12mo)
        XCTAssertEqual(a!.p50_12mo, b!.p50_12mo)
    }

    func testProbabilitiesInUnitRange() {
        let r = MonteCarloEngine.simulate(plan: .sampleTight, history: [], seed: 42)!
        XCTAssertTrue((0...1).contains(r.probNegativeWithin6mo))
        XCTAssertTrue((0...1).contains(r.probNegativeWithin12mo))
    }

    func testPercentilesOrdered() {
        let r = MonteCarloEngine.simulate(plan: .sampleTight, history: [], seed: 42)!
        XCTAssertLessThanOrEqual(r.p10_12mo, r.p50_12mo)
        XCTAssertLessThanOrEqual(r.p50_12mo, r.p90_12mo)
    }

    func testNoNaNOrInfinity() {
        let r = MonteCarloEngine.simulate(plan: .sampleTight, history: [], seed: 42)!
        XCTAssertTrue(r.p10_12mo.isFinite && r.p50_12mo.isFinite && r.p90_12mo.isFinite)
        XCTAssertTrue(r.probNegativeWithin6mo.isFinite && r.probNegativeWithin12mo.isFinite)
    }

    func testZeroIncomeReturnsNil() {
        XCTAssertNil(MonteCarloEngine.simulate(plan: MoneyPlan(monthlyIncome: 0, housing: 500), history: [], seed: 1))
    }

    func testIncompletePlanReturnsNil() {
        XCTAssertNil(MonteCarloEngine.simulate(plan: .empty, history: [], seed: 1))
    }

    func testHealthierFinancesAreNotRiskierThanTight() {
        let healthy = MonteCarloEngine.simulate(plan: .sampleOkay, history: [], seed: 42)!
        let tight = MonteCarloEngine.simulate(plan: .sampleTight, history: [], seed: 42)!
        XCTAssertLessThanOrEqual(healthy.probNegativeWithin12mo, tight.probNegativeWithin12mo)
    }

    func testNationalDefaultModeWithoutHistory() {
        XCTAssertEqual(MonteCarloEngine.simulate(plan: .sampleTight, history: [], seed: 42)?.mode, .nationalDefault)
    }

    func testPersonalHistoryModeWithThreeMonths() {
        let p = MoneyPlan.sampleTight
        let r = MonteCarloEngine.simulate(plan: p, history: months([p, p, p]), seed: 42)
        XCTAssertEqual(r?.mode, .personalHistory)
    }

    func testSensitivityLeverDoesNotIncreaseOdds() {
        let p = MoneyPlan.sampleTight
        guard let base = MonteCarloEngine.simulate(plan: p, history: [], seed: 0xB1A5),
              let lever = MonteCarloEngine.sensitivity(plan: p, history: [], seed: 0xB1A5)?.topActionableLever else {
            return // no actionable lever for this plan is acceptable
        }
        XCTAssertLessThanOrEqual(lever.newProbability6mo, base.probNegativeWithin6mo + 1e-9)
        XCTAssertGreaterThanOrEqual(lever.reduction, 0)
    }

    func testRunCountReported() {
        let r = MonteCarloEngine.simulate(plan: .sampleTight, history: [], runs: 300, seed: 42)!
        XCTAssertEqual(r.runs, 300)
    }
}
