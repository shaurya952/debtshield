import XCTest
@testable import DebtShieldAI

/// Verdict classification and derived-figure safety for `MoneyPlan`.
/// The "tight" verdict weighs both the safe-line share *and* the dollar cushion
/// (`comfortableCushion`), so these cases pin that behaviour down.
final class MoneyPlanTests: XCTestCase {

    func testOkayUnderSafeLine() {
        let p = MoneyPlan(monthlyIncome: 4000, housing: 1200, food: 350, energy: 160, debtPayments: 50)
        XCTAssertEqual(p.status, .okay)
    }

    func testTightWhenOverLineAndThinCushion() {
        // 65% of income on basics, only $1,050 left → tight.
        let p = MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 300, energy: 150, debtPayments: 100)
        XCTAssertEqual(p.status, .tight)
    }

    func testOverLineButComfortableCushionIsOkay() {
        // 58% of income on basics but $2,100 left → the dollar rule keeps it okay.
        let p = MoneyPlan(monthlyIncome: 5000, housing: 1400, food: 900, energy: 300, debtPayments: 300)
        XCTAssertEqual(p.status, .okay)
    }

    func testOverBudget() {
        let p = MoneyPlan(monthlyIncome: 2500, housing: 1600, food: 600, energy: 300, debtPayments: 250)
        XCTAssertEqual(p.status, .over)
        XCTAssertEqual(p.moneyLeft ?? 0, -250, accuracy: 0.001)
    }

    func testComfortableCushionBoundary() {
        // Both over the 55% line; the dollar cushion decides.
        let okay = MoneyPlan(monthlyIncome: 4000, housing: 2300)   // 57.5%, $1,700 left ≥ cushion
        XCTAssertEqual(okay.status, .okay)
        let tight = MoneyPlan(monthlyIncome: 4000, housing: 2600)  // 65%, $1,400 left < cushion
        XCTAssertEqual(tight.status, .tight)
    }

    func testZeroIncomeYieldsNilDerived() {
        let p = MoneyPlan(monthlyIncome: 0, housing: 500)
        XCTAssertNil(p.status)
        XCTAssertNil(p.moneyLeft)
        XCTAssertNil(p.essentialsShare)
    }

    func testMissingIncomeYieldsNil() {
        XCTAssertNil(MoneyPlan(housing: 500).status)
    }

    func testDebtExceedingIncomeIsOver() {
        let p = MoneyPlan(monthlyIncome: 1000, debtPayments: 1500)
        XCTAssertEqual(p.status, .over)
        XCTAssertLessThan(p.moneyLeft ?? 0, 0)
    }

    func testDerivedFiguresAreFinite() {
        let p = MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 300, energy: 150, debtPayments: 100)
        XCTAssertTrue((p.essentialsShare ?? .nan).isFinite)
        XCTAssertTrue((p.moneyLeft ?? .nan).isFinite)
        XCTAssertEqual(p.essentialsShare ?? 0, 1950.0 / 3000.0, accuracy: 0.0001)
    }

    func testFixturesClassifyAsDocumented() {
        XCTAssertEqual(MoneyPlan.sampleOkay.status, .okay)
        XCTAssertEqual(MoneyPlan.sampleTight.status, .tight)
        XCTAssertEqual(MoneyPlan.sampleOver.status, .over)
        XCTAssertEqual(MoneyPlan.sampleComfortableOverLine.status, .okay)
        XCTAssertNil(MoneyPlan.empty.status)
    }
}
