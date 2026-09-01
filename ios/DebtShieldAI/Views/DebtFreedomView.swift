import SwiftUI

/// "Where debt clears soonest" — the places your balance could be gone fastest.
///
/// The capstone: it takes the debt you owe, the amount you could put toward it
/// (your minimum plus whatever's left over), and re-runs it against every place —
/// because a cheaper home or a better-paying local job frees up money, and every
/// spare dollar clears debt faster. Each place shows months to debt-free with a
/// Monte Carlo range, and how much sooner than staying put.
struct DebtFreedomView: View {
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    let context: RankContext

    private var balance: Double? { store.plan.debtBalance.flatMap { $0 > 0 ? $0 : nil } }
    private var apr: Double? { store.plan.debtAPR }
    private var debtMin: Double? { store.plan.debtPayments }

    private var baselineAvailable: Double {
        DebtFreedomEngine.availableToward(debtMin: debtMin, moneyLeft: store.plan.moneyLeft)
    }

    /// Ranking every county and the baseline payoff are both heavy — a full-country
    /// sort plus a Monte Carlo run — so they're computed off the main thread once on
    /// appear and held here. The screen pushes instantly and fills in, instead of
    /// freezing mid-navigation while the numbers crunch.
    @State private var places: [PlaceRankingEngine.RankedPlace] = []
    @State private var baseline: DebtFreedomEngine.Payoff?
    @State private var isComputing = true

