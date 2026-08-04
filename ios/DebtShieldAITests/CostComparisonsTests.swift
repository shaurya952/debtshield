import XCTest
@testable import DebtShieldAI

/// Compare-tab logic. Notably: food has no local dimension in the data, so it
/// must still surface two references (typical-for-income + the U.S. average).
final class CostComparisonsTests: XCTestCase {

    func testFoodShowsIncomeTypicalAndNationalRows() {
        let p = MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 300, energy: 150, debtPayments: 100)
        let c = CostComparisons.food(p, .previewSample)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.refs.count, 2)
        XCTAssertTrue(c!.refs.contains { $0.label == "Across the U.S." })
    }

    func testFoodNilWithoutFoodEntry() {
        let p = MoneyPlan(monthlyIncome: 3000, housing: 1400)
        XCTAssertNil(CostComparisons.food(p, .previewSample))
    }

    func testDebtGuidelineHigh() {
        let p = MoneyPlan(monthlyIncome: 4000, debtPayments: 1600) // 40% → high
        XCTAssertEqual(CostComparisons.debt(p)?.standing, .high)
    }

    func testDebtGuidelineHealthy() {
        let p = MoneyPlan(monthlyIncome: 4000, debtPayments: 400) // 10% → healthy
        XCTAssertEqual(CostComparisons.debt(p)?.standing, .healthy)
    }

    func testAllComparisonAmountsAreFinite() {
        let all = CostComparisons.all(plan: .sampleTight, county: nil, benchmarks: .previewSample)
        XCTAssertFalse(all.isEmpty)
        for c in all {
            XCTAssertTrue(c.yours.isFinite)
            for ref in c.refs { XCTAssertTrue(ref.amount.isFinite) }
        }
    }

    func testNationalFoodBenchmarkPresent() {
        XCTAssertGreaterThan(Benchmarks.previewSample.nationalFood, 0)
        XCTAssertGreaterThan(Benchmarks.previewSample.nationalRent, 0)
    }
}
