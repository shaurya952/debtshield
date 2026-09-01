import SwiftUI

/// "Here vs. there" — two places, side by side.
///
/// The decision most people actually face isn't "rank the country", it's "should
/// I move from A to B?" Pick two places and see them head-to-head on the numbers
/// that matter: money left over, year-ahead risk, rent and energy — using your
/// own pay, or (if a job is chosen on Places) that job's local pay in each state.
struct ComparePlacesView: View {
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    let context: RankContext

    @State private var fipsA: String?
    @State private var fipsB: String?
    @State private var picking: Slot?
    @State private var riskA: PlaceRiskEngine.Level?
    @State private var riskB: PlaceRiskEngine.Level?

    enum Slot: String, Identifiable { case a, b; var id: String { rawValue } }

    private func county(_ fips: String?) -> ScoredCounty? {
        guard let fips, let ds = dataStore.dataset else { return nil }
        return ds.county(fips: fips)
    }
    private func outlook(_ fips: String?) -> MoveOutlook? {
        guard let c = county(fips) else { return nil }
        return AffordabilityEngine.outlook(current: store.plan, place: c,
                                           stateEnergy: benchmarks.energy.typicalBill(inState: c.state),
                                           incomeOverride: context.income(for: c.state))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                intro
                HStack(spacing: Theme.Spacing.regular) {
                    slotButton(.a, county(fipsA))
                    slotButton(.b, county(fipsB))
                }
                if let oa = outlook(fipsA), let ob = outlook(fipsB) {
                    verdict(oa, ob)
                    comparison(oa, ob)
                } else {
                    Text("Pick two places to see them side by side.")
                        .font(Theme.Typography.subheadline).foregroundStyle(Theme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center).padding(.top, Theme.Spacing.comfortable)
                }
            }
            .padding(Theme.Spacing.comfortable).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .background { AppBackdrop() }
        .navigationTitle("Compare two places")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $picking) { slot in
            if let searchIndex = dataStore.searchIndex {
                AreaPickerView(searchIndex: searchIndex) { c in
                    if slot == .a { fipsA = c.record.fips } else { fipsB = c.record.fips }
                }
            }
        }
        .onAppear { if fipsA == nil { fipsA = store.homeCountyFIPS } }
        .task(id: fipsA.map { "\($0)#\(Int(context.income(for: county($0)?.state ?? "") ?? 0))" }) {
            let o = outlook(fipsA); riskA = await Task.detached(priority: .utility) { o.flatMap { PlaceRiskEngine.level(for: $0.projected) } }.value
        }
        .task(id: fipsB.map { "\($0)#\(Int(context.income(for: county($0)?.state ?? "") ?? 0))" }) {
            let o = outlook(fipsB); riskB = await Task.detached(priority: .utility) { o.flatMap { PlaceRiskEngine.level(for: $0.projected) } }.value
        }
    }

    private var intro: some View {
        Text("Weighing a move? Put two places head-to-head — your numbers against each one's real costs.")
            .font(Theme.Typography.body).foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
    }

    private func slotButton(_ slot: Slot, _ c: ScoredCounty?) -> some View {
        Button { picking = slot } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(slot == .a ? "Place A" : "Place B")
                    .font(.caption2.weight(.semibold)).foregroundStyle(Theme.secondaryText)
                    .textCase(.uppercase)
                Text(c?.displayName ?? "Pick a place")
                    .font(Theme.Typography.body.weight(.semibold))
                    .foregroundStyle(c == nil ? Theme.brand : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Theme.Spacing.regular).frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background { RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous).fill(Theme.cardBackground) }
        }
        .buttonStyle(PressableCardStyle())
    }

    // MARK: - Verdict + rows

    private func verdict(_ a: MoveOutlook, _ b: MoveOutlook) -> some View {
        let diff = a.projectedLeft - b.projectedLeft
        let more = diff >= 0 ? a : b
        let less = diff >= 0 ? b : a
        let text: String = abs(diff) < 1
            ? "About the same — you'd keep roughly \(PlaceFormat.money(a.projectedLeft)) a month either way."
            : "In \(more.placeName) you'd keep about \(PlaceFormat.money(abs(diff))) more a month than in \(less.placeName)."
        return Card {
            Text(text).font(Theme.Typography.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func comparison(_ a: MoveOutlook, _ b: MoveOutlook) -> some View {
        Card {
            header(a, b)
            Divider()
            moneyRow("Money left / mo", a.projectedLeft, b.projectedLeft, higherIsBetter: true)
            riskRow("Year-ahead risk", riskA, riskB)
            moneyRow("Typical rent", a.typicalRent, b.typicalRent, higherIsBetter: false)
            moneyRow("Typical energy", a.typicalEnergy ?? 0, b.typicalEnergy ?? 0, higherIsBetter: false)
            moneyRow("Most rent you could afford", max(0, a.maxAffordableRent), max(0, b.maxAffordableRent), higherIsBetter: true)
            Text("Rent: U.S. Census · Energy: EIA · Risk: on-device simulation. Typical figures, not a quote.")
                .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func header(_ a: MoveOutlook, _ b: MoveOutlook) -> some View {
        HStack {
            Text("").frame(maxWidth: .infinity, alignment: .leading)
            Text(a.placeName).font(.caption.weight(.bold)).frame(maxWidth: .infinity).multilineTextAlignment(.center)
            Text(b.placeName).font(.caption.weight(.bold)).frame(maxWidth: .infinity).multilineTextAlignment(.center)
        }
    }

    private func moneyRow(_ label: String, _ av: Double, _ bv: Double, higherIsBetter: Bool) -> some View {
        let aWins = higherIsBetter ? av >= bv : av <= bv
        return HStack {
            Text(label).font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(PlaceFormat.money(av)).font(Theme.Typography.money().monospacedDigit())
                .foregroundStyle(aWins ? Theme.statusColor(.okay) : .primary)
                .fontWeight(aWins ? .bold : .regular).frame(maxWidth: .infinity)
            Text(PlaceFormat.money(bv)).font(Theme.Typography.money().monospacedDigit())
                .foregroundStyle(!aWins ? Theme.statusColor(.okay) : .primary)
                .fontWeight(!aWins ? .bold : .regular).frame(maxWidth: .infinity)
        }
        .frame(minHeight: 34).accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(PlaceFormat.money(av)) versus \(PlaceFormat.money(bv))")
    }

    private func riskRow(_ label: String, _ a: PlaceRiskEngine.Level?, _ b: PlaceRiskEngine.Level?) -> some View {
        HStack {
            Text(label).font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Group { if let a { RiskChip(level: a) } else { Text("—").foregroundStyle(Theme.secondaryText) } }
                .frame(maxWidth: .infinity)
            Group { if let b { RiskChip(level: b) } else { Text("—").foregroundStyle(Theme.secondaryText) } }
                .frame(maxWidth: .infinity)
        }
        .frame(minHeight: 34)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ComparePlacesView(store: .preview(.sampleTight), dataStore: DataStore(),
                          benchmarks: .previewSample, context: RankContext(override: 5000, byState: nil))
    }
}
#endif
