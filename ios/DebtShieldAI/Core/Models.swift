import Foundation

extension Double {
    /// One decimal place, the house style for every score in the app.
    ///
    /// Lives here rather than in `Theme` so the scoring layer stays free of any
    /// UI framework import — which is what lets it be tested headlessly.
    var scoreText: String {
        formatted(.number.precision(.fractionLength(1)))
    }
}

// MARK: - Risk level

/// Risk banding for the Financial Distress Index.
///
/// Accessibility note: risk is never communicated by colour alone. Every
/// presentation of a `RiskLevel` pairs the colour with `label` text and
/// `symbolName` (an SF Symbol shape), so the meaning survives greyscale,
/// colour-blindness, and VoiceOver.
enum RiskLevel: String, CaseIterable, Identifiable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var id: String { rawValue }

    /// Thresholds mirror `risk_label()` in debtshield_streamlit_app.py exactly.
    static func from(index: Double) -> RiskLevel {
        if index < 35 { return .low }
        if index < 65 { return .medium }
        return .high
    }

    var label: String { rawValue }

    /// Distinct shapes, not just distinct colours.
    var symbolName: String {
        switch self {
        case .low: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        }
    }

    /// Plain-English meaning, reused by the dashboard legend and VoiceOver.
    var plainEnglish: String {
        switch self {
        case .low:
            return "Financial pressure is below typical levels for counties in this dataset."
        case .medium:
            return "There is some meaningful financial pressure, but it is not severe or compounding."
        case .high:
            return "There is severe financial pressure, usually compounding across several categories."
        }
    }
}

// MARK: - Drivers

/// The five stress categories that make up the Financial Distress Index.
enum DriverKind: String, CaseIterable, Identifiable, Sendable {
    case housing, debt, cost, energy, food

    var id: String { rawValue }

    var title: String {
        switch self {
        case .housing: return "Housing"
        case .debt: return "Debt"
        case .cost: return "Cost of Living"
        case .energy: return "Energy"
        case .food: return "Food Access"
        }
    }

    /// "Why this matters", in one sentence a non-expert can read.
    var whyThisMatters: String {
        switch self {
        case .housing:
            return "How much of a typical paycheck goes to rent. When rent takes too much, one missed cheque can start an eviction."
        case .debt:
            return "How much households owe relative to what they earn, and how often payments are falling behind."
        case .cost:
            return "How hard it is to cover everyday basics, based on poverty and unemployment levels."
        case .energy:
            return "How much of household income goes to heating, cooling, and electricity bills."
        case .food:
            return "How easy it is to reach an affordable grocery store on a low income."
        }
    }

    /// Base weights from `engineer_features()` in the Streamlit app.
    var baseWeight: Double {
        switch self {
        case .housing: return 0.30
        case .debt: return 0.25
        case .cost: return 0.20
        case .energy: return 0.15
        case .food: return 0.10
        }
    }
}

/// One driver's score for one county, plus whether the underlying data source
/// is actually present in the bundled dataset.
///
/// This is the key honesty upgrade over the Streamlit version. There, a driver
/// with no source columns silently fell back to a constant default and was
/// still drawn as a bar — so every county showed an identical "Energy 45.0".
/// Here an unmeasured driver is explicitly flagged and excluded from the index.
struct DriverScore: Identifiable, Hashable, Sendable {
    let kind: DriverKind
    let score: Double
    let isMeasured: Bool

    var id: String { kind.id }
    var title: String { kind.title }
}

// MARK: - Raw dataset row

/// One row of `real_county_data.csv`, before scoring.
///
/// Optional fields are the ones the bundled dataset does not currently carry.
/// They exist so that a richer CSV can be dropped in later without touching
/// `RiskScoring` — the scoring engine already reads them.
struct CountyRecord: Identifiable, Hashable, Sendable {
    let fips: String
    let state: String
    let county: String
    let year: Int?

    // Present for almost every county — but not all. The Census publishes no
    // median household income for the very smallest counties, so these are
    // optional and a county missing them is kept and marked unscored rather
    // than dropped.
    var medianHouseholdIncome: Double?
    var medianGrossRent: Double?
    var rentBurdenPct: Double?
    var povertyRate: Double?
    var unemploymentRate: Double?

    // Not present in the bundled dataset. Reserved for future data sources.
    var evictionFilingRate: Double?
    var jobGrowthPct: Double?
    var avgHouseholdDebt: Double?
    var debtToIncomeRatio: Double?
    var creditCardDelinquencyRate: Double?
    var energyBurdenPct: Double?
    var lowIncomeLowAccessPct: Double?

    var id: String { fips }

    /// "Autauga County, Alabama" — matches the Streamlit `display_name`.
    var displayName: String { "\(county), \(state)" }
}

// MARK: - Scored county

/// A `CountyRecord` with the Financial Distress Index applied.
///
/// `index` and `riskLevel` are optional because a handful of U.S. counties are
/// too small for the Census to publish the indicators the score needs. Those
/// counties are still first-class citizens — searchable, listed, and openable —
/// they simply report "not enough data" instead of a number. Making these
/// optional rather than defaulting to zero means the compiler forces every
/// screen to decide what to show, so an unscored county can never silently
/// render as a very safe 0.0.
struct ScoredCounty: Identifiable, Hashable, Sendable {
    let record: CountyRecord
    /// Empty when the county could not be scored.
    let drivers: [DriverScore]
    let index: Double?
    let riskLevel: RiskLevel?
    /// Human-readable names of the indicators that are missing, for the UI to
    /// explain *why* there is no score.
    let missingIndicators: [String]

