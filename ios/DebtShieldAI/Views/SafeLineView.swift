import SwiftUI

/// The home screen. The first thing a person sees, and the heart of the app.
///
/// It answers one question in dollars — *how does this month stand?* — with the
/// Safe Line bar, a single headline figure, and a calm one-line verdict. No
/// score, no grade, no jargon. If nothing has been entered yet it shows a warm
/// invitation rather than an empty chart.
///
/// It deliberately depends only on `MoneyPlanStore`, never on the county
/// `Dataset`. A person's budget must never wait on — or fail with — the load of
/// 3,000 counties. The housing comparison layer arrives later and is purely
/// additive on top of this.
struct SafeLineView: View {
    let store: MoneyPlanStore
    /// The county data, for the local rent + energy comparison only.
    /// Optional-by-nature: the screen renders fully whether or not this has
    /// loaded, so a budget never waits on it.
    let dataStore: DataStore
    /// Typical-cost reference data (energy by state, food by income band).
    let benchmarks: Benchmarks

    @State private var isEditing = false
    @State private var isChoosingArea = false

    /// The big money figure — larger than any Theme style, and scales with
    /// Dynamic Type.
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 46

    private var plan: MoneyPlan { store.plan }

    /// The county the person said they live in, if chosen and loaded.
    private var homeCounty: ScoredCounty? {
        guard let fips = store.homeCountyFIPS, let dataset = dataStore.dataset else { return nil }
        return dataset.county(fips: fips)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if plan.isComplete {
                    resultCard
                    askLink
                    breakdownCard
                    comparisonSection
                    editButton
                } else {
                    emptyState
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Your month")
        .sheet(isPresented: $isEditing) {
            MyNumbersView(store: store)
        }
        .sheet(isPresented: $isChoosingArea) {
            if let searchIndex = dataStore.searchIndex {
                AreaPickerView(searchIndex: searchIndex) { county in
                    store.setHomeCounty(fips: county.record.fips, name: county.county)
                }
            }
        }
    }

    // MARK: - Cost comparisons

    /// One card comparing each entered cost to a typical figure or guideline.
    /// Every row is optional and additive — food and debt appear as soon as
    /// income is known; rent and energy appear once an area is chosen. The whole
    /// section is absent until the county data has loaded or a comparison exists.
    @ViewBuilder
    private var comparisonSection: some View {
        let comparisons = CostComparisons.all(plan: plan, county: homeCounty, benchmarks: benchmarks)
        let canPickArea = dataStore.searchIndex != nil
        if !comparisons.isEmpty || canPickArea {
            Card {
                SectionHeader(
                    title: "How your costs compare",
                    subtitle: "Rough markers from public data — guides, not targets"
                )

                ForEach(comparisons) { comparison in
                    comparisonRow(comparison)
                }

                areaControl(canPickArea: canPickArea, hasComparisons: !comparisons.isEmpty)

                Text("Sources: Census (rent), EIA (energy), BLS (food). Debt is compared to the common guideline of keeping payments under \(Int(CostComparisons.debtHealthyShare * 100))% of income.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func comparisonRow(_ comparison: CostComparison) -> some View {
        HStack(spacing: Theme.Spacing.regular) {
            Circle()
                .fill(Theme.essentialColor(comparison.kind))
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(comparison.kind.label)
                    .font(Theme.Typography.body)
                Text(comparison.detail)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Theme.Spacing.tight)
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(comparison.yours))
                    .font(Theme.Typography.money())
                Text(comparison.headline)
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundStyle(standingColor(comparison.standing))
            }
        }
        .frame(minHeight: Theme.minimumTapTarget)
        .accessibilityElement(children: .combine)
    }

    private func standingColor(_ standing: CostStanding) -> Color {
        switch standing {
        case .healthy: return Theme.statusColor(.okay)
        case .watch: return Theme.statusColor(.tight)
        case .high: return Theme.statusColor(.over)
        case .above, .below, .about: return Theme.secondaryText
        }
    }

    @ViewBuilder
    private func areaControl(canPickArea: Bool, hasComparisons: Bool) -> some View {
        if let name = store.homeCountyName {
            Divider()
            HStack {
                Label("Rent & energy vs. \(name)", systemImage: "mappin.and.ellipse")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Button("Change") { isChoosingArea = true }
                    .font(Theme.Typography.subheadline.weight(.semibold))
            }
            .frame(minHeight: Theme.minimumTapTarget)
        } else if canPickArea {
            if hasComparisons { Divider() }
            Button {
                isChoosingArea = true
            } label: {
                Label("Add where you live to compare rent & energy", systemImage: "mappin.and.ellipse")
                    .font(Theme.Typography.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
            }
        }
    }

    // MARK: - Result

    @ViewBuilder
    private var resultCard: some View {
        let status = plan.status ?? .okay
        VStack(alignment: .leading, spacing: Theme.Spacing.comfortable) {
            // The situation, as a pill: icon + colour + words.
            StatusPill(status: status)

            // The one number that matters — big, friendly, rounded.
            if let left = plan.moneyLeft {
                VStack(alignment: .leading, spacing: 2) {
                    Text(headlineAmount(left))
                        .font(.system(size: heroSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(left >= 0 ? "left this month" : "short this month")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }

            SafeLineBar(plan: plan)
                .padding(.top, Theme.Spacing.tight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.comfortable)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .fill(Theme.statusWash(status))
                }
                .shadow(color: Theme.heroShadow, radius: 14, x: 0, y: 8)
        }
    }

    private func headlineAmount(_ left: Double) -> String {
        let magnitude = left.magnitude.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return left >= 0 ? magnitude : "−\(magnitude)"
    }

    // MARK: - Ask

    private var askLink: some View {
        NavigationLink {
            PersonalChatView(store: store)
        } label: {
            HStack(spacing: Theme.Spacing.regular) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.title3)
                    .foregroundStyle(Theme.brand)
                    .frame(width: 38, height: 38)
                    .background(Theme.iconWell(Theme.brand), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(askTitle)
                        .font(Theme.Typography.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("A calm, plain explanation — no judgment")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens Ask DebtShield about your month")
    }

    private var askTitle: String {
        switch plan.status {
        case .over, .tight: return "Ask why it's tight"
        default: return "Ask about your month"
        }
    }

    // MARK: - Breakdown

    private var breakdownCard: some View {
        Card {
            SectionHeader(title: "Where it goes")
            ForEach(plan.segments) { segment in
                HStack(spacing: Theme.Spacing.regular) {
                    Circle()
                        .fill(Theme.essentialColor(segment.kind))
                        .frame(width: 12, height: 12)
                    Text(segment.label)
                        .font(Theme.Typography.body)
                    Spacer()
                    Text(money(segment.amount))
                        .font(Theme.Typography.money())
                        .foregroundStyle(.primary)
                }
                .frame(minHeight: 32)
                .accessibilityElement(children: .combine)
            }

            Divider()

            HStack {
                Text(leftoverLabel)
                    .font(Theme.Typography.body.weight(.semibold))
                Spacer()
                if let left = plan.moneyLeft {
                    Text(headlineAmount(left))
                        .font(Theme.Typography.money())
                        .foregroundStyle(Theme.statusColor(plan.status ?? .okay))
                }
            }
            .frame(minHeight: 32)
        }
    }

    private var leftoverLabel: String {
        guard let left = plan.moneyLeft else { return "Left over" }
        return left >= 0 ? "Left over" : "Over by"
    }

    // MARK: - Edit

    private var editButton: some View {
        Button {
            isEditing = true
        } label: {
            Label("Edit your numbers", systemImage: "slider.horizontal.3")
                .font(Theme.Typography.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
        }
        .buttonStyle(.bordered)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.comfortable) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundStyle(Theme.brand)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Theme.iconWell(Theme.brand)))
                .accessibilityHidden(true)

            Text("See where your money stands")
                .font(Theme.Typography.title)
                .multilineTextAlignment(.center)

            Text("Add a few numbers and we'll show you, in plain dollars, how much room you have this month. Everything stays on your phone.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                isEditing = true
            } label: {
                Text("Add your numbers")
                    .font(Theme.Typography.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, Theme.Spacing.tight)
        }
        .padding(Theme.Spacing.section)
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.section)
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#if DEBUG
#Preview("Filled — tight") {
    NavigationStack { SafeLineView(store: .preview(.sampleTight), dataStore: DataStore(), benchmarks: .previewSample) }
}

#Preview("Filled — over") {
    NavigationStack { SafeLineView(store: .preview(.sampleOver), dataStore: DataStore(), benchmarks: .previewSample) }
}

#Preview("Empty") {
    NavigationStack { SafeLineView(store: .preview(.empty), dataStore: DataStore(), benchmarks: .previewSample) }
}
#endif
