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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { UserDefaults.standard.set(true, forKey: "debtshield.opened.comparison") }
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
                    AppIconBadge(systemImage: "mappin.and.ellipse", size: 38)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Comparing to \(name)")
                            .font(Theme.Typography.body.weight(.semibold))
                        Text("Rent and utilities use your local typical")
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
                    subtitle: "To compare rent and utilities to your area. Food, debt, and the U.S. figures show either way."
                )
            }
            .buttonStyle(PressableCardStyle())
        }
    }

    // MARK: - One comparison

    private func comparisonCard(_ c: Comparison) -> some View {
        Card {
            HStack(spacing: Theme.Spacing.regular) {
                AppIconBadge(systemImage: c.kind.symbol, tint: Theme.essentialColor(c.kind), size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text(c.kind.label)
                        .font(Theme.Typography.headline)
                    Text("You pay")
                        .font(.caption2)
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Text(money(c.yours))
                    .font(Theme.Typography.money(.title3))
                    .foregroundStyle(Theme.essentialColor(c.kind))
            }

            VStack(spacing: Theme.Spacing.regular) {
                bar(label: "You", value: c.yours, peak: c.peak,
                    color: Theme.essentialColor(c.kind), isYou: true)
                ForEach(c.refs) { ref in
                    bar(label: ref.label, value: ref.amount, peak: c.peak,
                        color: Color(uiColor: .systemGray3))
                }
            }
            .padding(.vertical, 2)

            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.tight) {
                standingPill(c.standing)
                Text(c.verdict)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Typical from \(c.source)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    /// A small, colored at-a-glance chip for a cost's standing.
    private func standingPill(_ standing: CostStanding) -> some View {
        let color = verdictColor(standing)
        let (icon, word): (String, String)
        switch standing {
        case .above:   (icon, word) = ("arrow.up.right", "Higher")
        case .high:    (icon, word) = ("arrow.up.right", "High")
        case .watch:   (icon, word) = ("exclamationmark.triangle.fill", "Watch")
        case .below:   (icon, word) = ("arrow.down.right", "Lower")
        case .healthy: (icon, word) = ("checkmark.circle.fill", "Comfortable")
        case .about:   (icon, word) = ("equal", "Typical")
        }
        return Label(word, systemImage: icon)
            .font(.caption.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14), in: Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.22), lineWidth: 1))
            .fixedSize()
            .accessibilityHidden(true)
    }

    private func bar(label: String, value: Double, peak: Double, color: Color, isYou: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(Theme.Typography.caption.weight(isYou ? .bold : .regular))
                    .foregroundStyle(isYou ? color : Theme.secondaryText)
                Spacer()
                Text(money(value))
                    .font(Theme.Typography.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(isYou ? .primary : Theme.secondaryText)
            }
            GeometryReader { geo in
                Capsule()
                    .fill(LinearGradient(colors: [color, color.opacity(0.72)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: max(6, geo.size.width * value / peak))
                    .shadow(color: isYou ? color.opacity(0.35) : .clear,
                            radius: isYou ? 4 : 0, x: 0, y: 2)
            }
            .frame(height: isYou ? 14 : 10)
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
            HStack(spacing: Theme.Spacing.regular) {
                AppIconBadge(systemImage: highs.isEmpty ? "checkmark.seal.fill" : "chart.bar.xaxis",
                             tint: highs.isEmpty ? Theme.statusColor(.okay) : Theme.brand, size: 34)
                Text("The big picture")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
            }
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
            AppIconBadge(systemImage: "chart.bar.xaxis", size: 84)

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
