import Foundation

/// One person's monthly money picture — the heart of the app.
///
/// A pure, synchronous, value-type model with **no SwiftUI import**, so it can
/// be reasoned about and previewed in isolation and can never accidentally
/// depend on a view. Colours live in `Theme`; this file only knows about
/// dollars and which situation the numbers describe.
///
/// ## The honesty rule, carried over from the county work
///
/// Every field is optional, and `status` is `nil` until there is enough to say
/// anything. This mirrors the decision in `ScoredCounty` where `index` is
/// optional rather than defaulting to zero: a half-filled plan must never render
/// as a confident green "you're okay". If we don't know the income, we don't
/// know the answer, and the model says so by returning `nil`.
///
/// ## Language rule
///
/// This is for a person who is anxious about money, not an analyst. Nothing here
/// uses the word "risk", "distress", or a grade out of 100. The output is a
/// situation ("money's tight this month") and a dollar figure ("$312 left"),
/// never a score.
struct MoneyPlan: Equatable, Sendable, Codable {

    /// Take-home pay for the month. The one figure everything is measured
    /// against — with no income there is no picture, only inputs.
    var monthlyIncome: Double?

    /// Rent or mortgage. Almost always the largest single essential, which is
    /// why it is drawn first (leftmost) in the Safe Line bar.
    var housing: Double?
    /// Ongoing costs of keeping the home itself — property tax, home insurance,
    /// repairs, landscaping, pest control. Grouped into one figure the person
    /// can enter at a glance; the input screen's info button lists what's inside.
    var homeUpkeep: Double?
    var food: Double?
    var energy: Double?
    /// Water and sewer.
    var water: Double?
    /// Getting around — car payment, gas, insurance, upkeep, transit/rideshare.
    var transportation: Double?
    /// Personal & lifestyle — clothes, entertainment, hobbies, subscriptions,
    /// personal care. The flexible spending most within a person's control.
    var personal: Double?
    /// Minimum debt payments due this month — cards, loans, financing. Not the
    /// total balance owed; what has to go out this month to stay current.
    var debtPayments: Double?

    init(
        monthlyIncome: Double? = nil,
        housing: Double? = nil,
        homeUpkeep: Double? = nil,
        food: Double? = nil,
        energy: Double? = nil,
        water: Double? = nil,
        transportation: Double? = nil,
        personal: Double? = nil,
        debtPayments: Double? = nil
    ) {
        self.monthlyIncome = monthlyIncome
        self.housing = housing
        self.homeUpkeep = homeUpkeep
        self.food = food
        self.energy = energy
        self.water = water
        self.transportation = transportation
        self.personal = personal
        self.debtPayments = debtPayments
    }

    // MARK: - Codable (with a one-way migration)

    private enum CodingKeys: String, CodingKey {
        case monthlyIncome, housing, homeUpkeep, food, energy, water,
             transportation, personal, debtPayments
    }

    /// Custom decode so an older saved plan that stored a **separate** water bill
    /// folds into `energy` — the app now collects one "Utilities" figure
    /// (electricity, gas, water, sewer, trash). New plans never write `water`;
    /// this only rescues numbers a tester entered before the two were merged.
    /// Encoding stays synthesised, so `water` is simply written as `nil` from now
    /// on and quietly disappears on the next save.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        monthlyIncome  = try c.decodeIfPresent(Double.self, forKey: .monthlyIncome)
        housing        = try c.decodeIfPresent(Double.self, forKey: .housing)
        homeUpkeep     = try c.decodeIfPresent(Double.self, forKey: .homeUpkeep)
        food           = try c.decodeIfPresent(Double.self, forKey: .food)
        let energyRaw  = try c.decodeIfPresent(Double.self, forKey: .energy)
        let waterRaw   = try c.decodeIfPresent(Double.self, forKey: .water)
        energy         = MoneyPlan.merge(energyRaw, waterRaw)
        water          = nil
        transportation = try c.decodeIfPresent(Double.self, forKey: .transportation)
        personal       = try c.decodeIfPresent(Double.self, forKey: .personal)
        debtPayments   = try c.decodeIfPresent(Double.self, forKey: .debtPayments)
    }

    /// Sum two optional amounts, staying `nil` only when *both* are absent — so a
    /// migrated water bill adds onto energy without turning a genuine blank into
    /// a misleading zero.
    private static func merge(_ a: Double?, _ b: Double?) -> Double? {
        (a == nil && b == nil) ? nil : (a ?? 0) + (b ?? 0)
    }
}

// MARK: - Essentials

