import Foundation

/// How one of the person's costs stacks up against typical spending.
///
/// The everyday standings (`below` / `about` / `above`) are **neutral** — paying
/// more than typical isn't a failing, it's just information — so the UI colours
/// them plainly. Only debt, measured against an affordability guideline, carries
/// a green/amber/red feel.
enum CostStanding: Equatable, Sendable {
    case below, about, above      // vs typical spending
    case healthy, watch, high     // vs the debt guideline
}

/// One reference point to compare against — "Your area", "Across the U.S.", or
/// the debt guideline.
struct ComparisonRef: Identifiable, Equatable, Sendable {
    let label: String
    let amount: Double
    var id: String { label }
}

/// One cost, with what you pay and the typical figures to compare it to.
struct Comparison: Identifiable, Equatable, Sendable {
    let kind: EssentialKind
    let yours: Double
    /// Typical figures, most-local first (your area, then the U.S.).
    let refs: [ComparisonRef]
    /// A plain, kind, one-line read.
    let verdict: String
    let standing: CostStanding
    let source: String

    var id: String { kind.id }

    /// The biggest bar to scale against — you or any reference.
    var peak: Double { max(yours, refs.map(\.amount).max() ?? 0, 1) }
}

/// Builds the comparisons for a plan. Pure and synchronous. A cost appears only
/// when the person entered it *and* at least one typical figure exists for it.
enum CostComparisons {

    /// Within this fraction of typical reads as "about the same".
    static let typicalBand = 0.10

    /// Debt payments are compared to this share of income — the common rule of
    /// thumb for non-housing debt (housing is counted separately here).
    static let debtHealthyShare = 0.20
    static let debtHighShare = 0.36

    static func all(plan: MoneyPlan, county: ScoredCounty?, benchmarks: Benchmarks?) -> [Comparison] {
        [housing(plan, county, benchmarks),
         energy(plan, county, benchmarks),
         food(plan, benchmarks),
         debt(plan)]
            .compactMap { $0 }
    }

    // MARK: - Each cost

    static func housing(_ plan: MoneyPlan, _ county: ScoredCounty?, _ benchmarks: Benchmarks?) -> Comparison? {
        guard let yours = plan.housing, yours > 0 else { return nil }
        var refs: [ComparisonRef] = []
        if let rent = county?.record.medianGrossRent, rent > 0 {
            refs.append(ComparisonRef(label: "Your area", amount: rent))
        }
        if let national = benchmarks?.nationalRent, national > 0 {
            refs.append(ComparisonRef(label: "Across the U.S.", amount: national))
        }
        guard !refs.isEmpty else { return nil }
        let (standing, verdict) = read(yours, refs)
        return Comparison(kind: .housing, yours: yours, refs: refs,
                          verdict: verdict, standing: standing, source: "U.S. Census, 2019–2023")
    }

    static func energy(_ plan: MoneyPlan, _ county: ScoredCounty?, _ benchmarks: Benchmarks?) -> Comparison? {
        guard let yours = plan.energy, yours > 0 else { return nil }
        var refs: [ComparisonRef] = []
        if let state = county?.state, let bill = benchmarks?.energy.typicalBill(inState: state), bill > 0 {
            refs.append(ComparisonRef(label: "Your state", amount: bill))
        }
        if let national = benchmarks?.nationalEnergy, national > 0 {
            refs.append(ComparisonRef(label: "Across the U.S.", amount: national))
        }
        guard !refs.isEmpty else { return nil }
        let (standing, verdict) = read(yours, refs)
        return Comparison(kind: .energy, yours: yours, refs: refs,
                          verdict: verdict, standing: standing, source: "EIA 2024")
    }

    static func food(_ plan: MoneyPlan, _ benchmarks: Benchmarks?) -> Comparison? {
        guard let yours = plan.food, yours > 0,
              let income = plan.monthlyIncome, income > 0,
              let typical = benchmarks?.food.typicalMonthly(forMonthlyIncome: income), typical > 0
        else { return nil }
        // Food has no local dimension in the data, so the two references are the
        // BLS typical for this income and the all-households U.S. average.
        var refs = [ComparisonRef(label: "Typical for your income", amount: typical)]
        if let national = benchmarks?.nationalFood, national > 0 {
            refs.append(ComparisonRef(label: "Across the U.S.", amount: national))
        }
        let (standing, verdict) = read(yours, refs)
        return Comparison(kind: .food, yours: yours, refs: refs,
                          verdict: verdict, standing: standing, source: "BLS 2023")
    }

    static func debt(_ plan: MoneyPlan) -> Comparison? {
        guard let yours = plan.debtPayments, yours > 0,
              let income = plan.monthlyIncome, income > 0 else { return nil }
        let share = yours / income
        let pct = Int((share * 100).rounded())
        let guideline = income * debtHealthyShare
        let standing: CostStanding
        let verdict: String
        if share <= debtHealthyShare {
            standing = .healthy
            verdict = "Comfortable — that's \(pct)% of your income, under the 20% guideline."
        } else if share <= debtHighShare {
            standing = .watch
            verdict = "Getting high — that's \(pct)% of your income. Worth keeping an eye on."
        } else {
            standing = .high
            verdict = "High — \(pct)% of your income goes to debt payments."
        }
        return Comparison(kind: .debt, yours: yours,
                          refs: [ComparisonRef(label: "Healthy guideline (20%)", amount: guideline)],
                          verdict: verdict, standing: standing, source: "20% rule of thumb")
    }

    // MARK: - Reading a comparison

    /// Compares what you pay to the most-local typical, and writes a plain,
    /// kind verdict — mentioning both area and national when they point the
    /// same way.
    private static func read(_ yours: Double, _ refs: [ComparisonRef]) -> (CostStanding, String) {
        let primary = refs[0].amount
        let ratio = (yours - primary) / primary
        if ratio > typicalBand {
            return (.above, "You spend more than most.")
        }
        if ratio < -typicalBand {
            return (.below, "You spend less than most.")
        }
        return (.about, "About the same as most.")
    }
}
