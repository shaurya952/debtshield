import Foundation

/// Monte Carlo simulation of the months ahead — the odds engine.
///
/// A single projection (like `TrajectoryEngine`) draws one straight line. Real
/// life wobbles: some months food is high, some months a surprise bill lands.
/// This engine runs the next 6 and 12 months *many times* with that month-to-
/// month wobble, and reports how often the person would dip into debt — a
/// probability, not a single guess.
///
/// Same discipline as `MoneyPlan` / `SituationEngine`: pure, synchronous, no
/// SwiftUI, no formatting, no UI. It returns raw numbers; a view layer decides
/// how to phrase them later. And it keeps the app's honesty instinct — it
/// returns `nil` rather than a fake certainty when the inputs aren't there.
///
/// ## Where the wobble comes from — hybrid
///
/// - **Personal history** (3+ stored months): each category's spread is
///   measured from the person's own past — the mean and standard deviation of
///   their income, rent, food, energy and debt across those months (plus the
///   current month as the latest point).
/// - **National default** (fewer than 3 months): each category wobbles by a
///   sensible coefficient of variation — income steadiest, energy and food
///   swingier — plus the occasional surprise cost. All of it lives in the
///   clearly-named constants below, tunable in one place.
///
/// `MonteCarloResult.mode` reports which was used, so the UI can later say what
/// the estimate is based on.
enum MonteCarloEngine {

    static let defaultRuns = 500

    // MARK: - National-default variability (used when history is thin)
    //
    // Coefficient of variation (CV) = standard deviation ÷ mean, per category.
    // Income is the steadiest; energy swings most (seasonal heating/cooling);
    // food is moderately variable; rent/mortgage and minimum debt payments
    // barely move month to month. All tunable here, in one place.

    static let incomeCV: Double = 0.07
    static let housingCV: Double = 0.03
    static let foodCV: Double = 0.15
    static let energyCV: Double = 0.22
    static let debtCV: Double = 0.05

    /// Occasional surprise costs — car repair, medical, a broken appliance.
    /// Applied only in national-default mode; in personal-history mode the
    /// person's own measured spread already reflects their real surprises.
    static let surpriseChancePerMonth: Double = 0.15
    static let surpriseMean: Double = 300
    static let surpriseCV: Double = 0.5

    // MARK: - Entry point

