import SwiftUI

/// Places — the relocation hero.
///
/// Two levels, because people think in both: **States** for the big picture,
/// then drill into a state's **Counties** for the specific spot. Rank by your own
/// pay, or — the "same job, new place" idea — by a **job's typical local pay** in
/// each state (BLS wage data), which is where a move can change a life: the same
/// career earns very differently across states, weighed against local costs.
struct PlacesView: View {
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    let wages: OccupationWages
    let saved: SavedPlacesStore
    var onGoHome: () -> Void

    @State private var planningIncome: Double?
    /// nil = rank by the person's own pay; otherwise by this job's local pay.
    @State private var occupation: OccupationWages.Occupation?
    @State private var pickingOccupation = false
    @State private var scope: Scope = .states

    enum Scope: String, CaseIterable, Identifiable { case states = "States", counties = "Counties", saved = "Saved"; var id: String { rawValue } }

    private var baseIncome: Double? { store.plan.monthlyIncome }

    /// The income model to rank with — either a flat figure or a per-state map.
    private var context: RankContext {
        if let occupation {
            return RankContext(override: nil, byState: wages.monthlyTakeHomeByState(occupation: occupation.code))
        }
        return RankContext(override: planningIncome, byState: nil)
    }

    private var rankedStates: [StateRankingEngine.RankedState] {
        guard let dataset = dataStore.dataset else { return [] }
        return StateRankingEngine.rank(plan: store.plan, in: dataset, energy: benchmarks.energy,
                                       incomeOverride: context.override, incomeByState: context.byState)
    }
    private var rankedCounties: [PlaceRankingEngine.RankedPlace] {
        guard let dataset = dataStore.dataset else { return [] }
        return PlaceRankingEngine.rank(plan: store.plan, in: dataset, energy: benchmarks.energy,
                                       options: context.options(limit: 30))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if baseIncome == nil {
                    emptyState
                } else {
                    intro
                    debtFreedomLink
                    payCard
                    Picker("View", selection: $scope) {
                        ForEach(Scope.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    if dataStore.isLoading && rankedStates.isEmpty {
                        loadingCard
                    } else {
                        switch scope {
                        case .states:   statesList
                        case .counties: countiesList
                        case .saved:    savedList
                        }
                        if scope != .saved { sources }
                    }
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Where you'd have room")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if baseIncome != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ComparePlacesView(store: store, dataStore: dataStore,
                                          benchmarks: benchmarks, context: context)
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .accessibilityLabel("Compare two places")
                }
            }
        }
        .onAppear { if planningIncome == nil { planningIncome = store.plan.monthlyIncome } }
        .sheet(isPresented: $pickingOccupation) {
            OccupationPickerSheet(occupations: wages.occupations, selected: occupation) { picked in
                occupation = picked
            }
        }
    }

    // MARK: - Lists

    private var statesList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            listHeader(title: "Best states first", note: "typical county")
            VStack(spacing: Theme.Spacing.regular) {
                ForEach(Array(rankedStates.enumerated()), id: \.element.id) { i, state in
                    NavigationLink {
                        StateCountiesView(state: state.state, store: store, dataStore: dataStore,
                                          benchmarks: benchmarks, context: context, saved: saved)
                    } label: { stateRowLabel(rank: i + 1, state) }
                    .buttonStyle(PressableCardStyle())
                }
            }
        }
    }

    private var countiesList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            listHeader(title: "Best counties, anywhere", note: nil)
            VStack(spacing: Theme.Spacing.regular) {
                ForEach(Array(rankedCounties.enumerated()), id: \.element.id) { i, place in
                    RankedPlaceRow(rank: i + 1, place: place, store: store, dataStore: dataStore,
                                   benchmarks: benchmarks, income: context.income(for: place.county.state), saved: saved)
                }
            }
        }
    }

    /// The person's saved shortlist, re-scored against the current pay and ranked.
    private var savedPlaces: [PlaceRankingEngine.RankedPlace] {
        guard let dataset = dataStore.dataset else { return [] }
        return saved.fips.compactMap { fips -> PlaceRankingEngine.RankedPlace? in
            guard let county = dataset.county(fips: fips) else { return nil }
            let e = benchmarks.energy.typicalBill(inState: county.state)
            guard let o = AffordabilityEngine.outlook(current: store.plan, place: county,
                                                      stateEnergy: e, incomeOverride: context.income(for: county.state))
            else { return nil }
            return PlaceRankingEngine.RankedPlace(county: county, outlook: o)
        }
        .sorted { $0.monthlyLeft > $1.monthlyLeft }
    }

    @ViewBuilder
    private var savedList: some View {
        if savedPlaces.isEmpty {
            VStack(spacing: Theme.Spacing.regular) {
                AppIconBadge(systemImage: "star", size: 64)
                Text("No saved places yet")
                    .font(Theme.Typography.headline)
                Text("Open any place and tap the ★ to add it to your shortlist. Saved places re-rank with your pay, so you can weigh your candidates in one spot.")
                    .font(Theme.Typography.subheadline).foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity).padding(.vertical, Theme.Spacing.section)
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
                listHeader(title: "Your shortlist", note: nil)
                VStack(spacing: Theme.Spacing.regular) {
                    ForEach(Array(savedPlaces.enumerated()), id: \.element.id) { i, place in
                        RankedPlaceRow(rank: i + 1, place: place, store: store, dataStore: dataStore,
                                       benchmarks: benchmarks, income: context.income(for: place.county.state), saved: saved)
                    }
                }
            }
        }
    }

    private func listHeader(title: String, note: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(Theme.Typography.headline)
            Spacer()
            if occupation == nil, let now = store.plan.moneyLeft {
                Text("You now: \(PlaceFormat.signed(now))/mo")
                    .font(.caption).foregroundStyle(Theme.secondaryText).monospacedDigit()
            } else if let note {
                Text(note).font(.caption).foregroundStyle(Theme.secondaryText)
            }
        }
    }

    // MARK: - State row

    /// Below this many people in a job statewide, we flag the state amber — a high
    /// median wage there rests on very few actual jobs, so "your pay goes furthest"
    /// could be pointing at work that barely exists locally. A named heuristic.
    private let jobScarcityFloor = 500

    private func jobCountText(_ n: Int, job: String) -> String {
        let j = job.lowercased()
        return n < jobScarcityFloor
            ? "Few \(j) jobs here — about \(n.formatted())"
            : "About \(n.formatted()) \(j) jobs here"
    }

    private func stateRowLabel(rank: Int, _ state: StateRankingEngine.RankedState) -> some View {
        let color = PlaceFormat.color(for: state.medianMonthlyLeft)
        return HStack(spacing: Theme.Spacing.regular) {
            Text("\(rank)")
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 26, alignment: .trailing).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(state.state)
                    .font(Theme.Typography.body.weight(.semibold)).foregroundStyle(.primary)
                Text("Best: \(state.best.county.county) · \(state.affordableCount) of \(state.rankedCount) affordable")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let occ = occupation, let n = wages.employment(occupation: occ.code, state: state.state) {
                    Text(jobCountText(n, job: occ.name))
                        .font(.caption2)
                        .foregroundStyle(n < jobScarcityFloor ? Theme.statusColor(.tight) : Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Theme.Spacing.tight)
            VStack(alignment: .trailing, spacing: 2) {
                Text(PlaceFormat.signed(state.medianMonthlyLeft))
                    .font(Theme.Typography.money()).foregroundStyle(color).monospacedDigit()
                Text("typical/mo").font(.caption2).foregroundStyle(Theme.secondaryText)
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.secondaryText.opacity(0.6)).accessibilityHidden(true)
        }
        .padding(.vertical, Theme.Spacing.regular).padding(.horizontal, Theme.Spacing.comfortable)
        .frame(minHeight: Theme.minimumTapTarget).frame(maxWidth: .infinity)
        .background { RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(Theme.cardBackground) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.state), typical \(PlaceFormat.signed(state.medianMonthlyLeft)) a month, best county \(state.best.county.county)")
    }

    // MARK: - Header pieces

    @ViewBuilder
    private var debtFreedomLink: some View {
        if let b = store.plan.debtBalance, b > 0 {
            NavigationLink {
                DebtFreedomView(store: store, dataStore: dataStore, benchmarks: benchmarks, context: context)
            } label: {
                HStack(spacing: Theme.Spacing.regular) {
                    AppIconBadge(systemImage: "flag.checkered", tint: Theme.brand, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Where debt clears soonest")
                            .font(Theme.Typography.body.weight(.semibold)).foregroundStyle(.primary)
                        Text("Places your balance could be gone fastest")
                            .font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold)).foregroundStyle(Theme.secondaryText.opacity(0.6))
                }
                .padding(Theme.Spacing.comfortable).frame(maxWidth: .infinity)
                .frame(minHeight: Theme.minimumTapTarget)
                .background { RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(Theme.brand.opacity(0.10)) }
            }
            .buttonStyle(PressableCardStyle())
            .accessibilityHint("Ranks where your debt would clear soonest")
        }
    }

    private var intro: some View {
        Text("Where your money would stretch furthest — for perspective, never a nudge to move.")
            .font(Theme.Typography.subheadline).foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
    }

    /// The pay the ranking runs on, as one compact control: a tappable row that
    /// says what you're ranking by (your own pay, or a job's local pay), and — only
    /// when it's your own pay — an inline field to adjust it. A job's per-state pay
    /// isn't a single number to edit, so the field gives way to a one-line note.
    private var payCard: some View {
        Card {
            Button { pickingOccupation = true } label: {
                HStack(spacing: Theme.Spacing.regular) {
                    AppIconBadge(systemImage: occupation == nil ? "person.fill" : "briefcase.fill",
                                 tint: Theme.brand, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ranking by").font(.caption).foregroundStyle(Theme.secondaryText)
                        Text(occupation?.name ?? "My pay")
                            .font(Theme.Typography.body.weight(.semibold)).foregroundStyle(.primary)
                    }
                    Spacer(minLength: Theme.Spacing.tight)
                    HStack(spacing: 4) {
                        Text("Change").font(.caption).foregroundStyle(Theme.brand)
                        Image(systemName: "chevron.up.chevron.down").font(.caption2).foregroundStyle(Theme.brand)
                    }
                }
                .frame(minHeight: Theme.minimumTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Ranking by \(occupation?.name ?? "my pay"). Tap to change.")
            if occupation == nil {
                Divider()
                CurrencyField(title: "Monthly take-home", value: $planningIncome)
                jobHookCTA
            } else {
                Divider()
                Text("Using the typical local pay for a \(occupation!.name) in each state — an estimated after-tax figure, a ballpark not a real paycheck. States where it isn't reported are left out.")
                    .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// The differentiator, made obvious: an accented invitation to rank by a job's
    /// local pay, shown whenever the ranking is on the person's own income. It's the
    /// one thing no other cost-of-living tool does, so it shouldn't hide behind a
    /// grey "Change" link.
    private var jobHookCTA: some View {
        Button { pickingOccupation = true } label: {
            HStack(spacing: Theme.Spacing.regular) {
                AppIconBadge(systemImage: "briefcase.fill", tint: Theme.brand, size: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text("See where your job pays furthest")
                        .font(Theme.Typography.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    Text("Rank by your career's local pay — 116 jobs")
                        .font(.caption).foregroundStyle(Theme.secondaryText)
                }
                Spacer(minLength: Theme.Spacing.tight)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold)).foregroundStyle(Theme.brand)
            }
            .padding(Theme.Spacing.regular)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.brand.opacity(0.10))
            }
        }
        .buttonStyle(PressableCardStyle())
        .accessibilityHint("Ranks places by this job's typical local pay")
    }

    private var loadingCard: some View {
        HStack(spacing: Theme.Spacing.regular) {
            ProgressView()
            Text("Ranking places across the country…")
                .font(Theme.Typography.subheadline).foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
    }

    private var sources: some View {
        Text(sourcesText)
            .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true).padding(.top, Theme.Spacing.tight)
    }
    private var sourcesText: String {
        let base = "Ranked by projected money left over: your numbers against each county's typical rent (U.S. Census gross rent, which already includes utilities), plus your own food and debt. States show their typical (median) county. Places within about $50 of each other are effectively tied, and very small counties carry more uncertainty. Doesn't include taxes, insurance, transport or the cost of moving. Typical figures, not a guarantee."
        return occupation == nil ? base
            : base + " Pay is the state's median wage for this job (BLS OEWS 2023), shown as an estimated after-tax take-home — a ballpark, not a real paycheck."
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.comfortable) {
            AppIconBadge(systemImage: "map.fill", size: 84)
            Text("Add your numbers first").font(Theme.Typography.title).multilineTextAlignment(.center)
            Text("Once you've entered what comes in and goes out on the Home tab, this ranks where in the U.S. your money would leave you the most room.")
                .font(Theme.Typography.body).foregroundStyle(Theme.secondaryText).multilineTextAlignment(.center)
            Button { onGoHome() } label: {
                Text("Go to Home").font(Theme.Typography.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
            }
            .buttonStyle(.borderedProminent).padding(.top, Theme.Spacing.tight)
        }
        .padding(Theme.Spacing.section).frame(maxWidth: .infinity).padding(.top, Theme.Spacing.section)
    }
}

/// The income model a ranking runs with — a flat figure, or an occupation's
/// per-state local pay. Kept small and Equatable so it threads cleanly into
/// child screens.
struct RankContext: Equatable {
    var override: Double?
    var byState: [String: Double]?

    func options(limit: Int, stateFilter: String? = nil) -> PlaceRankingEngine.Options {
        .init(incomeOverride: override, incomeByState: byState, stateFilter: stateFilter, limit: limit)
    }
    /// The income used for a place in the given state.
    func income(for state: String) -> Double? {
        if let byState { return byState[state] }
        return override
    }
}

// MARK: - Shared county row

/// One ranked county, as a tappable card that opens its full affordability
/// picture, plus a calm year-ahead risk chip. Shared by the national county list
/// and a single state's list.
struct RankedPlaceRow: View {
    let rank: Int
    let place: PlaceRankingEngine.RankedPlace
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    /// The income used to rank this place (its state's occupation pay, or the flat
    /// figure) — carried into the detail so it matches.
    let income: Double?
    let saved: SavedPlacesStore

    @State private var risk: PlaceRiskEngine.Level?

    var body: some View {
        let color = PlaceFormat.color(for: place.outlook.tone)
        NavigationLink {
            MoveView(store: store, dataStore: dataStore, benchmarks: benchmarks,
                     initialFIPS: place.county.record.fips, initialIncome: income, saved: saved)
        } label: {
            HStack(spacing: Theme.Spacing.regular) {
                Text("\(rank)")
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 26, alignment: .trailing).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(place.county.displayName)
                        .font(Theme.Typography.body.weight(.semibold)).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 6) {
                        Text(PlaceFormat.word(place.outlook.tone)).font(.caption).foregroundStyle(color)
                        if let risk { RiskChip(level: risk) }
                    }
                }
                Spacer(minLength: Theme.Spacing.tight)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(PlaceFormat.signed(place.monthlyLeft))
                        .font(Theme.Typography.money()).foregroundStyle(color).monospacedDigit()
                    Text("left/mo").font(.caption2).foregroundStyle(Theme.secondaryText)
                }
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.6)).accessibilityHidden(true)
            }
            .padding(.vertical, Theme.Spacing.regular).padding(.horizontal, Theme.Spacing.comfortable)
            .frame(minHeight: Theme.minimumTapTarget).frame(maxWidth: .infinity)
            .background { RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(Theme.cardBackground) }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(place.county.displayName), \(PlaceFormat.signed(place.monthlyLeft)) left a month, \(PlaceFormat.word(place.outlook.tone))\(risk.map { ", \($0.word)" } ?? "")")
        }
        .buttonStyle(PressableCardStyle())
        .task(id: "\(place.id)#\(Int(place.monthlyLeft))") {
            let projected = place.outlook.projected
            risk = await Task.detached(priority: .utility) {
                PlaceRiskEngine.level(for: projected)
            }.value
        }
    }
}

