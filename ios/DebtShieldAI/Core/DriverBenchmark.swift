import Foundation

/// National distribution of one driver's scores, used to say where a county
/// sits relative to every other county.
///
/// This exists because absolute driver scores are misleading on this dataset.
/// Housing has a median of 10.5 and a 90th percentile of 20.7 — largely because
/// the eviction sub-component has no data source and contributes a permanent
/// zero, compressing the whole scale. A county scoring 20.7 on housing "sounds"
/// low but is worse than 90% of the country.
///
/// The Streamlit app fired recommendations at a fixed score of 50, which on
/// this data means housing recommendations reach 2 counties out of 3,142 and
/// 85% of counties receive nothing but a generic monitoring message. Ranking
/// against the national distribution fixes that without touching the index.
struct DriverBenchmark: Sendable, Equatable {
    /// Ascending.
    let sortedScores: [Double]

    init(scores: [Double]) {
        sortedScores = scores.sorted()
    }

    /// Share of counties scoring strictly lower, 0–100.
    func percentile(of score: Double) -> Double {
        guard !sortedScores.isEmpty else { return 0 }
        // Binary search for the first index whose value is >= score.
        var low = 0
        var high = sortedScores.count
        while low < high {
            let mid = (low + high) / 2
            if sortedScores[mid] < score { low = mid + 1 } else { high = mid }
        }
        return Double(low) / Double(sortedScores.count) * 100
    }

    var median: Double {
        guard !sortedScores.isEmpty else { return 0 }
        let mid = sortedScores.count / 2
        if sortedScores.count.isMultiple(of: 2) {
            return (sortedScores[mid - 1] + sortedScores[mid]) / 2
        }
        return sortedScores[mid]
    }
}

/// Turns a percentile into words.
///
/// Single source of truth on purpose. This phrasing lives on both the Risk
/// Drivers screen and the Recommendations screen, and when the two screens each
/// had their own copy they drifted — one was fixed and the other kept telling
/// users a county was "worse than 100% of U.S. counties".
///
/// The rounding rule matters: a percentile of 99.7 *displays* as 100, so the
/// decision has to be made on the rounded figure the reader actually sees, not
/// on the raw value.
enum PercentilePhrasing {

    /// e.g. "worse than 87% of U.S. counties".
    static func comparison(_ percentile: Double) -> String {
        let shown = Int(percentile.rounded())
        if shown >= 100 { return "worse than nearly every U.S. county" }
        if shown <= 0 { return "among the lowest of any U.S. county" }
        return "worse than \(shown)% of U.S. counties"
    }

    /// Sentence-cased form for starting a sentence.
    static func comparisonCapitalised(_ percentile: Double) -> String {
        let text = comparison(percentile)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    /// Fits "a higher score than ___": "30% of them", "nearly all of them".
    static func shareOfThem(_ percentile: Double) -> String {
        let shown = Int(percentile.rounded())
        if shown >= 100 { return "nearly all of them" }
        if shown <= 0 { return "almost none of them" }
        return "\(shown)% of them"
    }
}

/// How pressing a driver is for a county, judged against the nation rather than
/// against a fixed number.
enum DriverSeverity: String, CaseIterable, Sendable {
    case critical
    case elevated
    case typical
    case low

    /// Thresholds are national percentiles.
    static func from(percentile: Double) -> DriverSeverity {
        if percentile >= 90 { return .critical }
        if percentile >= 75 { return .elevated }
        if percentile >= 50 { return .typical }
        return .low
    }

    var label: String {
        switch self {
        case .critical: return "Among the worst in the country"
        case .elevated: return "Worse than most counties"
        case .typical: return "Around the national middle"
        case .low: return "Better than most counties"
        }
    }

    /// Short form for badges.
    var shortLabel: String {
        switch self {
        case .critical: return "Critical"
        case .elevated: return "Elevated"
        case .typical: return "Typical"
        case .low: return "Lower"
        }
    }

    var symbolName: String {
        switch self {
        case .critical: return "exclamationmark.octagon.fill"
        case .elevated: return "exclamationmark.triangle.fill"
        case .typical: return "equal.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }

    /// Drivers at or above this level are worth acting on.
    var warrantsAction: Bool {
        self == .critical || self == .elevated
    }
}

/// A driver score placed in national context.
struct DriverStanding: Identifiable, Sendable {
    let driver: DriverScore
    let percentile: Double
    let nationalMedian: Double

    var id: String { driver.id }
    var kind: DriverKind { driver.kind }
    var score: Double { driver.score }
    var severity: DriverSeverity { .from(percentile: percentile) }

    /// "Worse than 91% of U.S. counties" — the number that actually means
    /// something to a reader, in plain words.
    ///
    /// The top-scoring county is described rather than given a percentage: it
    /// is not "worse than 100% of counties", because it is not worse than
    /// itself.
    var comparisonSentence: String {
        "\(PercentilePhrasing.comparisonCapitalised(percentile)). The national median is \(nationalMedian.scoreText)."
    }
}