    /// Simulates the months ahead. `history` is the person's stored past months
    /// (oldest or newest order doesn't matter here). `startingBalance` is any
    /// cushion they begin with — 0 by default, the honest assumption when we
    /// don't know their savings. Returns `nil` if there's nothing to simulate.
    static func simulate(
        plan: MoneyPlan,
        history: [MonthRecord],
        startingBalance: Double = 0,
        runs: Int = defaultRuns,
        seed: UInt64? = nil
    ) -> MonteCarloResult? {
        guard runs > 0,
              plan.isComplete,
              let income = plan.monthlyIncome, income > 0 else { return nil }

        let usePersonal = history.count >= 3
        let mode: VariabilityMode = usePersonal ? .personalHistory : .nationalDefault

        // One distribution per category. Income is always present; an essential
        // is simulated only if the person actually pays it.
        guard let incomeDist = dist(income, cv: incomeCV, history: history,
                                    keyPath: \.monthlyIncome, usePersonal: usePersonal) else { return nil }
        let housingDist = dist(plan.housing, cv: housingCV, history: history, keyPath: \.housing, usePersonal: usePersonal)
        let foodDist = dist(plan.food, cv: foodCV, history: history, keyPath: \.food, usePersonal: usePersonal)
        let energyDist = dist(plan.energy, cv: energyCV, history: history, keyPath: \.energy, usePersonal: usePersonal)
        let debtDist = dist(plan.debtPayments, cv: debtCV, history: history, keyPath: \.debtPayments, usePersonal: usePersonal)

        let allowSurprise = !usePersonal

        // Seeded for reproducibility; a random seed when none is given.
        var rng = SplitMix64(seed: seed ?? UInt64.random(in: UInt64.min...UInt64.max))

        var wentNegative6 = 0
        var wentNegative12 = 0
        var ending6: [Double] = []
        var ending12: [Double] = []
        ending6.reserveCapacity(runs)
        ending12.reserveCapacity(runs)

        for _ in 0..<runs {
            var balance = startingBalance
            var dippedBy6 = false
            var dippedBy12 = false

            for month in 1...12 {
                let drawnIncome = max(0, gaussian(incomeDist, &rng))
                let h = housingDist.map { max(0, gaussian($0, &rng)) }
                let f = foodDist.map { max(0, gaussian($0, &rng)) }
                let e = energyDist.map { max(0, gaussian($0, &rng)) }
                let d = debtDist.map { max(0, gaussian($0, &rng)) }

                // Apply the existing MoneyPlan math to get money-left this month.
                let monthPlan = MoneyPlan(monthlyIncome: drawnIncome, housing: h, food: f, energy: e, debtPayments: d)
                var left = monthPlan.moneyLeft ?? (drawnIncome - monthPlan.essentialsTotal)

                if allowSurprise, Double.random(in: 0...1, using: &rng) < surpriseChancePerMonth {
                    left -= max(0, gaussian(Dist(mean: surpriseMean, sd: surpriseMean * surpriseCV), &rng))
                }

                balance += left

                if balance < 0 {
                    if month <= 6 { dippedBy6 = true }
                    dippedBy12 = true
                }
                if month == 6 { ending6.append(balance) }
                if month == 12 { ending12.append(balance) }
            }

            if dippedBy6 { wentNegative6 += 1 }
            if dippedBy12 { wentNegative12 += 1 }
        }

        return MonteCarloResult(
            mode: mode,
            runs: runs,
            probNegativeWithin6mo: Double(wentNegative6) / Double(runs),
            probNegativeWithin12mo: Double(wentNegative12) / Double(runs),
            endingBalances6mo: ending6.sorted(),
            endingBalances12mo: ending12.sorted()
        )
    }

    // MARK: - Distributions

    /// One category's spread. In personal mode it's measured from the stored
    /// months (plus the current value); in national mode it's the current value
    /// wobbled by the category's coefficient of variation. Returns `nil` for a
    /// category the person doesn't pay.
    private static func dist(
        _ current: Double?,
        cv: Double,
        history: [MonthRecord],
        keyPath: KeyPath<MoneyPlan, Double?>,
        usePersonal: Bool
    ) -> Dist? {
        guard let cur = current, cur > 0 else { return nil }
        guard usePersonal else { return Dist(mean: cur, sd: cur * cv) }

        var samples = history.compactMap { $0.plan[keyPath: keyPath] }.filter { $0 >= 0 }
        samples.append(cur)
        guard samples.count >= 2 else { return Dist(mean: cur, sd: cur * cv) }

        let mean = samples.reduce(0, +) / Double(samples.count)
        let variance = samples.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(samples.count - 1)
        return Dist(mean: mean, sd: variance.squareRoot())
    }

    private struct Dist {
        let mean: Double
        let sd: Double
    }

    /// A draw from a normal distribution via Box–Muller.
    private static func gaussian<G: RandomNumberGenerator>(_ d: Dist, _ generator: inout G) -> Double {
        guard d.sd > 0 else { return d.mean }
        let u1 = Double.random(in: Double.leastNormalMagnitude...1, using: &generator)
        let u2 = Double.random(in: 0...1, using: &generator)
        let z = (-2 * Foundation.log(u1)).squareRoot() * Foundation.cos(2 * Double.pi * u2)
        return d.mean + d.sd * z
    }
}

// MARK: - Result

/// Which variability model the simulation used.
enum VariabilityMode: String, Sendable, Equatable {
    case personalHistory
    case nationalDefault
}

/// The raw simulation output — probabilities and ending-balance distributions.
/// No formatting; percentile helpers are computation, not presentation.
struct MonteCarloResult: Sendable, Equatable {
    let mode: VariabilityMode
    let runs: Int

    /// Share of runs (0…1) where the running balance went negative at any point
    /// within the first 6 / 12 months.
    let probNegativeWithin6mo: Double
    let probNegativeWithin12mo: Double