    var isScored: Bool { index != nil }

    var id: String { record.fips }
    var displayName: String { record.displayName }
    var county: String { record.county }
    var state: String { record.state }

    /// The highest-scoring driver among those actually measured.
    var topDriver: DriverScore? {
        drivers.filter(\.isMeasured).max { $0.score < $1.score }
    }

    func driver(_ kind: DriverKind) -> DriverScore? {
        drivers.first { $0.kind == kind }
    }

    /// A full sentence for VoiceOver, so a screen-reader user gets the same
    /// information a sighted user gets from the badge plus the number.
    var accessibilitySummary: String {
        guard let index, let riskLevel else {
            return "\(displayName). Not enough data to calculate a score."
        }
        var parts = [
            "\(displayName). \(riskLevel.label) risk.",
            "Financial Distress Index \(index.scoreText) out of 100."
        ]
        if let top = topDriver {
            parts.append("Strongest driver: \(top.title), \(top.score.scoreText) out of 100.")
        }
        return parts.joined(separator: " ")
    }
}

// MARK: - Dataset

/// Which optional data sources the loaded CSV actually contains. Drives the
/// weight renormalisation in `RiskScoring`.
struct DatasetCapabilities: Sendable, Equatable {
    var hasDebtSources: Bool = false
    var hasEnergySource: Bool = false
    var hasFoodSource: Bool = false
    var hasEvictionSource: Bool = false
    var hasJobGrowthSource: Bool = false

    /// The drivers that contribute to the index for this dataset.
    var measuredDrivers: Set<DriverKind> {
        var set: Set<DriverKind> = [.housing, .cost]
        if hasDebtSources { set.insert(.debt) }
        if hasEnergySource { set.insert(.energy) }
        if hasFoodSource { set.insert(.food) }
        return set
    }
}

/// Everything the app needs after a successful load.
struct Dataset: Sendable {
    /// Every county in the file, including any that could not be scored.
    let counties: [ScoredCounty]
    let capabilities: DatasetCapabilities
    /// e.g. "Census ACS 5-Year, 3,144 counties"
    let sourceDescription: String
    /// National score distribution per driver, computed once at load.
    let benchmarks: [DriverKind: DriverBenchmark]

    /// Places a county's drivers in national context, strongest first.
    /// Unmeasured drivers are excluded — there is nothing to rank them against.
    func standings(for county: ScoredCounty) -> [DriverStanding] {
        county.drivers
            .filter(\.isMeasured)
            .compactMap { driver in
                guard let benchmark = benchmarks[driver.kind] else { return nil }
                return DriverStanding(
                    driver: driver,
                    percentile: benchmark.percentile(of: driver.score),
                    nationalMedian: benchmark.median
                )
            }
            .sorted { $0.percentile > $1.percentile }
    }

    /// Counties with a Financial Distress Index. All statistics — averages,
    /// rankings, distribution, top and bottom tens — are computed over this
    /// subset, so an unscored county never drags an average toward zero.
    var scoredCounties: [ScoredCounty] {
        counties.filter(\.isScored)
    }

    var unscoredCounties: [ScoredCounty] {
        counties.filter { !$0.isScored }
    }

    var averageIndex: Double {
        let scored = scoredCounties.compactMap(\.index)
        guard !scored.isEmpty else { return 0 }
        return scored.reduce(0, +) / Double(scored.count)
    }

    func count(of level: RiskLevel) -> Int {
        counties.filter { $0.riskLevel == level }.count
    }

    var highestRisk: [ScoredCounty] {
        scoredCounties.sorted { ($0.index ?? 0) > ($1.index ?? 0) }
    }

    var lowestRisk: [ScoredCounty] {
        scoredCounties.sorted { ($0.index ?? 0) < ($1.index ?? 0) }
    }

    var states: [String] {
        Array(Set(counties.map(\.state))).sorted()
    }

    /// Look up a single county by its FIPS code — used by the personal housing
    /// comparison to find the typical rent where someone lives.
    func county(fips: String) -> ScoredCounty? {
        counties.first { $0.record.fips == fips }
    }

    /// 1 = highest distress. Nil for a county with no score.
    func rank(of county: ScoredCounty) -> Int? {
        guard let index = county.index else { return nil }
        return scoredCounties.filter { ($0.index ?? 0) > index }.count + 1
    }

    /// Share of scored counties scoring lower than this one, 0–100. Gives a
    /// single county a national frame of reference — something the Streamlit
    /// profile page never showed.
    func percentile(for county: ScoredCounty) -> Double? {
        guard let index = county.index else { return nil }
        let scored = scoredCounties
        guard !scored.isEmpty else { return nil }
        let lower = scored.filter { ($0.index ?? 0) < index }.count
        return Double(lower) / Double(scored.count) * 100
    }
}
