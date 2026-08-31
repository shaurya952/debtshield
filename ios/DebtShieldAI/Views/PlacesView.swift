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
            } else {
                Divider()
                Text("Using the typical local pay for a \(occupation!.name) in each state — estimated take-home. States where it isn't reported are left out.")
                    .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
        let base = "Ranked by projected money left over: your numbers against each county's typical rent (U.S. Census gross rent, which already includes utilities), plus your own food and debt. States show their typical (median) county. Doesn't include taxes, insurance, transport or the cost of moving. Typical figures, not a guarantee."
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
    static func signed(_ value: Double) -> String {
        let m = money(abs(value)); return value >= 0 ? "+\(m)" : "−\(m)"
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

/// A searchable picker for the occupations — far cleaner than a 60-item menu.
struct OccupationPickerSheet: View {
    let occupations: [OccupationWages.Occupation]
    let selected: OccupationWages.Occupation?
    var onSelect: (OccupationWages.Occupation?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [OccupationWages.Occupation] {
        query.isEmpty ? occupations
            : occupations.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section {
                        row(title: "My pay", subtitle: "Rank by your own take-home",
                            isSelected: selected == nil, systemImage: "person.fill") {
                            onSelect(nil); dismiss()
                        }
                    }
                }
                Section("Rank by a job's local pay") {
                    ForEach(filtered) { occ in
                        row(title: occ.name, subtitle: nil,
                            isSelected: selected?.code == occ.code, systemImage: "briefcase.fill") {
                            onSelect(occ); dismiss()
                        }
                    }
                    if filtered.isEmpty {
                        Text("No jobs match “\(query)”.")
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, prompt: "Search jobs")
            .navigationTitle("Pay to rank by")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
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
