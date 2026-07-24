import Foundation

/// One person's monthly money picture — the heart of the app.
///
/// This is the personal counterpart to `RiskScoring`: a pure, synchronous,
/// value-type model with **no SwiftUI import**, so it can be reasoned about and
/// previewed in isolation and can never accidentally depend on a view. Colours
/// live in `Theme`; this file only knows about dollars and which situation the
/// numbers describe.
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
    var food: Double?
    var energy: Double?
    /// Minimum debt payments due this month — cards, loans, financing. Not the
    /// total balance owed; what has to go out this month to stay current.
    var debtPayments: Double?

    init(
        monthlyIncome: Double? = nil,
        housing: Double? = nil,
        food: Double? = nil,
        energy: Double? = nil,
        debtPayments: Double? = nil
    ) {
        self.monthlyIncome = monthlyIncome
        self.housing = housing
        self.food = food
        self.energy = energy
        self.debtPayments = debtPayments
    }
}

// MARK: - Essentials

/// The four essential categories, in the fixed left-to-right order they fill the
/// Safe Line bar. Order, labels, and category identity all live here so the bar,
/// the "why am I short" answers, and any future screen can never disagree about
/// what an essential is or what it's called.
enum EssentialKind: String, CaseIterable, Identifiable, Sendable {
    case housing, food, energy, debt

    var id: String { rawValue }

    /// Plain, unshortened labels — the words two friends would text.
    var label: String {
        switch self {
        case .housing: return "Rent or mortgage"
        case .food: return "Food"
        case .energy: return "Energy"
        case .debt: return "Debt payments"
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

    /// A distinct SF Symbol per status, so the situation is carried by shape as
    /// well as colour — it survives greyscale, colour-blindness, and VoiceOver.
    var symbolName: String {
        switch self {
        case .okay: return "checkmark.circle.fill"
        case .tight: return "equal.circle.fill"
        case .over: return "exclamationmark.triangle.fill"
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

    /// The essentials that were actually entered, in bar order. A blank or zero
    /// category is left out entirely rather than drawn as an empty sliver.
    var segments: [EssentialSegment] {
        EssentialKind.allCases.compactMap { kind in
            let amount: Double? = {
                switch kind {
                case .housing: return housing
                case .food: return food
                case .energy: return energy
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

    /// The largest cost that usually *can* move quickly — i.e. not rent or a
    /// mortgage, which rarely change month to month.
    var biggestMovableEssential: EssentialSegment? {
        segments.filter { $0.kind != .housing }.max { $0.amount < $1.amount }
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
    /// Bands (all driven by `safeLineShare`):
    /// - `okay`  — essentials at or below the safe line
    /// - `tight` — above the safe line but still within income
    /// - `over`  — essentials exceed income (bar overflows, money left is negative)
    var status: MoneyStatus? {
        guard let share = essentialsShare, !segments.isEmpty else { return nil }
        if share > 1.0 { return .over }
        if share > Self.safeLineShare { return .tight }
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