/// The four essential categories, in the fixed left-to-right order they fill the
/// Safe Line bar. Order, labels, and category identity all live here so the bar,
/// the "why am I short" answers, and any future screen can never disagree about
/// what an essential is or what it's called.
enum EssentialKind: String, CaseIterable, Identifiable, Sendable {
    /// Declaration order is bar order (left → right): the home first, then the
    /// running costs, then the flexible spending, with debt last.
    case housing, homeUpkeep, food, energy, water, transportation, personal, debt

    var id: String { rawValue }

    /// Plain, unshortened labels — the words two friends would text.
    var label: String {
        switch self {
        case .housing: return "Rent or mortgage"
        case .homeUpkeep: return "Home upkeep"
        case .food: return "Food & groceries"
        case .energy: return "Utilities"
        case .water: return "Water"
        case .transportation: return "Transportation"
        case .personal: return "Personal"
        case .debt: return "Debt payments"
        }
    }

    /// What to fold into this one number — shown behind the info (ⓘ) button on
    /// the input screen, so a grouped category is never a guessing game.
    var info: String {
        switch self {
        case .housing: return "Just your monthly rent or mortgage payment."
        case .homeUpkeep: return "Property tax, home insurance, repairs, landscaping, and pest control."
        case .food: return "Groceries and eating out."
        case .energy: return "All your home utilities in one — electricity, natural gas, heating, water, sewer, and trash."
        case .water: return "Your monthly water and sewer bill."
        case .transportation: return "Car payment, gas, insurance, upkeep, and transit or rideshare."
        case .personal: return "Clothes, entertainment, hobbies, subscriptions, and personal care."
        case .debt: return "The least you must pay this month on cards, loans, and financing — not the total you owe."
        }
    }

    /// SF Symbol for the category, so its icon reads the same everywhere it
    /// appears (the compare cards, the breakdown, anywhere a category is shown).
    var symbol: String {
        switch self {
        case .housing: return "house.fill"
        case .homeUpkeep: return "wrench.and.screwdriver.fill"
        case .food: return "fork.knife"
        case .energy: return "bolt.fill"
        case .water: return "drop.fill"
        case .transportation: return "car.fill"
        case .personal: return "bag.fill"
        case .debt: return "creditcard.fill"
        }
    }
}

/// One essential's amount for the month. The bar renders these left to right in
/// `EssentialKind.allCases` order; `amount` is always a real, entered figure
/// (a category the person left blank is simply absent from `segments`).
struct EssentialSegment: Identifiable, Equatable, Sendable {
    let kind: EssentialKind
    let amount: Double

    var id: String { kind.id }
    var label: String { kind.label }
}

// MARK: - Situation

/// Where the month stands, relative to the safe line and to income.
///
/// Three states, mapped to the green / amber / red the app keeps — but the model
/// never names a colour (that's `Theme`'s job) and never says "risk". Each case
/// carries its own plain-English headline so the wording lives in exactly one
/// place.
enum MoneyStatus: String, CaseIterable, Identifiable, Sendable {
    /// Essentials sit under the safe line. Room to breathe.
    case okay
    /// Essentials are above the safe line but still within income. Nothing is
    /// overflowing, but there isn't much slack.
    case tight
    /// Essentials are more than income. The bar overflows and money left goes
    /// negative — the month doesn't cover itself.
    case over

    var id: String { rawValue }

    /// The one line shown with the result. Situation, not grade.
    var headline: String {
        switch self {
        case .okay: return "You're okay"
        case .tight: return "It's tight"
        case .over: return "Money's tight this month"
        }
    }

}

// MARK: - Computed picture

extension MoneyPlan {

    /// Where essentials should not cross — the "safe line", as a share of income.
    ///
    /// Set to 0.55 (the middle of the 50–60% guideline). This single constant
    /// decides who sees green versus amber. To make the app stricter or more
    /// lenient, change only this number.
    static let safeLineShare: Double = 0.55

    /// The one place the app weighs real dollars, not just the ratio.
    ///
    /// Essentials over the safe-line *share* usually mean a tight month — but not
    /// always. Someone who earns well can spend a little over 55% on basics and
    /// still keep a large cushion; calling that "tight" would be wrong, and it
    /// would contradict the calmer read the year-ahead odds give the same person.
    /// So a month only counts as `tight` when it clears the share *and* the
    /// dollars left fall below this comfortable cushion. Below it, an
    /// over-the-line share genuinely does read as tight.
    static let comfortableCushion: Double = 1_500

    /// The essentials that were actually entered, in bar order. A blank or zero
    /// category is left out entirely rather than drawn as an empty sliver.
    var segments: [EssentialSegment] {
        EssentialKind.allCases.compactMap { kind in
            let amount: Double? = {
                switch kind {
                case .housing: return housing
                case .homeUpkeep: return homeUpkeep
                case .food: return food
                case .energy: return energy
                case .water: return water
                case .transportation: return transportation
                case .personal: return personal
                case .debt: return debtPayments
                }
            }()
            guard let amount, amount > 0 else { return nil }
            return EssentialSegment(kind: kind, amount: amount)
        }
    }

