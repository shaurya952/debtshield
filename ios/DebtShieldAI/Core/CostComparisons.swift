import Foundation

/// How one of the person's costs compares to a typical figure or a guideline.
///
/// The "typical" standings (`above` / `about` / `below`) are **neutral** — being
/// above the local typical rent isn't a failing, it's just information, so the
/// UI colours them plainly. Only debt, which is measured against a real
/// affordability guideline, carries a green/amber/red feel.
enum CostStanding: Equatable, Sendable {
    case above, about, below      // vs a typical amount
    case healthy, watch, high     // vs the debt guideline
}

/// One line of the "how your costs compare" section.
struct CostComparison: Identifiable, Equatable, Sendable {
    let kind: EssentialKind
    let yours: Double
    /// The typical amount (rent / energy / food) or the guideline amount (debt).
    let benchmark: Double
    let standing: CostStanding
    /// Short trailing phrase: "$200 above typical", "about typical", "18% of income".
    let headline: String
    /// Secondary line naming the benchmark and its source.
    let detail: String

    var id: String { kind.id }
}

/// Builds the comparisons for a person's plan. Pure and synchronous; each
/// comparison appears only when the person entered that cost *and* a benchmark
/// exists for it. Everything degrades quietly to "not shown".
enum CostComparisons {

    /// A cost within this fraction of typical reads as "about typical".
    static let typicalBand = 0.10

    /// Debt payments are compared to this share of income. 20% is the common
    /// rule of thumb for *non-housing* debt — and housing is tracked
    /// separately here, so 20% is the honest yardstick for this field.
    static let debtHealthyShare = 0.20
    /// Above this share, debt reads as high regardless.
    static let debtHighShare = 0.36

    static func all(plan: MoneyPlan, county: ScoredCounty?, benchmarks: Benchmarks?) -> [CostComparison] {
        [housing(plan, county),
         energy(plan, county, benchmarks),
         food(plan, benchmarks),
         debt(plan)]
            .compactMap { $0 }
    }

    // MARK: - Each cost

    static func housing(_ plan: MoneyPlan, _ county: ScoredCounty?) -> CostComparison? {
        guard let yours = plan.housing, yours > 0,
              let county, let rent = county.record.medianGrossRent, rent > 0 else { return nil }
        let (standing, headline) = compareToTypical(yours, rent)
        return CostComparison(
            kind: .housing, yours: yours, benchmark: rent, standing: standing,
            headline: headline,
            detail: "Typical rent in \(county.county): \(money(rent)) · Census"
        )
    }

    static func energy(_ plan: MoneyPlan, _ county: ScoredCounty?, _ benchmarks: Benchmarks?) -> CostComparison? {
        guard let yours = plan.energy, yours > 0,
              let county, let typical = benchmarks?.energy.typicalBill(inState: county.state), typical > 0
        else { return nil }
        let (standing, headline) = compareToTypical(yours, typical)
        return CostComparison(
            kind: .energy, yours: yours, benchmark: typical, standing: standing,
            headline: headline,
            detail: "Typical electricity bill in \(county.state): \(money(typical)) · EIA"
        )
    }

    static func food(_ plan: MoneyPlan, _ benchmarks: Benchmarks?) -> CostComparison? {
        guard let yours = plan.food, yours > 0,
              let income = plan.monthlyIncome, income > 0,
              let typical = benchmarks?.food.typicalMonthly(forMonthlyIncome: income), typical > 0
        else { return nil }
        let (standing, headline) = compareToTypical(yours, typical)
        return CostComparison(
            kind: .food, yours: yours, benchmark: typical, standing: standing,
            headline: headline,
            detail: "Typical for your income: \(money(typical))/mo · BLS"
        )
    }

    static func debt(_ plan: MoneyPlan) -> CostComparison? {
        guard let yours = plan.debtPayments, yours > 0,
              let income = plan.monthlyIncome, income > 0 else { return nil }
        let share = yours / income
        let pct = Int((share * 100).rounded())
        let standing: CostStanding
        let detail: String
        if share <= debtHealthyShare {
            standing = .healthy
            detail = "Under \(Int(debtHealthyShare * 100))% of income is a comfortable sign"
        } else if share <= debtHighShare {
            standing = .watch
            detail = "Over a fifth of your income goes to debt — worth watching"
        } else {
            standing = .high
            detail = "Over a third of your income goes to debt payments"
        }
        return CostComparison(
            kind: .debt, yours: yours, benchmark: income * debtHealthyShare, standing: standing,
            headline: "\(pct)% of income", detail: detail
        )
    }

    // MARK: - Helpers

    private static func compareToTypical(_ yours: Double, _ typical: Double) -> (CostStanding, String) {
        let ratio = (yours - typical) / typical
        if ratio > typicalBand {
            return (.above, "\(money(yours - typical)) above typical")
        }
        if ratio < -typicalBand {
            return (.below, "\(money(typical - yours)) below typical")
        }
        return (.about, "about typical")
    }

    private static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
