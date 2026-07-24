import SwiftUI

/// The Compare tab: how your spending lines up with typical households — where
/// you live, and across the U.S. This is what the county and national data is
/// for. Plain words, gentle tone, never a grade.
struct CompareView: View {
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks
    /// Jumps to the Home tab so the person can add their numbers.
    var onGoHome: () -> Void

    @State private var isChoosingArea = false

    private var plan: MoneyPlan { store.plan }

    private var homeCounty: ScoredCounty? {
        guard let fips = store.homeCountyFIPS, let dataset = dataStore.dataset else { return nil }
        return dataset.county(fips: fips)
    }

    private var comparisons: [Comparison] {
        CostComparisons.all(plan: plan, county: homeCounty, benchmarks: benchmarks)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if plan.isComplete {
                    introCard
                    areaCard
                    ForEach(comparisons) { comparisonCard($0) }
                    overallCard
                } else {
                    emptyState
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("How you compare")
        .sheet(isPresented: $isChoosingArea) {
            if let searchIndex = dataStore.searchIndex {
                AreaPickerView(searchIndex: searchIndex) { county in
                    store.setHomeCounty(fips: county.record.fips, name: county.county)
                }
            }
        }
    }

    // MARK: - Intro + area

    private var introCard: some View {
        Text("Here's how your spending lines up with typical households — where you live, and across the U.S. It's just for perspective, never a target.")
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var areaCard: some View {
        let canPick = dataStore.searchIndex != nil
        if let name = store.homeCountyName {
            Card {
                HStack(spacing: Theme.Spacing.regular) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Theme.brand)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Comparing to \(name)")
                            .font(Theme.Typography.body.weight(.semibold))
                        Text("Rent and energy use your local typical")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    Spacer()
                    Button("Change") { isChoosingArea = true }
                        .font(Theme.Typography.subheadline.weight(.semibold))
                }
                .frame(minHeight: Theme.minimumTapTarget)
            }
        } else if canPick {
            Button {
                isChoosingArea = true
            } label: {
                ActionRowLabel(
                    systemImage: "mappin.and.ellipse",
                    title: "Add where you live",
                    subtitle: "To compare rent and energy to your area. Food, debt, and the U.S. figures show either way."
                )
            }
            .buttonStyle(PressableCardStyle())
        }
    }

    // MARK: - One comparison

    private func comparisonCard(_ c: Comparison) -> some View {
        Card {
            HStack {
                Text(c.kind.label)
                    .font(Theme.Typography.headline)
                Spacer()
                Text(money(c.yours))
                    .font(Theme.Typography.money(.title3))
            }

            VStack(spacing: Theme.Spacing.regular) {
                bar(label: "You", value: c.yours, peak: c.peak,
                    color: Theme.essentialColor(c.kind))
                ForEach(c.refs) { ref in
                    bar(label: ref.label, value: ref.amount, peak: c.peak,
                        color: Color(uiColor: .systemGray3))
                }
            }
            .padding(.vertical, 2)

            Text(c.verdict)
                .font(Theme.Typography.subheadline.weight(.medium))
                .foregroundStyle(verdictColor(c.standing))
                .fixedSize(horizontal: false, vertical: true)

            Text("Typical from \(c.source)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func bar(label: String, value: Double, peak: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(money(value))
                    .font(Theme.Typography.caption.weight(.semibold).monospacedDigit())
            }
            GeometryReader { geo in
                Capsule()
                    .fill(color)
                    .frame(width: max(6, geo.size.width * value / peak))
            }
            .frame(height: 10)
            .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(money(value))")
    }

    private func verdictColor(_ standing: CostStanding) -> Color {
        switch standing {
        case .healthy: return Theme.statusColor(.okay)
        case .watch: return Theme.statusColor(.tight)
        case .high: return Theme.statusColor(.over)
        case .above, .below, .about: return Theme.secondaryText
        }
    }

    // MARK: - Overall

    private var overallCard: some View {
        let highs = comparisons
            .filter { $0.standing == .above || $0.standing == .high }
            .map { $0.kind.label.lowercased() }
        return Card {
            SectionHeader(title: "The big picture")
            if highs.isEmpty {
                Text("Nothing here stands out as high — your spending looks close to or below typical. That's a good place to be.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Running higher than typical: \(listly(highs)). That's just where to look first — not a problem on its own. Ask on the Home tab for the fastest way to free up room.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func listly(_ items: [String]) -> String {
        ListFormatter.localizedString(byJoining: items)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.comfortable) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundStyle(Theme.brand)
                .frame(width: 96, height: 96)
                .background(Circle().fill(Theme.iconWell(Theme.brand)))
                .accessibilityHidden(true)

            Text("Add your numbers first")
                .font(Theme.Typography.title)
                .multilineTextAlignment(.center)

            Text("Once you've entered what comes in and goes out on the Home tab, this shows how your spending compares to your area and the rest of the U.S.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                onGoHome()
            } label: {
                Text("Go to Home")
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
#Preview("With numbers") {
    NavigationStack {
        CompareView(store: .preview(.sampleTight), dataStore: DataStore(),
                    benchmarks: .previewSample, onGoHome: {})
    }
}

#Preview("Empty") {
    NavigationStack {
        CompareView(store: .preview(.empty), dataStore: DataStore(),
                    benchmarks: .previewSample, onGoHome: {})
    }
}
#endif
