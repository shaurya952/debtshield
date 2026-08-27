import SwiftUI

/// Places — the relocation hero.
///
/// Two levels, because people think in both: **States** for the big picture
/// ("which states stretch my money"), then drill into a state's **Counties** for
/// the specific spot. Both rank on the same on-device math (`PlaceRankingEngine`
/// and its `StateRankingEngine` rollup): where your real numbers leave the most
/// breathing room. Tapping any county opens the full "could you afford it here"
/// picture.
struct PlacesView: View {
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    /// Jumps to Home so a person with no numbers can add them.
    var onGoHome: () -> Void

    enum Scope: String, CaseIterable, Identifiable { case states = "States", counties = "Counties"; var id: String { rawValue } }
    @State private var scope: Scope = .states

    /// The pay to plan around — defaults to current take-home; changing it re-ranks.
    @State private var planningIncome: Double?
    private var baseIncome: Double? { store.plan.monthlyIncome }
    private var override: Double? { planningIncome != baseIncome ? planningIncome : nil }

    private var rankedStates: [StateRankingEngine.RankedState] {
        guard let dataset = dataStore.dataset else { return [] }
        return StateRankingEngine.rank(plan: store.plan, in: dataset,
                                       energy: benchmarks.energy, incomeOverride: override)
    }
    private var rankedCounties: [PlaceRankingEngine.RankedPlace] {
        guard let dataset = dataStore.dataset else { return [] }
        return PlaceRankingEngine.rank(plan: store.plan, in: dataset, energy: benchmarks.energy,
                                       options: .init(incomeOverride: override, limit: 30))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if baseIncome == nil {
                    emptyState
                } else {
                    intro
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
                        }
                        sources
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
        .onAppear { if planningIncome == nil { planningIncome = store.plan.monthlyIncome } }
    }

    // MARK: - Lists

    private var statesList: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            listHeader(title: "Best states first", note: "typical county")
            VStack(spacing: Theme.Spacing.regular) {
                ForEach(Array(rankedStates.enumerated()), id: \.element.id) { i, state in
                    NavigationLink {
                        StateCountiesView(state: state.state, store: store, dataStore: dataStore,
                                          benchmarks: benchmarks, planningIncome: planningIncome)
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
                                   benchmarks: benchmarks, planningIncome: planningIncome)
                }
            }
        }
    }

    private func listHeader(title: String, note: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(Theme.Typography.headline)
            Spacer()
            if let now = store.plan.moneyLeft {
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
                .frame(width: 26, alignment: .trailing)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(state.state)
                    .font(Theme.Typography.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("Best: \(state.best.county.county) · \(state.affordableCount) of \(state.rankedCount) affordable")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
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
                .foregroundStyle(Theme.secondaryText.opacity(0.6))
                .accessibilityHidden(true)
        }
        .padding(.vertical, Theme.Spacing.regular)
        .padding(.horizontal, Theme.Spacing.comfortable)
        .frame(minHeight: Theme.minimumTapTarget)
        .frame(maxWidth: .infinity)
        .background { RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(Theme.cardBackground) }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.state), typical \(PlaceFormat.signed(state.medianMonthlyLeft)) a month, best county \(state.best.county.county)")
    }

    // MARK: - Header / states / footers

    private var intro: some View {
        Text("The same money goes further in some places than others. See which states stretch it, then drill into a county for the specifics. It's for perspective, never a nudge to move.")
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var payCard: some View {
        Card {
            SectionHeader(title: "The pay you're planning around",
                          subtitle: "Keep your current take-home, or try a new job's number to see how the map changes.")
            CurrencyField(title: "Monthly take-home", value: $planningIncome)
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
        Text("Ranked by projected money left over: your numbers against each county's typical rent (U.S. Census) and its state energy bill (EIA). States show their typical (median) county. Typical figures, not a guarantee — a county median isn't your exact apartment.")
            .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true).padding(.top, Theme.Spacing.tight)
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

// MARK: - Shared county row

/// One ranked county, as a tappable card that opens its full affordability
/// picture. Shared by the national county list and a single state's list.
struct RankedPlaceRow: View {
    let rank: Int
    let place: PlaceRankingEngine.RankedPlace
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    let planningIncome: Double?

    var body: some View {
        let color = PlaceFormat.color(for: place.outlook.tone)
        NavigationLink {
            MoveView(store: store, dataStore: dataStore, benchmarks: benchmarks,
                     initialFIPS: place.county.record.fips, initialIncome: planningIncome)
        } label: {
            HStack(spacing: Theme.Spacing.regular) {
                Text("\(rank)")
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 26, alignment: .trailing).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(place.county.displayName)
                        .font(Theme.Typography.body.weight(.semibold)).foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(PlaceFormat.word(place.outlook.tone)).font(.caption).foregroundStyle(color)
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
            .accessibilityLabel("\(place.county.displayName), \(PlaceFormat.signed(place.monthlyLeft)) left a month, \(PlaceFormat.word(place.outlook.tone))")
        }
        .buttonStyle(PressableCardStyle())
    }
}

// MARK: - A single state's counties

/// The counties inside one state, ranked — reached by tapping a state.
struct StateCountiesView: View {
    let state: String
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    let planningIncome: Double?

    private var override: Double? {
        planningIncome != store.plan.monthlyIncome ? planningIncome : nil
    }
    private var counties: [PlaceRankingEngine.RankedPlace] {
        guard let dataset = dataStore.dataset else { return [] }
        return PlaceRankingEngine.rank(plan: store.plan, in: dataset, energy: benchmarks.energy,
                                       options: .init(incomeOverride: override, stateFilter: state, limit: 100))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
                Text("Counties in \(state), ranked by the room your numbers would have there.")
                    .font(Theme.Typography.subheadline).foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(Array(counties.enumerated()), id: \.element.id) { i, place in
                    RankedPlaceRow(rank: i + 1, place: place, store: store, dataStore: dataStore,
                                   benchmarks: benchmarks, planningIncome: planningIncome)
                }
            }
            .padding(Theme.Spacing.comfortable).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle(state)
        .navigationBarTitleDisplayMode(.inline)
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
    /// Colour a bare dollar figure (state medians have no tone of their own).
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

#if DEBUG
#Preview {
    NavigationStack {
        PlacesView(store: .preview(.sampleTight), dataStore: DataStore(),
                   benchmarks: .previewSample, onGoHome: {})
    }
}
#endif