    /// Ending balances across all runs, sorted ascending — enough to read any
    /// percentile / range.
    let endingBalances6mo: [Double]
    let endingBalances12mo: [Double]

    /// The p-th percentile (0…100) of the 12-month ending balance.
    func percentile12mo(_ p: Double) -> Double { Self.percentile(endingBalances12mo, p) }
    /// The p-th percentile (0…100) of the 6-month ending balance.
    func percentile6mo(_ p: Double) -> Double { Self.percentile(endingBalances6mo, p) }

    var p10_12mo: Double { percentile12mo(10) }
    var p50_12mo: Double { percentile12mo(50) }
    var p90_12mo: Double { percentile12mo(90) }
    var p10_6mo: Double { percentile6mo(10) }
    var p50_6mo: Double { percentile6mo(50) }
    var p90_6mo: Double { percentile6mo(90) }

    /// Linear-interpolated percentile of a sorted array.
    private static func percentile(_ sorted: [Double], _ p: Double) -> Double {
        guard let first = sorted.first else { return 0 }
        guard sorted.count > 1 else { return first }
        let rank = (max(0, min(100, p)) / 100) * Double(sorted.count - 1)
        let low = Int(rank.rounded(.down))
        let high = Int(rank.rounded(.up))
        let frac = rank - Double(low)
        return sorted[low] + (sorted[high] - sorted[low]) * frac
    }
}

// MARK: - Seeded RNG

/// A small, fast, seedable generator (SplitMix64) so simulations are
/// reproducible when a seed is given.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

#if DEBUG
extension MonteCarloEngine {
    /// A text harness — runs the engine on a few sample inputs and dumps the
    /// probabilities and percentiles so the math can be eyeballed. Seeded, so
    /// the numbers are stable run to run. Not shipped.
    static func sanityDump(seed: UInt64 = 42) -> String {
        var out = ""

        func run(_ label: String, _ plan: MoneyPlan, history: [MonthRecord]) {
            guard let r = simulate(plan: plan, history: history, runs: 500, seed: seed) else {
                out += "[\(label)] → nil (not enough entered)\n\n"; return
            }
            out += "[\(label)]  mode: \(r.mode.rawValue)\n"
            out += String(format: "   P(into debt within 6 mo) = %2.0f%%   within 12 mo = %2.0f%%\n",
                          r.probNegativeWithin6mo * 100, r.probNegativeWithin12mo * 100)
            out += "   12-mo ending balance:  p10 \(money(r.p10_12mo))   p50 \(money(r.p50_12mo))   p90 \(money(r.p90_12mo))\n\n"
        }

        run("COMFORTABLE (no history)",
            MoneyPlan(monthlyIncome: 5000, housing: 1400, food: 400, energy: 150, debtPayments: 100), history: [])
        run("NEW USER, some room (no history)",
            MoneyPlan(monthlyIncome: 2800, housing: 1300, food: 350, energy: 180, debtPayments: 150), history: [])
        run("TIGHT (no history)",
            MoneyPlan(monthlyIncome: 3000, housing: 1500, food: 550, energy: 300, debtPayments: 500), history: [])
        run("OVER BUDGET (no history)",
            MoneyPlan(monthlyIncome: 2500, housing: 1500, food: 500, energy: 300, debtPayments: 400), history: [])

        let history = [
            MonthRecord(monthKey: "2026-04", plan: MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 380, energy: 210, debtPayments: 300)),
            MonthRecord(monthKey: "2026-05", plan: MoneyPlan(monthlyIncome: 3050, housing: 1400, food: 460, energy: 260, debtPayments: 300)),
            MonthRecord(monthKey: "2026-06", plan: MoneyPlan(monthlyIncome: 2950, housing: 1400, food: 520, energy: 190, debtPayments: 300))
        ]
        run("WITH 3 MONTHS HISTORY (personal)",
            MoneyPlan(monthlyIncome: 3000, housing: 1400, food: 450, energy: 230, debtPayments: 300), history: history)

        return out
    }

    private static func money(_ value: Double) -> String {
        let sign = value < 0 ? "−" : ""
        return sign + "$" + abs(value).formatted(.number.precision(.fractionLength(0)))
    }
}
#endif
