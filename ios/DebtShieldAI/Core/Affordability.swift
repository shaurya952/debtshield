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

        let energy = stateEnergy ?? current.energy
        let food = current.food
        let debt = current.debtPayments

        var projected = current
        projected.monthlyIncome = income
        projected.housing = rent
        projected.energy = energy

        let left = projected.moneyLeft ?? (income - projected.essentialsTotal)
        let otherEssentials = (food ?? 0) + (energy ?? 0) + (debt ?? 0)
        let maxAffordableRent = income * MoneyPlan.safeLineShare - otherEssentials
        let incomeNeeded = (rent + otherEssentials) / MoneyPlan.safeLineShare

        let tone: MoveOutlook.Tone
        let headline: String
        let detail: String
        let rentText = money(rent)
        let energyText = energy.map { money($0) } ?? "a typical bill"

        if left < 0 {
            tone = .over
            headline = "This move would tip you into the red"
            detail = "In \(place.county), typical rent is \(rentText) a month and energy runs about \(energyText). With your income and other costs, you'd be about \(money(-left)) short every month — this move would push you into debt."
        } else if projected.status == .tight {
            tone = .tight
            headline = "You could live here, but it'd be tight"
            detail = "You'd have about \(money(left)) left each month — covered, but not much room. To stay comfortably under your safe line, rent here would need to be under about \(money(max(0, maxAffordableRent)))."
        } else {
            tone = .good
            headline = "You could afford to live here"
            detail = "You'd have about \(money(left)) left each month — comfortable. You could go up to about \(money(max(0, maxAffordableRent))) in rent here and still stay under your safe line."
        }

        return MoveOutlook(
            placeName: place.county,
            placeState: place.state,
            typicalRent: rent,
            typicalEnergy: energy,
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
