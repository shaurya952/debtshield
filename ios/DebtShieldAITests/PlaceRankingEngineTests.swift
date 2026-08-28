import XCTest
@testable import DebtShieldAI

/// The relocation-ranking engine (Phase 1). It reuses `AffordabilityEngine`, so
/// these tests focus on the ranking behaviour itself: order, filters, skips, and
/// determinism — never guessing a place without the data to back it.
final class PlaceRankingEngineTests: XCTestCase {

    // Small, fixed world so the assertions don't depend on the bundled file.
    private func world() -> (Dataset, EnergyBenchmark) {
        let energy = EnergyBenchmark(byState: ["Alpha": 150, "Beta": 150, "Gamma": 150])
        func county(_ fips: String, _ state: String, _ name: String, rent: Double?) -> ScoredCounty {
            ScoredCounty(record: CountyRecord(
                fips: fips, state: state, county: name,
                medianHouseholdIncome: 60000, medianGrossRent: rent))
        }
        let dataset = Dataset(counties: [
            county("01", "Alpha", "Aville", rent: 800),
            county("02", "Beta",  "Bville", rent: 5200),   // rent > income → negative money-left
            county("03", "Gamma", "Cville", rent: nil),    // no rent data → must be skipped
            county("04", "Alpha", "Dville", rent: 1200),
            county("05", "Alpha", "Eville", rent: 900),     // ties with Fville for tie-break test
            county("06", "Alpha", "Fville", rent: 900)
        ])
        return (dataset, energy)
    }

    private let plan = MoneyPlan(monthlyIncome: 5000, food: 400, energy: 150, debtPayments: 200)

    func testRanksByBreathingRoomMostFirst() {
        let (data, energy) = world()
        let ranked = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy)
        XCTAssertFalse(ranked.isEmpty)
        // Cheapest rent (Aville, $800) leaves the most money → ranks first.
        XCTAssertEqual(ranked.first?.county.record.fips, "01")
        // And the list is monotonically non-increasing in money-left.
        for i in 1..<ranked.count {
            XCTAssertGreaterThanOrEqual(ranked[i-1].monthlyLeft, ranked[i].monthlyLeft)
        }
    }

    func testSkipsCountiesWithNoRentData() {
        let (data, energy) = world()
        let ids = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy).map(\.county.id)
        XCTAssertFalse(ids.contains("03"), "A county with no rent must never be ranked (no guessing).")
    }

    func testRespectsLimit() {
        let (data, energy) = world()
        let ranked = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy,
                                             options: .init(limit: 2))
        XCTAssertEqual(ranked.count, 2)
        XCTAssertEqual(ranked.first?.county.id, "01")
    }

    func testStateFilterKeepsOnlyThatState() {
        let (data, energy) = world()
        let ranked = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy,
                                             options: .init(stateFilter: "Alpha"))
        XCTAssertTrue(ranked.allSatisfy { $0.county.state == "Alpha" })
        XCTAssertFalse(ranked.map(\.county.id).contains("02")) // Beta excluded
    }

    func testMinMonthlyLeftDropsUnaffordablePlaces() {
        let (data, energy) = world()
        // Floor at $0 removes any place that would put the person in the red.
        let ranked = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy,
                                             options: .init(minMonthlyLeft: 0))
        XCTAssertTrue(ranked.allSatisfy { $0.monthlyLeft >= 0 })
        XCTAssertFalse(ranked.map(\.county.id).contains("02"), "Bville ($5200 rent) is unaffordable here.")
    }

    func testDeterministicOrderAndTieBreak() {
        let (data, energy) = world()
        let a = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy).map(\.county.id)
        let b = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy).map(\.county.id)
        XCTAssertEqual(a, b, "Same inputs must always produce the same order.")
        // Eville & Fville both rent $900 → equal money-left → FIPS breaks the tie (05 before 06).
        if let e = a.firstIndex(of: "05"), let f = a.firstIndex(of: "06") {
            XCTAssertLessThan(e, f)
        } else {
            XCTFail("Both tied places should be present.")
        }
    }

    func testIncomeOverrideOpensUpMorePlaces() {
        let (data, energy) = world()
        // On $5k, Bville is negative. Model a $20k/mo job → it should clear zero.
        let rich = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy,
                                           options: .init(incomeOverride: 20000))
        let bville = rich.first { $0.county.id == "02" }
        XCTAssertNotNil(bville)
        XCTAssertGreaterThan(bville!.monthlyLeft, 0)
    }

    func testEmptyWithoutAnIncome() {
        let (data, energy) = world()
        let noIncome = MoneyPlan(housing: 1000, food: 400)
        XCTAssertTrue(PlaceRankingEngine.rank(plan: noIncome, in: data, energy: energy).isEmpty)
    }

    func testIncomeByStateAppliesPerStateAndSkipsUnlisted() {
        let (data, energy) = world()
        // Only Alpha has a salary (an occupation's local pay); Beta/Gamma have
        // none, so their counties are skipped — not guessed.
        let ranked = PlaceRankingEngine.rank(plan: plan, in: data, energy: energy,
                                             options: .init(incomeByState: ["Alpha": 6000], limit: 50))
        XCTAssertFalse(ranked.isEmpty)
        XCTAssertTrue(ranked.allSatisfy { $0.county.state == "Alpha" })
        XCTAssertFalse(ranked.map(\.county.id).contains("02")) // Beta, no wage → skipped
    }
}
