import XCTest
@testable import DebtShieldAI

/// Covers the month-by-month paths the year-ahead chart draws. The chart is
/// only as honest as these series, so they are checked for shape, ordering and
/// determinism rather than for specific dollar values.
final class MonteCarloPathTests: XCTestCase {

    /// A comfortable month: $5,000 in, $2,550 of essentials.
    private var comfortable: MoneyPlan {
        MoneyPlan(monthlyIncome: 5000, housing: 1400, food: 600, energy: 250, debtPayments: 300)
    }

    /// Short every month: essentials exceed income.
    private var underwater: MoneyPlan {
        MoneyPlan(monthlyIncome: 2000, housing: 1600, food: 600, energy: 250, debtPayments: 300)
    }

    private func run(_ plan: MoneyPlan, seed: UInt64 = 42) -> MonteCarloResult? {
        MonteCarloEngine.simulate(plan: plan, history: [], seed: seed)
    }

    func testPathsHaveOneValuePerMonthOfTheHorizon() throws {
        let r = try XCTUnwrap(run(comfortable))
        XCTAssertEqual(r.medianPath.count, MonteCarloEngine.horizonMonths)
        XCTAssertEqual(r.lowPath.count, MonteCarloEngine.horizonMonths)
        XCTAssertEqual(r.highPath.count, MonteCarloEngine.horizonMonths)
    }

    func testBandEnclosesTheMedianEveryMonth() throws {
        let r = try XCTUnwrap(run(comfortable))
        for month in r.medianPath.indices {
            XCTAssertLessThanOrEqual(r.lowPath[month], r.medianPath[month],
                                     "p25 should not exceed the median in month \(month + 1)")
            XCTAssertLessThanOrEqual(r.medianPath[month], r.highPath[month],
                                     "median should not exceed p75 in month \(month + 1)")
        }
    }

    func testTheFinalMedianMatchesTheTwelveMonthPercentile() throws {
        let r = try XCTUnwrap(run(comfortable))
        // The last point of the path and the existing 12-month percentile are
        // the same quantity; if they ever diverge the chart is lying.
        XCTAssertEqual(try XCTUnwrap(r.medianPath.last), r.p50_12mo, accuracy: 0.0001)
    }

    func testAComfortablePlanClimbsAcrossTheYear() throws {
        let r = try XCTUnwrap(run(comfortable))
        let first = try XCTUnwrap(r.medianPath.first)
        let last = try XCTUnwrap(r.medianPath.last)
        XCTAssertGreaterThan(last, first, "money left over should accumulate")
        XCTAssertTrue(r.medianPath.allSatisfy { $0 > 0 }, "should never dip below zero")
    }

    func testAnUnderwaterPlanFallsBelowZeroAndKeepsFalling() throws {
        let r = try XCTUnwrap(run(underwater))
        let last = try XCTUnwrap(r.medianPath.last)
        XCTAssertLessThan(last, 0, "a plan that is short every month should end negative")
        XCTAssertLessThan(last, try XCTUnwrap(r.medianPath.first), "and should keep falling")
    }

    func testPathsAreDeterministicForTheSameSeed() throws {
        let a = try XCTUnwrap(run(comfortable, seed: 42))
        let b = try XCTUnwrap(run(comfortable, seed: 42))
        XCTAssertEqual(a.medianPath, b.medianPath)
        XCTAssertEqual(a.lowPath, b.lowPath)
        XCTAssertEqual(a.highPath, b.highPath)
    }

    func testADifferentSeedGivesADifferentPath() throws {
        let a = try XCTUnwrap(run(comfortable, seed: 42))
        let b = try XCTUnwrap(run(comfortable, seed: 7))
        XCTAssertNotEqual(a.medianPath, b.medianPath,
                          "different seeds should explore different runs")
    }

    func testAnIncompletePlanProducesNoResult() {
        XCTAssertNil(MonteCarloEngine.simulate(plan: .empty, history: [], seed: 42))
    }
}
