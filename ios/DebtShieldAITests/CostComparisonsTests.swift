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

    func testTransportationComparesToNationalBLS() {
        let p = MoneyPlan(monthlyIncome: 5000, transportation: 450)
        let c = CostComparisons.transportation(p, .previewSample)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.standing, .below) // 450 well under the ~1,098 U.S. average
        XCTAssertTrue(c!.refs.contains { $0.label == "Across the U.S." })
        XCTAssertTrue(c!.source.contains("BLS"))
    }

    func testPersonalComparesToNationalBLS() {
        let p = MoneyPlan(monthlyIncome: 5000, personal: 300)
        let c = CostComparisons.personal(p, .previewSample)
        XCTAssertNotNil(c)
        XCTAssertEqual(c?.standing, .below) // 300 under the ~550 U.S. average
        XCTAssertTrue(c!.source.contains("BLS"))
    }

    func testNewCategoryComparisonsNilWithoutEntry() {
        let p = MoneyPlan(monthlyIncome: 5000, housing: 1400)
        XCTAssertNil(CostComparisons.transportation(p, .previewSample))
        XCTAssertNil(CostComparisons.personal(p, .previewSample))
    }

    func testWaterAndHomeUpkeepCompareToBLS() {
        let p = MoneyPlan(monthlyIncome: 5000, homeUpkeep: 300, water: 40)
        let water = CostComparisons.water(p, .previewSample)
        let upkeep = CostComparisons.homeUpkeep(p, .previewSample)
        XCTAssertNotNil(water)
        XCTAssertNotNil(upkeep)
        XCTAssertTrue(water!.source.contains("BLS"))
        XCTAssertTrue(upkeep!.source.contains("BLS"))
        XCTAssertEqual(water?.standing, .below)  // 40 under the ~65 U.S. average
        XCTAssertEqual(upkeep?.standing, .below)  // 300 under the ~671 homeowner average
    }

    func testRealBLSNationalFiguresAreSane() {
        // Real published BLS CE 2023 monthly figures.
        XCTAssertEqual(BenchmarksLoader.officialNationalTransportationMonthly, 13174.0 / 12, accuracy: 0.01)
        XCTAssertEqual(BenchmarksLoader.officialNationalPersonalMonthly, (2041.0 + 3635.0 + 927.0) / 12, accuracy: 0.01)
        XCTAssertEqual(BenchmarksLoader.officialNationalWaterMonthly, 780.0 / 12, accuracy: 0.01)
        XCTAssertEqual(BenchmarksLoader.officialNationalHomeUpkeepMonthly, (4079.0 + 3974.0) / 12, accuracy: 0.01)
    }
}