    /// Everything essential, added up. Blank categories count as zero — but see
    /// `status`, which refuses to judge a plan with no income at all.
    var essentialsTotal: Double {
        segments.reduce(0) { $0 + $1.amount }
    }

    /// The single largest thing you pay — the biggest lever on the month.
    var biggestEssential: EssentialSegment? {
        segments.max { $0.amount < $1.amount }
    }

    /// The largest cost that usually *can* move quickly — i.e. not the fixed
    /// roof costs (rent/mortgage and home upkeep like tax and insurance), which
    /// rarely change month to month.
    var biggestMovableEssential: EssentialSegment? {
        let fixed: Set<EssentialKind> = [.housing, .homeUpkeep]
        return segments.filter { !fixed.contains($0.kind) }.max { $0.amount < $1.amount }
    }

    /// One segment's share of income, 0…1, or nil without a usable income.
    func share(of segment: EssentialSegment) -> Double? {
        guard let income = monthlyIncome, income > 0 else { return nil }
        return segment.amount / income
    }

    /// Dollars left after essentials. Negative when the month doesn't cover
    /// itself — and shown that way, because a negative number is the honest
    /// answer. `nil` only when there is no income to subtract from.
    var moneyLeft: Double? {
        guard let income = monthlyIncome, income > 0 else { return nil }
        return income - essentialsTotal
    }

    /// Essentials as a share of income, 0…1+ (can exceed 1 when overspending).
    /// `nil` without a usable income. This is the figure compared to the safe
    /// line.
    var essentialsShare: Double? {
        guard let income = monthlyIncome, income > 0 else { return nil }
        return essentialsTotal / income
    }

    /// The safe line expressed in dollars for this income — where the marker
    /// sits on the bar. `nil` without a usable income.
    var safeLineAmount: Double? {
        guard let income = monthlyIncome, income > 0 else { return nil }
        return income * Self.safeLineShare
    }

    /// The situation, or `nil` when there isn't enough to say.
    ///
    /// Requires a usable income *and* at least one essential — a plan that is
    /// only an income figure isn't yet a picture of the month. Keeping this
    /// `nil` rather than defaulting to `.okay` is the whole honesty guarantee:
    /// an empty or half-filled plan can never render as a reassuring green.
    ///
    /// Bands (share and dollars together):
    /// - `okay`  — essentials at or below the safe line, *or* above it but with a
    ///             comfortable dollar cushion still left (see `comfortableCushion`)
    /// - `tight` — above the safe line *and* the dollars left are thin
    /// - `over`  — essentials exceed income (bar overflows, money left is negative)
    ///
    /// The dollar test is the one place share isn't the whole story: it stops a
    /// well-paid month that runs a little over 55% from being mislabelled tight.
    var status: MoneyStatus? {
        guard let share = essentialsShare, let left = moneyLeft, !segments.isEmpty else { return nil }
        if share > 1.0 { return .over }
        if share > Self.safeLineShare, left < Self.comfortableCushion { return .tight }
        return .okay
    }

    /// Whether there's enough entered to show a result rather than the empty
    /// state.
    var isComplete: Bool { status != nil }
}

// MARK: - Fixtures

extension MoneyPlan {
    /// An empty plan — the first-launch state, before anything is entered.
    static let empty = MoneyPlan()

    /// Comfortably under the safe line: $4,000 income, $1,760 essentials (44%).
    /// Expect `.okay`, $2,240 left.
    static let sampleOkay = MoneyPlan(
        monthlyIncome: 4_000,
        housing: 1_200,
        food: 350,
        energy: 160,
        debtPayments: 50
    )

    /// Over the safe line but within income: $3,000 income, $1,950 essentials
    /// (65%). Expect `.tight`, $1,050 left.
    static let sampleTight = MoneyPlan(
        monthlyIncome: 3_000,
        housing: 1_400,
        food: 300,
        energy: 150,
        debtPayments: 100
    )

    /// Over the safe line on share, but comfortable in dollars: $6,000 income,
    /// $3,600 essentials (60%), $2,400 left. Expect `.okay` — the dollar cushion
    /// keeps a well-paid, slightly-over-line month from reading as tight.
    static let sampleComfortableOverLine = MoneyPlan(
        monthlyIncome: 6_000,
        housing: 2_400,
        food: 700,
        energy: 250,
        debtPayments: 250
    )

    /// Spending more than the month brings in: $2,500 income, $2,750 essentials
    /// (110%). Expect `.over`, −$250 left.
    static let sampleOver = MoneyPlan(
        monthlyIncome: 2_500,
        housing: 1_800,
        food: 400,
        energy: 250,
        debtPayments: 300
    )
}
