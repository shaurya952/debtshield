import XCTest
@testable import DebtShieldAI

/// The place-risk read: Monte Carlo shortfall odds → a low / watch / high band.
final class PlaceRiskEngineTests: XCTestCase {

    func testBandThresholds() {
        XCTAssertEqual(PlaceRiskEngine.level(forOdds: 0.05), .low)
        XCTAssertEqual(PlaceRiskEngine.level(forOdds: 0.15), .watch)   // boundary is inclusive
        XCTAssertEqual(PlaceRiskEngine.level(forOdds: 0.34), .watch)
        XCTAssertEqual(PlaceRiskEngine.level(forOdds: 0.35), .high)    // boundary is inclusive
        XCTAssertEqual(PlaceRiskEngine.level(forOdds: 0.90), .high)
    }

    func testComfortablePlanReadsLowRisk() {
        // Big cushion: ~$6,150 left every month → almost never goes negative.
        let safe = MoneyPlan(monthlyIncome: 8000, housing: 1000, food: 400, energy: 150, debtPayments: 100)
        XCTAssertEqual(PlaceRiskEngine.level(for: safe), .low)
    }

    func testUnderwaterPlanReadsHighRisk() {
        // Essentials ($3,050) exceed income ($3,000) → short almost every month.
        let broke = MoneyPlan(monthlyIncome: 3000, housing: 1900, food: 600, energy: 250, debtPayments: 300)
        XCTAssertEqual(PlaceRiskEngine.level(for: broke), .high)
    }

    func testDeterministic() {
        let plan = MoneyPlan(monthlyIncome: 4000, housing: 1400, food: 500, energy: 200, debtPayments: 250)
        let a = PlaceRiskEngine.shortfallOdds(for: plan)
        let b = PlaceRiskEngine.shortfallOdds(for: plan)
        XCTAssertNotNil(a)
        XCTAssertEqual(a, b, "Seeded (42) — the same place must give the same odds every time.")
    }

    func testNilWhenNotSimulatable() {
        XCTAssertNil(PlaceRiskEngine.shortfallOdds(for: MoneyPlan(housing: 1000))) // no income
    }
}
