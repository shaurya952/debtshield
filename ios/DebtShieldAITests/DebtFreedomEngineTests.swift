import XCTest
@testable import DebtShieldAI

/// "The fastest way out" — months-to-debt-free, deterministic and Monte Carlo.
final class DebtFreedomEngineTests: XCTestCase {

    func testInterestFreePayoffIsBalanceOverPayment() {
        // $12,000 at 0% APR, $1,000/mo → exactly 12 months.
        XCTAssertEqual(DebtFreedomEngine.months(balance: 12_000, aprPercent: 0, payment: 1_000), 12)
    }

    func testPaymentBelowInterestNeverPaysOff() {
        // $10,000 at 24% APR → ~$200/mo interest; paying $150 never clears it.
        XCTAssertNil(DebtFreedomEngine.months(balance: 10_000, aprPercent: 24, payment: 150))
    }

    func testInterestSlowsPayoff() {
        let noInterest = DebtFreedomEngine.months(balance: 10_000, aprPercent: 0, payment: 500)!
        let withInterest = DebtFreedomEngine.months(balance: 10_000, aprPercent: 24, payment: 500)!
        XCTAssertGreaterThan(withInterest, noInterest)
    }

    func testMorePaymentPaysFaster() {
        let slow = DebtFreedomEngine.months(balance: 10_000, aprPercent: 18, payment: 300)!
        let fast = DebtFreedomEngine.months(balance: 10_000, aprPercent: 18, payment: 600)!
        XCTAssertLessThan(fast, slow)
    }

    func testMonteCarloRangeIsOrderedAndDeterministic() {
        let a = DebtFreedomEngine.payoff(balance: 12_000, aprPercent: 12, available: 1_000)
        let b = DebtFreedomEngine.payoff(balance: 12_000, aprPercent: 12, available: 1_000)
        XCTAssertNotNil(a)
        XCTAssertEqual(a, b, "Seeded (42) — the same inputs give the same range every time.")
        if let p10 = a?.p10, let p50 = a?.p50, let p90 = a?.p90 {
            XCTAssertLessThanOrEqual(p10, p50)
            XCTAssertLessThanOrEqual(p50, p90)
        } else { XCTFail("A comfortably-payable debt should produce a Monte Carlo range.") }
        XCTAssertEqual(a?.countsInterest, true)
    }

    func testAvailableTowardCombinesMinimumAndLeftover() {
        XCTAssertEqual(DebtFreedomEngine.availableToward(debtMin: 200, moneyLeft: 800), 1_000)
        XCTAssertEqual(DebtFreedomEngine.availableToward(debtMin: nil, moneyLeft: nil), 0)
    }

    func testNoBalanceNoPayoff() {
        XCTAssertNil(DebtFreedomEngine.payoff(balance: 0, aprPercent: 20, available: 500))
    }
}
