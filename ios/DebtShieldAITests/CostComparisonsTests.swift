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

    func testHomeUpkeepComparesToBLS() {
        let p = MoneyPlan(monthlyIncome: 5000, homeUpkeep: 300)
        let upkeep = CostComparisons.homeUpkeep(p, .previewSample)
        XCTAssertNotNil(upkeep)
        XCTAssertTrue(upkeep!.source.contains("BLS"))
        XCTAssertEqual(upkeep?.standing, .below)  // 300 under the ~671 homeowner average
    }

    func testUtilitiesAddsGasAndWaterOntoElectricity() {
        // The one "Utilities" entry compares against electricity (previewSample
        // nationalEnergy 137) PLUS the gas+water addon (110) = ~247 U.S. typical.
        let p = MoneyPlan(monthlyIncome: 5000, energy: 150)
        let c = CostComparisons.utilities(p, nil, .previewSample)
        XCTAssertNotNil(c)
        let national = c!.refs.first { $0.label == "Across the U.S." }
        XCTAssertNotNil(national)
        XCTAssertEqual(national!.amount, 137 + 110, accuracy: 0.5)
        XCTAssertEqual(c?.standing, .below)      // 150 under the ~247 U.S. average
        XCTAssertTrue(c!.source.contains("BLS")) // gas + water are BLS-sourced
    }

    func testLegacyWaterFoldsIntoUtilitiesOnDecode() throws {
        // A plan saved before the merge kept water separate; decoding must fold
        // it into energy so the figure isn't silently lost.
        let legacy = #"{"monthlyIncome":5000,"energy":150,"water":40}"#.data(using: .utf8)!
        let plan = try JSONDecoder().decode(MoneyPlan.self, from: legacy)
        XCTAssertEqual(plan.energy, 190)   // 150 electricity + 40 water
        XCTAssertNil(plan.water)           // water retired after migration
    }

    func testRealBLSNationalFiguresAreSane() {
        // Real published BLS CE 2023 monthly figures.
        XCTAssertEqual(BenchmarksLoader.officialNationalTransportationMonthly, 13174.0 / 12, accuracy: 0.01)
        XCTAssertEqual(BenchmarksLoader.officialNationalPersonalMonthly, (2041.0 + 3635.0 + 927.0) / 12, accuracy: 0.01)
        XCTAssertEqual(BenchmarksLoader.officialNationalWaterMonthly, 780.0 / 12, accuracy: 0.01)
        XCTAssertEqual(BenchmarksLoader.officialNationalNaturalGasMonthly, 540.0 / 12, accuracy: 0.01)
        XCTAssertEqual(BenchmarksLoader.officialNationalUtilitiesAddonMonthly, (540.0 + 780.0) / 12, accuracy: 0.01)
        XCTAssertEqual(BenchmarksLoader.officialNationalHomeUpkeepMonthly, (4079.0 + 3974.0) / 12, accuracy: 0.01)
    }
}
