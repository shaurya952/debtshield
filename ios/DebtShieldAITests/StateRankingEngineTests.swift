import XCTest
@testable import DebtShieldAI

/// The state-level rollup. Rolls county results up to a per-state median and
/// ranks the states — the big-picture view before drilling into a county.
final class StateRankingEngineTests: XCTestCase {

    // income 5000, food 400, debt 200 → left = 4400 − rent. Utilities live inside
    // the place's gross rent, so they're never subtracted a second time.
    private let plan = MoneyPlan(monthlyIncome: 5000, food: 400, energy: 150, debtPayments: 200)

    private func world() -> (Dataset, EnergyBenchmark) {
        let energy = EnergyBenchmark(byState: ["Alpha": 150, "Beta": 150])
        func c(_ fips: String, _ state: String, _ name: String, _ rent: Double?) -> ScoredCounty {
            ScoredCounty(record: CountyRecord(fips: fips, state: state, county: name,
                                              medianHouseholdIncome: 60000, medianGrossRent: rent))
        }
        let dataset = Dataset(counties: [
            c("01", "Alpha", "Aville", 800),   // left 3600  (best of Alpha)
            c("02", "Alpha", "Bville", 1200),  // left 3200
            c("03", "Alpha", "Cville", 900),   // left 3500  (median of Alpha)
            c("10", "Beta",  "Dville", 5200),  // left −800
            c("11", "Beta",  "Eville", 1000)   // left 3400
        ])
        return (dataset, energy)
    }

    func testRanksStatesByMedianCounty() {
        let (data, energy) = world()
        let states = StateRankingEngine.rank(plan: plan, in: data, energy: energy)
        XCTAssertEqual(states.map(\.state), ["Alpha", "Beta"]) // Alpha median 3500 > Beta median 1300
        XCTAssertEqual(states.first?.medianMonthlyLeft ?? 0, 3500, accuracy: 0.5)
    }

    func testMedianOfEvenCountUsesTwoMiddleValues() {
        let (data, energy) = world()
        let beta = StateRankingEngine.rank(plan: plan, in: data, energy: energy).first { $0.state == "Beta" }
        XCTAssertNotNil(beta)
        // Beta counties: 3400 and −800 → median = (3400 − 800)/2 = 1300.
        XCTAssertEqual(beta!.medianMonthlyLeft, 1300, accuracy: 0.5)
    }

    func testCarriesBestCountyAndAffordableCounts() {
        let (data, energy) = world()
        let states = StateRankingEngine.rank(plan: plan, in: data, energy: energy)
        let alpha = states.first { $0.state == "Alpha" }!
        XCTAssertEqual(alpha.best.county.id, "01")           // cheapest rent → most room
        XCTAssertEqual(alpha.affordableCount, 3)
        XCTAssertEqual(alpha.rankedCount, 3)

        let beta = states.first { $0.state == "Beta" }!
        XCTAssertEqual(beta.affordableCount, 1)              // Dville is in the red
        XCTAssertEqual(beta.rankedCount, 2)
    }

    func testDeterministic() {
        let (data, energy) = world()
        let a = StateRankingEngine.rank(plan: plan, in: data, energy: energy).map(\.id)
        let b = StateRankingEngine.rank(plan: plan, in: data, energy: energy).map(\.id)
        XCTAssertEqual(a, b)
    }
}
