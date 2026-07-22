import Foundation

/// Compares what a person pays for housing against the typical rent where they
/// live. Pure and synchronous — no UI, no data source of its own; it's handed
/// the two figures and works out how they relate.
///
/// The tone is a marker, not a verdict: rent varies enormously within any one
/// county, so this says "higher / lower / about typical" and leaves the judging
/// to the person. It never calls anyone's rent good or bad.
struct HousingComparison: Equatable {
    /// What the person pays each month (rent or mortgage).
    let yours: Double
    /// The county's median gross rent, monthly.
    let typical: Double
    /// The county name, for the sentence.
    let areaName: String

    /// Anything within this fraction of typical reads as "about typical" —
    /// housing is too variable to call a 5% gap meaningful.
    static let typicalBand = 0.10

    enum Standing: Equatable {
        case higher, lower, about
    }

    var difference: Double { yours - typical }

    var standing: Standing {
        guard typical > 0 else { return .about }
        let ratio = (yours - typical) / typical
        if ratio > Self.typicalBand { return .higher }
        if ratio < -Self.typicalBand { return .lower }
        return .about
    }

    /// A calm, plain sentence. Dollars, no grade.
    var sentence: String {
        let gap = money(abs(difference))
        switch standing {
        case .higher:
            return "You're paying about \(gap) more a month than the typical rent in \(areaName)."
        case .lower:
            return "You're paying about \(gap) less a month than the typical rent in \(areaName)."
        case .about:
            return "That's about the typical rent for \(areaName)."
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