/// A small, plain risk pill — the second axis, kept calm and non-alarming.
struct RiskChip: View {
    let level: PlaceRiskEngine.Level
    var body: some View {
        let c = color
        Text(level.word)
            .font(.caption2.weight(.semibold)).foregroundStyle(c)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(c.opacity(0.14), in: Capsule())
    }
    private var color: Color {
        switch level {
        case .low: return Theme.statusColor(.okay)
        case .watch: return Theme.statusColor(.tight)
        case .high: return Theme.statusColor(.over)
        }
    }
}

// MARK: - A single state's counties

struct StateCountiesView: View {
    let state: String
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    let context: RankContext
    let saved: SavedPlacesStore

    private var counties: [PlaceRankingEngine.RankedPlace] {
        guard let dataset = dataStore.dataset else { return [] }
        return PlaceRankingEngine.rank(plan: store.plan, in: dataset, energy: benchmarks.energy,
                                       options: context.options(limit: 100, stateFilter: state))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                stateCostCard
                VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
                    Text("Specific costs by county")
                        .font(Theme.Typography.headline)
                    Text("Ranked by the room your numbers would have. Tap any county for its own rent, utilities and payoff.")
                        .font(Theme.Typography.subheadline).foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    ForEach(Array(counties.enumerated()), id: \.element.id) { i, place in
                        RankedPlaceRow(rank: i + 1, place: place, store: store, dataStore: dataStore,
                                       benchmarks: benchmarks, income: context.income(for: state), saved: saved)
                    }
                }
            }
            .padding(Theme.Spacing.comfortable).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle(state)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The state's typical (median) county rent against the U.S. average. Census
    /// "gross rent" already bundles utilities, so this is one whole housing+utilities
    /// figure — never a rent line with a separate utility cost added on top.
    private var stateCostCard: some View {
        let rents = counties.compactMap { $0.county.record.medianGrossRent }.filter { $0 > 0 }.sorted()
        let medianRent = rents.isEmpty ? nil : rents[rents.count / 2]
        return Card {
            SectionHeader(title: "Typical rent in \(state)",
                          subtitle: "How it compares to the U.S. average")
            if let medianRent {
                CostVsUSRow(symbol: "house.fill", label: "Rent — utilities included",
                            here: medianRent, us: benchmarks.nationalRent, tint: Theme.essentialColor(.housing))
            }
            Text("Typical (median) gross rent across \(state)'s counties (U.S. Census) — it already includes utilities. Food, getting-around, state taxes and insurance don't vary by place in this data yet, so this keeps them unchanged rather than guessing.")
                .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// One cost here versus the U.S. average, with a plain "X% higher/lower" read.
/// Shared by the state summary and the county detail so both look identical.
struct CostVsUSRow: View {
    let symbol: String
    let label: String
    let here: Double
    let us: Double
    var tint: Color = Theme.brand

    var body: some View {
        let diff = us > 0 ? (here - us) / us : 0
        let pct = Int((abs(diff) * 100).rounded())
        let higher = here >= us
        let comparison = pct == 0 ? "about the U.S. average"
            : "\(pct)% \(higher ? "higher" : "lower") than the U.S."
        let color = pct == 0 ? Theme.secondaryText
            : (higher ? Theme.statusColor(.tight) : Theme.statusColor(.okay))
        return HStack(spacing: Theme.Spacing.regular) {
            AppIconBadge(systemImage: symbol, tint: tint, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(Theme.Typography.body.weight(.semibold))
                Text("U.S. average \(PlaceFormat.money(us))/mo")
                    .font(.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: Theme.Spacing.tight)
            VStack(alignment: .trailing, spacing: 2) {
                Text(PlaceFormat.money(here)).font(Theme.Typography.money()).monospacedDigit()
                Text(comparison).font(.caption2).foregroundStyle(color)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) here \(PlaceFormat.money(here)) a month, \(comparison)")
    }
}

// MARK: - Formatting helpers

enum PlaceFormat {
    static func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
    /// Money-left figures are typical-data estimates, so they're rounded to the
    /// nearest $50 before display: two places within ~$50 aren't meaningfully
    /// different, and dollar-exact numbers ("+$3,373" vs "+$3,370") imply a
    /// precision the data doesn't have. The ranking order still uses exact values.
    static func signed(_ value: Double) -> String {
        let rounded = (value / 50).rounded() * 50
        let m = money(abs(rounded)); return rounded >= 0 ? "+\(m)" : "−\(m)"
    }
    static func color(for tone: MoveOutlook.Tone) -> Color {
        switch tone {
        case .good: return Theme.statusColor(.okay)
        case .tight: return Theme.statusColor(.tight)
        case .over: return Theme.statusColor(.over)
        }
    }
    static func color(for left: Double) -> Color {
        if left < 0 { return Theme.statusColor(.over) }
        if left < MoneyPlan.comfortableCushion { return Theme.statusColor(.tight) }
        return Theme.statusColor(.okay)
    }
    static func word(_ tone: MoveOutlook.Tone) -> String {
        switch tone {
        case .good: return "Comfortable"
        case .tight: return "Doable, but tight"
        case .over: return "Over budget here"
        }
    }
}

/// A searchable, category-grouped picker for the occupations — with a "popular"
/// shortlist up top so the common jobs are reachable without scrolling 116 rows.
struct OccupationPickerSheet: View {
    let occupations: [OccupationWages.Occupation]
    let selected: OccupationWages.Occupation?
    var onSelect: (OccupationWages.Occupation?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    /// A handful of widely-held jobs, surfaced first when nothing is searched.
    private static let popularCodes = ["29-1141", "15-1252", "25-2021", "47-2111",
                                       "53-3032", "13-2011", "31-1131", "41-2031"]

    private var filtered: [OccupationWages.Occupation] {
        query.isEmpty ? occupations
            : occupations.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    /// SOC major group (first two digits) → a friendly, relatable category.
    private func category(_ code: String) -> String {
        switch code.prefix(2) {
        case "11", "13": return "Business & management"
        case "15", "17", "19": return "Tech, engineering & science"
        case "21", "23", "25", "27": return "Education, law & creative"
        case "29", "31": return "Healthcare"
        case "33", "35", "37", "39": return "Service & safety"
        case "41", "43": return "Sales & office"
        default: return "Trades & transport"
        }
    }

    private var grouped: [(name: String, jobs: [OccupationWages.Occupation])] {
        let order = ["Healthcare", "Tech, engineering & science", "Trades & transport",
                     "Business & management", "Sales & office", "Service & safety",
                     "Education, law & creative"]
        let dict = Dictionary(grouping: occupations) { category($0.code) }
        return order.compactMap { key in
            guard let jobs = dict[key] else { return nil }
            return (key, jobs.sorted { $0.name < $1.name })
        }
    }

    private var popular: [OccupationWages.Occupation] {
        Self.popularCodes.compactMap { code in occupations.first { $0.code == code } }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    row(title: "My pay", subtitle: "Rank by your own take-home",
                        isSelected: selected == nil, systemImage: "person.fill") {
                        onSelect(nil); dismiss()
                    }
                }
                if query.isEmpty {
                    if !popular.isEmpty {
                        Section("Popular") { jobRows(popular) }
                    }
                    ForEach(grouped, id: \.name) { group in
                        Section(group.name) { jobRows(group.jobs) }
                    }
                } else {
                    Section("Results") {
                        jobRows(filtered)
                        if filtered.isEmpty {
                            Text("No jobs match “\(query)”.")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search 116 jobs")
            .navigationTitle("Rank by which pay?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    @ViewBuilder
    private func jobRows(_ jobs: [OccupationWages.Occupation]) -> some View {
        ForEach(jobs) { occ in
            row(title: occ.name, subtitle: nil,
                isSelected: selected?.code == occ.code, systemImage: "briefcase.fill") {
                onSelect(occ); dismiss()
            }
        }
    }

    private func row(title: String, subtitle: String?, isSelected: Bool,
                     systemImage: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.regular) {
                Image(systemName: systemImage).foregroundStyle(Theme.brand).frame(width: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(Theme.secondaryText)
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark").foregroundStyle(Theme.brand).fontWeight(.semibold)
                }
            }
            .frame(minHeight: Theme.minimumTapTarget)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PlacesView(store: .preview(.sampleTight), dataStore: DataStore(),
                   benchmarks: .previewSample, wages: .previewSample, saved: SavedPlacesStore(), onGoHome: {})
    }
}
#endif
