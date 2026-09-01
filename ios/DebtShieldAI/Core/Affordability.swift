import Foundation

/// The housing-decision engine — the app's most defensible feature.
///
/// Given a real place, it uses that place's *actual* typical rent (Census) and
/// energy bill (EIA), combines them with the person's own income, food and debt,
/// and works out — deterministically — whether living there is affordable, the
/// most rent they could pay and stay safe, and the income they'd need. None of
/// it is a guess: a chat model would invent the local figures and can't see the
/// private budget; this computes from real bundled data on the device.
struct MoveOutlook: Equatable, Sendable {
    enum Tone: Equatable, Sendable { case good, tight, over }

    let placeName: String
    let placeState: String
    let typicalRent: Double
    let typicalEnergy: Double?

    /// The person's plan as it would be living there.
    let projected: MoneyPlan
    let projectedLeft: Double
    /// Money left where they are now, for the side-by-side.
    let currentLeft: Double?

    /// The most rent they could pay here and keep essentials under the safe line.
    /// Negative when their other costs already exceed the line.
    let maxAffordableRent: Double
    /// The income at which typical rent here fits under the safe line.
    let incomeNeeded: Double

    let tone: Tone
    let headline: String
    let detail: String
}

enum AffordabilityEngine {

    /// Projects a move to `place`. `stateEnergy` is that place's state bill (EIA);
    /// `incomeOverride` lets the person model a new job's pay.
    static func outlook(
        current: MoneyPlan,
        place: ScoredCounty,
        stateEnergy: Double?,
        incomeOverride: Double?
    ) -> MoveOutlook? {
        guard let rent = place.record.medianGrossRent, rent > 0,
              let income = incomeOverride ?? current.monthlyIncome, income > 0 else { return nil }

        // Census "median gross rent" already includes the renter's utilities
        // (electricity, gas, water, sewer, fuels). So this one figure covers
        // housing *and* utilities — adding a separate energy cost on top would
        // double-count utilities in every money-left number. We therefore fold
        // utilities into the rent and keep `stateEnergy` only as context (roughly
        // how much of that rent is utilities), never as an added-on cost.
        var projected = current
        projected.monthlyIncome = income
        projected.housing = rent
        projected.energy = 0

        let left = income - projected.essentialsTotal
        // Everything that isn't the housing+utilities figure we're solving for —
        // food, transport, personal, upkeep and debt — so "max rent" and "income
        // needed" account for the whole month, not just food and debt.
        let nonHousing = projected.essentialsTotal - rent
        let maxAffordableRent = income * MoneyPlan.safeLineShare - nonHousing
        let incomeNeeded = (rent + nonHousing) / MoneyPlan.safeLineShare

        let tone: MoveOutlook.Tone
        let headline: String
        let detail: String
        let rentText = money(rent)
        // The costs this estimate does *not* yet vary by place — named plainly so a
        // green result never reads as a full affordability verdict.
        let excluded = "Local costs like transport, state taxes and insurance aren't in this yet, so treat it as perspective, not a full affordability check."

        if left < 0 {
            tone = .over
            headline = "This move would stretch you thin"
            detail = "In \(place.county), typical rent — utilities included — runs about \(rentText) a month. With your income and other costs, you'd be about \(money(-left)) short each month here. \(excluded)"
        } else if projected.status == .tight {
            tone = .tight
            headline = "It could work here, but it'd be tight"
            detail = "You'd have about \(money(left)) left each month — covered, but not much room. \(excluded)"
        } else {
            tone = .good
            headline = "Your basics would fit here"
            detail = "You'd have about \(money(left)) left each month — a comfortable cushion, counting rent (utilities included), your food and your debt. \(excluded)"
        }

        return MoveOutlook(
            placeName: place.county,
            placeState: place.state,
            typicalRent: rent,
            typicalEnergy: stateEnergy ?? current.energy,
            projected: projected,
            projectedLeft: left,
            currentLeft: current.moneyLeft,
            maxAffordableRent: maxAffordableRent,
            incomeNeeded: incomeNeeded,
            tone: tone,
            headline: headline,
            detail: detail
        )
    }

    private static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}
