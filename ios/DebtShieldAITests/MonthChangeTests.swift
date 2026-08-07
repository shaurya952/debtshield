import XCTest
@testable import DebtShieldAI

/// "What changed since last month" — a plain read of actual history.
final class MonthChangeTests: XCTestCase {

    private func record(_ key: String, _ plan: MoneyPlan) -> MonthRecord {
        MonthRecord(monthKey: key, plan: plan)
    }

    func testMoreRoomThanLastMonth() {
        let last = record("2026-06", MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 400, energy: 200, debtPayments: 200)) // left 800
        let now = MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 300, energy: 200, debtPayments: 200) // left 900
        let change = MonthChangeEngine.compare(current: now, last: last)
        XCTAssertNotNil(change)
        XCTAssertEqual(change!.moneyLeftDelta, 100, accuracy: 0.001)
        XCTAssertTrue(change!.isImprovement)
        XCTAssertTrue(change!.headline.contains("more room"))
        XCTAssertEqual(change!.driver, "Mostly because food went down $100.")
    }

    func testLessRoomThanLastMonth() {
        let last = record("2026-06", MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 300, energy: 200, debtPayments: 200)) // left 900
        let now = MoneyPlan(monthlyIncome: 2800, housing: 1400, food: 300, energy: 200, debtPayments: 200) // left 700
        let change = MonthChangeEngine.compare(current: now, last: last)!
        XCTAssertEqual(change.moneyLeftDelta, -200, accuracy: 0.001)
        XCTAssertFalse(change.isImprovement)
        XCTAssertTrue(change.headline.contains("less room"))
        XCTAssertEqual(change.driver, "Mostly because income went down $200.")
    }

    func testFlatWhenUnchanged() {
        let plan = MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 300, energy: 200, debtPayments: 200)
        let change = MonthChangeEngine.compare(current: plan, last: record("2026-06", plan))!
        XCTAssertTrue(change.isFlat)
        XCTAssertNil(change.driver)
        XCTAssertTrue(change.headline.contains("About the same"))
    }

    func testNilWhenLastMonthHasNoIncome() {
        let last = record("2026-06", MoneyPlan(housing: 1400))
        let now = MoneyPlan(monthlyIncome: 3000, housing: 1400)
        XCTAssertNil(MonthChangeEngine.compare(current: now, last: last))
    }

    func testDriverPicksLargestMove() {
        let last = record("2026-06", MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 300, energy: 200, debtPayments: 200))
        // food +50, energy +40, debt +300 → debt is the biggest move
        let now = MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 350, energy: 240, debtPayments: 500)
        let change = MonthChangeEngine.compare(current: now, last: last)!
        XCTAssertEqual(change.driver, "Mostly because debt payments went up $300.")
    }
}
