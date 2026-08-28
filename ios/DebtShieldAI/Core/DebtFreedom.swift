import Foundation

/// "The fastest way out" — how soon the debt is gone, and how a place changes that.
///
/// This is the capstone that ties the whole app together: moving somewhere cheaper
/// (or where your job pays more) frees up money, and every spare dollar clears debt
/// faster. Given a balance, its rate, and the amount you could put toward it each
/// month, it computes **months to debt-free** — deterministically, plus a Monte
/// Carlo range because real months wobble. It's the affordability engine + the
/// mobility/pay data + the simulation, all pointed back at debt.
///
/// Pure and synchronous, no SwiftUI. Nothing here is a guess — no balance, no
/// feature; no rate, it says it isn't counting interest.
enum DebtFreedomEngine {

    static let mcRuns = 300
    static let seed: UInt64 = 42
    /// Month-to-month wobble in what's actually free for debt.
    static let surplusCV = 0.15
    static let surpriseChance = 0.15
    static let surpriseMean = 300.0
    /// Anything past this reads as "not really in reach".
    static let maxMonths = 1200

    struct Payoff: Equatable, Sendable {
        /// Months at a steady payment. `nil` when the payment can't overtake
        /// interest (never paid off) or the balance is already clear.
        let months: Int?
        /// Monte Carlo range on the payoff month — fastest / most-likely / slowest.
        let p10: Int?
        let p50: Int?
        let p90: Int?
        /// Whether interest was part of the math (false when no rate was given).
        let countsInterest: Bool
    }

    /// Deterministic months to clear `balance` paying `payment` per month at
    /// `aprPercent` (annual %). `nil` if the payment never overtakes interest.
    static func months(balance: Double, aprPercent: Double?, payment: Double) -> Int? {
        guard balance > 0 else { return balance <= 0 ? 0 : nil }
        guard payment > 0 else { return nil }
        let r = max(0, aprPercent ?? 0) / 100 / 12
        if r > 0, payment <= balance * r { return nil }   // interest ≥ payment → never
        var b = balance, m = 0
        while b > 0 && m < maxMonths { b = b * (1 + r) - payment; m += 1 }
        return b <= 0 ? m : nil
    }

    /// The full payoff picture for a monthly amount you could put toward debt.
    static func payoff(balance: Double, aprPercent: Double?, available: Double) -> Payoff? {
        guard balance > 0 else { return nil }
        let r = max(0, aprPercent ?? 0) / 100 / 12
        let deterministic = months(balance: balance, aprPercent: aprPercent, payment: available)

        var rng = SplitMix64(seed: seed)
        var finishes: [Int] = []
        finishes.reserveCapacity(mcRuns)
        for _ in 0..<mcRuns {
            var b = balance, m = 0
            while b > 0 && m < maxMonths {
                var pay = gauss(mean: available, sd: abs(available) * surplusCV, &rng)
                if Double.random(in: 0...1, using: &rng) < surpriseChance {
                    pay -= max(0, gauss(mean: surpriseMean, sd: surpriseMean * 0.5, &rng))
                }
                b = b * (1 + r) - max(0, pay)
                m += 1
            }
            if b <= 0 { finishes.append(m) }
        }
        finishes.sort()

        func pct(_ p: Double) -> Int? {
            guard finishes.count >= mcRuns / 2 else { return nil }   // most runs must finish
            let idx = Int((p / 100 * Double(finishes.count - 1)).rounded())
            return finishes[min(max(0, idx), finishes.count - 1)]
        }

        return Payoff(months: deterministic, p10: pct(10), p50: pct(50), p90: pct(90),
                      countsInterest: (aprPercent ?? 0) > 0)
    }

    /// The monthly amount that could attack the balance: the minimum payment plus
    /// whatever's left over (the "throw everything spare at it" assumption).
    static func availableToward(debtMin: Double?, moneyLeft: Double?) -> Double {
        (debtMin ?? 0) + (moneyLeft ?? 0)
    }

    // MARK: - Small seeded RNG (kept local so the engine stays self-contained)

    struct SplitMix64: RandomNumberGenerator {
        private var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
    }

    static func gauss(mean: Double, sd: Double, _ rng: inout SplitMix64) -> Double {
        guard sd > 0 else { return mean }
        let u1 = Double.random(in: 1e-9...1, using: &rng)
        let u2 = Double.random(in: 0...1, using: &rng)
        let z = (-2 * Foundation.log(u1)).squareRoot() * Foundation.cos(2 * Double.pi * u2)
        return mean + z * sd
    }
}