    private var baselineMonths: Int? { baseline?.p50 ?? baseline?.months }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if balance == nil {
                    needsDebt
                } else if isComputing {
                    computingCard
                } else if let balance {
                    intro
                    baselineCard(balance)
                    movingCostNote
                    header
                    VStack(spacing: Theme.Spacing.regular) {
                        ForEach(Array(places.enumerated()), id: \.element.id) { i, place in
                            DebtPlaceRow(rank: i + 1, place: place, balance: balance, apr: apr,
                                         debtMin: debtMin, baselineMonths: baselineMonths,
                                         store: store, dataStore: dataStore, benchmarks: benchmarks,
                                         income: context.income(for: place.county.state))
                        }
                    }
                    sources
                }
            }
            .padding(Theme.Spacing.comfortable).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .background { AppBackdrop() }
        .navigationTitle("Where debt clears soonest")
        .navigationBarTitleDisplayMode(.inline)
        .task { await compute() }
    }

    /// Rank the country and run the baseline payoff on a background task, then hand
    /// the results back to the view. Runs once; the inputs don't change on screen.
    private func compute() async {
        guard let balance, let dataset = dataStore.dataset else { isComputing = false; return }
        let plan = store.plan
        let energy = benchmarks.energy
        let opts = context.options(limit: 20)
        let available = baselineAvailable
        let rate = apr
        let result = await Task.detached(priority: .userInitiated) {
            () -> (places: [PlaceRankingEngine.RankedPlace], baseline: DebtFreedomEngine.Payoff?) in
            let ranked = PlaceRankingEngine.rank(plan: plan, in: dataset, energy: energy, options: opts)
            let base = DebtFreedomEngine.payoff(balance: balance, aprPercent: rate, available: available)
            return (ranked, base)
        }.value
        places = result.places
        baseline = result.baseline
        isComputing = false
    }

    private var computingCard: some View {
        HStack(spacing: Theme.Spacing.regular) {
            ProgressView()
            Text("Working out where your debt clears soonest…")
                .font(Theme.Typography.subheadline).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 140)
    }

    private var intro: some View {
        Text("Every spare dollar clears debt faster — and a cheaper place, or a better-paying local job, frees up more of them. Here's where your debt could be gone soonest if you put everything spare toward it.")
            .font(Theme.Typography.body).foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The most important caveat on this screen: a move isn't free, and for someone
    /// carrying debt that upfront cost is exactly the constraint the ranking removes.
    /// Named plainly so "clears soonest" never reads as "just move."
    private var movingCostNote: some View {
        Card {
            HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                AppIconBadge(systemImage: "exclamationmark.triangle.fill",
                             tint: Theme.statusColor(.tight), size: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text("A move isn't free")
                        .font(Theme.Typography.body.weight(.semibold))
                    Text("Moving usually costs a few thousand dollars up front — deposit, truck, time off — and needs a job waiting there. As an example, if a place saved you $300 a month, a $4,000 move would take over a year just to break even. These rankings don't include moving costs or whether the job exists locally, so treat them as perspective, not a plan.")
                        .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func baselineCard(_ balance: Double) -> some View {
        Card {
            SectionHeader(title: "Staying put")
            HStack(alignment: .firstTextBaseline) {
                Text(DebtFormat.owe(balance))
                    .font(Theme.Typography.money(.title3)).foregroundStyle(.primary)
                Spacer()
                if let m = baselineMonths {
                    Text("~\(DebtFormat.months(m))")
                        .font(Theme.Typography.money(.title3)).foregroundStyle(Theme.brand)
                } else {
                    Text("not in reach").font(Theme.Typography.subheadline).foregroundStyle(Theme.statusColor(.over))
                }
            }
            Text(baselineMonths == nil
                 ? "At your current place, what's spare each month doesn't overtake the interest. A place with more room would."
                 : "owed now · debt-free in about \(DebtFormat.months(baselineMonths!)) at your current place\(apr == nil ? " (not counting interest — add your rate for a truer estimate)" : "")")
                .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var header: some View {
        Text("Debt-free soonest").font(Theme.Typography.headline)
    }

    private var sources: some View {
        Text("Payoff assumes you put your minimum payment plus everything left over toward the balance. The range is an on-device simulation of the months ahead. Costs and pay are typical figures, not a quote — this is perspective, not advice.")
            .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true).padding(.top, Theme.Spacing.tight)
    }

    private var needsDebt: some View {
        VStack(spacing: Theme.Spacing.comfortable) {
            AppIconBadge(systemImage: "flag.checkered", size: 84)
            Text("Add what you owe").font(Theme.Typography.title).multilineTextAlignment(.center)
            Text("Enter the total you owe and its interest rate on the Home tab (under Debt), and this shows where your debt could clear soonest.")
                .font(Theme.Typography.body).foregroundStyle(Theme.secondaryText).multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.section).frame(maxWidth: .infinity).padding(.top, Theme.Spacing.section)
    }
}

/// One place, showing how soon your debt would clear there.
struct DebtPlaceRow: View {
    let rank: Int
    let place: PlaceRankingEngine.RankedPlace
    let balance: Double
    let apr: Double?
    let debtMin: Double?
    let baselineMonths: Int?
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    let income: Double?

    @State private var payoff: DebtFreedomEngine.Payoff?

    private var months: Int? { payoff?.p50 ?? payoff?.months }

    var body: some View {
        NavigationLink {
            MoveView(store: store, dataStore: dataStore, benchmarks: benchmarks,
                     initialFIPS: place.county.record.fips, initialIncome: income)
        } label: {
            HStack(spacing: Theme.Spacing.regular) {
                Text("\(rank)")
                    .font(.callout.weight(.semibold).monospacedDigit()).foregroundStyle(Theme.secondaryText)
                    .frame(width: 26, alignment: .trailing).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.county.displayName)
                        .font(Theme.Typography.body.weight(.semibold)).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let payoff, let lo = payoff.p10, let hi = payoff.p90 {
                        Text("most likely \(DebtFormat.months(lo))–\(DebtFormat.months(hi))\(soonerSuffix)")
                            .font(.caption).foregroundStyle(Theme.secondaryText)
                    } else if months == nil, payoff != nil {
                        Text("not in reach here").font(.caption).foregroundStyle(Theme.statusColor(.over))
                    } else {
                        Text("estimating…").font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                }
                Spacer(minLength: Theme.Spacing.tight)
                VStack(alignment: .trailing, spacing: 2) {
                    if let m = months {
                        Text("~\(DebtFormat.months(m))")
                            .font(Theme.Typography.money()).foregroundStyle(Theme.statusColor(.okay)).monospacedDigit()
                        Text("to debt-free").font(.caption2).foregroundStyle(Theme.secondaryText)
                    } else {
                        Text("—").foregroundStyle(Theme.secondaryText)
                    }
                }
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.6)).accessibilityHidden(true)
            }
            .padding(.vertical, Theme.Spacing.regular).padding(.horizontal, Theme.Spacing.comfortable)
            .frame(minHeight: Theme.minimumTapTarget).frame(maxWidth: .infinity)
            .background { RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(Theme.cardBackground) }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(place.county.displayName), debt-free in about \(months.map { DebtFormat.months($0) } ?? "not in reach")\(soonerSuffix)")
        }
        .buttonStyle(PressableCardStyle())
        .task(id: "\(place.id)#\(Int(place.monthlyLeft))#\(Int(balance))") {
            let available = DebtFreedomEngine.availableToward(debtMin: debtMin, moneyLeft: place.monthlyLeft)
            let b = balance, a = apr
            payoff = await Task.detached(priority: .utility) {
                DebtFreedomEngine.payoff(balance: b, aprPercent: a, available: available)
            }.value
        }
    }

    private var soonerSuffix: String {
        guard let base = baselineMonths, let m = months, base - m > 0 else { return "" }
        return " · \(DebtFormat.months(base - m)) sooner"
    }
}

enum DebtFormat {
    static func owe(_ v: Double) -> String {
        v.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
    /// Compact months → "8 mo", "1 yr 2 mo", "3 yr".
    static func months(_ m: Int) -> String {
        if m < 24 { return "\(m) mo" }
        let y = m / 12, mo = m % 12
        return mo == 0 ? "\(y) yr" : "\(y) yr \(mo) mo"
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        DebtFreedomView(store: .preview(MoneyPlan(monthlyIncome: 5000, housing: 1400, food: 600,
                                                  energy: 250, debtPayments: 300, debtBalance: 14000, debtAPR: 22)),
                        dataStore: DataStore(), benchmarks: .previewSample,
                        context: RankContext(override: 5000, byState: nil))
    }
}
#endif
