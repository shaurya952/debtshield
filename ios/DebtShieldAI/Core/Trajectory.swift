import Foundation

/// The app's differentiator: a calm, deterministic read of *where the months are
/// heading* — so a person learns they're drifting toward debt before they get
/// there, not after.
///
/// It is not a generative guess and not a promise. It fits a straight line to
/// the money-left of recent months and projects it forward, always framed as
/// "if this keeps up". Every figure is computed from the person's own numbers,
/// on the device — nothing a chatbot could reliably do, and nothing that needs
/// a bank login.
struct Trajectory: Equatable, Sendable {
    enum Direction: Equatable, Sendable {
        case improving   // money left is climbing
        case steady      // roughly flat
        case slipping    // falling, but still positive — the warning zone
        case underwater  // already short
    }

    let direction: Direction
    /// Average change in money-left per month (signed).
    let perMonth: Double
    /// Months until money-left would reach zero, when slipping.
    let monthsToShort: Int?
    /// The month key that projection lands on, when slipping.
    let shortMonthKey: String?
    /// Projected money-left next month.
    let projectedNext: Double

    let headline: String
    let detail: String
}

enum TrajectoryEngine {

    /// Within this much change per month reads as "holding steady".
    static let steadyBand = 40.0

    /// Reads the heading from money-left across months, oldest to newest (the
    /// last value is the current month). Returns nil until there are at least
    /// three months — fewer than that isn't a trend, just two dots.
    static func read(moneyLeft values: [Double], currentMonthKey: String) -> Trajectory? {
        guard values.count >= 3 else { return nil }

        let slope = leastSquaresSlope(values)
        let current = values.last ?? 0
        let projectedNext = current + slope

        let direction: Trajectory.Direction
        var monthsToShort: Int?
        var shortMonthKey: String?

        if current < 0 {
            direction = .underwater
        } else if slope < -steadyBand {
            direction = .slipping
            let months = Int(ceil(current / -slope))
            monthsToShort = max(1, months)
            shortMonthKey = MonthRecord.addMonths(max(1, months), to: currentMonthKey)
        } else if slope > steadyBand {
            direction = .improving
        } else {
            direction = .steady
        }

        let (headline, detail) = message(
            direction: direction,
            perMonth: slope,
            current: current,
            projectedNext: projectedNext,
            monthsToShort: monthsToShort,
            shortMonthKey: shortMonthKey
        )

        return Trajectory(
            direction: direction,
            perMonth: slope,
            monthsToShort: monthsToShort,
            shortMonthKey: shortMonthKey,
            projectedNext: projectedNext,
            headline: headline,
            detail: detail
        )
    }

    // MARK: - Line fit

    /// Least-squares slope of the values against their index — robust to a
    /// single noisy month in a way that "last minus first" isn't.
    private static func leastSquaresSlope(_ values: [Double]) -> Double {
        let n = Double(values.count)
        let xs = (0..<values.count).map(Double.init)
        let meanX = xs.reduce(0, +) / n
        let meanY = values.reduce(0, +) / n
        let numerator = zip(xs, values).reduce(0.0) { $0 + ($1.0 - meanX) * ($1.1 - meanY) }
        let denominator = xs.reduce(0.0) { $0 + ($1 - meanX) * ($1 - meanX) }
        return denominator == 0 ? 0 : numerator / denominator
    }

    // MARK: - Wording

    private static func message(
        direction: Trajectory.Direction,
        perMonth: Double,
        current: Double,
        projectedNext: Double,
        monthsToShort: Int?,
        shortMonthKey: String?
    ) -> (String, String) {
        let step = money(abs(perMonth))
        switch direction {
        case .slipping:
            let when = shortMonthKey.map { MonthRecord.label(for: $0) } ?? "soon"
            let headline = "Heads up — you're drifting toward the edge."
            var detail = "Your money left has been falling about \(step) a month. If that keeps up, you'd be short around **\(when)**."
            if let m = monthsToShort {
                detail += " That's about \(m) month\(m == 1 ? "" : "s") away."
            }
            detail += " Trimming your biggest cost now is the surest way to change course — the sooner, the easier."
            return (headline, detail)

        case .underwater:
            if perMonth < -TrajectoryEngine.steadyBand {
                return ("You're short, and the gap is growing.",
                        "You're spending more than you bring in, and it's widening about \(step) a month. This is the moment to act — ask below for the fastest lever.")
            } else if perMonth > TrajectoryEngine.steadyBand {
                return ("You're short, but climbing back.",
                        "You're still short this month, but the gap is shrinking about \(step) a month. Keep going — you're heading the right way.")
            } else {
                return ("You're short, and holding there.",
                        "You've been about the same each month, still short. A small, steady cut to your biggest cost is what turns this around.")
            }

        case .improving:
            let next = money(max(0, projectedNext))
            return ("You're heading the right way.",
                    "Your money left has grown about \(step) a month. Keep this pace and you'd have around \(next) of room next month. This is how a cushion gets built.")

        case .steady:
            let level = money(max(0, current))
            return ("You're holding steady.",
                    "About the same each month — roughly \(level) left. Steady is a good place to be. A small change to your biggest cost could start building a cushion.")
        }
    }

    private static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
