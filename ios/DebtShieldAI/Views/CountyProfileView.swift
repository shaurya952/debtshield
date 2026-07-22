import SwiftUI
import Charts

/// Phase 2 County Profile.
///
/// The Streamlit profile showed three metrics and one bar chart. This adds a
/// national frame of reference (rank and percentile), the underlying Census
/// indicators the score is built from, and an honest statement of which drivers
/// the dataset cannot measure.
struct CountyProfileView: View {
    let dataset: Dataset
    let searchIndex: CountySearchIndex
    let selection: SelectionStore
    let favorites: FavoritesManager

    @State private var isPickerPresented = false
    @ScaledMetric(relativeTo: .largeTitle) private var headlineNumberSize: CGFloat = 44

    var body: some View {
        Group {
            if let county = selection.selectedCounty(in: dataset) {
                profile(for: county)
            } else {
                emptyState
            }
        }
        .background(Theme.screenGradient)
        .navigationTitle("County Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if let county = selection.selectedCounty(in: dataset) {
                ToolbarItem(placement: .primaryAction) {
                    favoriteButton(for: county)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPickerPresented = true
                } label: {
                    Label("Change county", systemImage: "magnifyingglass")
                }
                .accessibilityHint("Search all \(dataset.counties.count.formatted(.number)) U.S. counties")
            }
        }
        // Records a visit whenever the selection changes, including the first
        // one, so Recently Viewed reflects what was actually opened.
        .task(id: selection.selectedID) {
            if let county = selection.selectedCounty(in: dataset) {
                favorites.recordVisit(county)
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            CountyPickerView(
                dataset: dataset,
                searchIndex: searchIndex,
                favorites: favorites
            ) { county in
                selection.select(county)
            }
        }
    }

    /// State is carried by the icon shape (filled vs outline) and by the
    /// accessibility label, not by colour alone.
    private func favoriteButton(for county: ScoredCounty) -> some View {
        let isSaved = favorites.isFavorite(county)
        return Button {
            favorites.toggleFavorite(county)
        } label: {
            Label(
                isSaved ? "Saved" : "Save",
                systemImage: isSaved ? "star.fill" : "star"
            )
        }
        .accessibilityLabel(isSaved ? "Saved" : "Save county")
        .accessibilityHint(
            isSaved
                ? "Removes \(county.displayName) from your saved counties"
                : "Adds \(county.displayName) to your saved counties"
        )
    }

    // MARK: - Empty state

    /// First launch has no selection. Rather than defaulting to an arbitrary
    /// county, the screen explains what to do and offers a few starting points.
    private var emptyState: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.comfortable) {
                Image(systemName: "map")
                    .font(.largeTitle)
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)

                Text("Choose a county")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)

                Text("Search any of the \(dataset.counties.count.formatted(.number)) U.S. counties in this dataset to see its Financial Distress Index and what drives it.")
                    .font(.body)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)

                Button {
                    isPickerPresented = true
                } label: {
                    Label("Search counties", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)

                quickList(
                    title: "Saved counties",
                    subtitle: "Counties you starred",
                    counties: favorites.favorites(in: dataset)
                )

                quickList(
                    title: "Recently viewed",
                    subtitle: "Where you have been lately",
                    counties: favorites.recents(in: dataset)
                )

                quickList(
                    title: "Or start with these",
                    subtitle: "The highest-scoring counties in the dataset",
                    counties: Array(dataset.highestRisk.prefix(3))
                )
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }

    /// A titled list of counties on the empty state. Renders nothing when the
    /// list is empty, so a first-time user sees only the suggestions card.
    @ViewBuilder
    private func quickList(
        title: String,
        subtitle: String,
        counties: [ScoredCounty]
    ) -> some View {
        if !counties.isEmpty {
            Card {
                SectionHeader(title: title, subtitle: subtitle)
                ForEach(Array(counties.enumerated()), id: \.element.id) { position, county in
                    if position > 0 { Divider() }
                    Button {
                        selection.select(county)
                    } label: {
                        CountyResultRow(county: county)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Profile

    private func profile(for county: ScoredCounty) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                headline(for: county)
                exploreCard(for: county)
                driverBreakdown(for: county)
                indicators(for: county)
                EducationalDisclaimer()
            }
            .padding(Theme.Spacing.comfortable)
        }
    }

    // MARK: Headline

    private func headline(for county: ScoredCounty) -> some View {
        let rank = dataset.rank(of: county)
        let percentile = dataset.percentile(for: county)

        return Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                Text(county.county)
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Text(county.state)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            }

            if let index = county.index, let riskLevel = county.riskLevel {
                RiskBadge(level: riskLevel)

                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.tight) {
                    Text(index.scoreText)
                        // @ScaledMetric so the headline number grows with the
                        // reader's text size instead of staying pinned at 44pt.
                        .font(.system(size: headlineNumberSize, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("out of 100")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Financial Distress Index")
                .accessibilityValue("\(index.scoreText) out of 100")

                if let rank, let percentile {
                    Text(rankSentence(rank: rank, percentile: percentile))
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            } else {
                UnscoredBadge()
                unscoredExplanation(for: county)
            }

            if let top = county.topDriver {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Biggest factor: \(top.title)")
                        .font(.subheadline.weight(.semibold))
                    Text(top.kind.whyThisMatters)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// Says plainly why there is no number, names the missing indicators, and
    /// makes clear that "no score" is not the same as "low risk".
    private func unscoredExplanation(for county: ScoredCounty) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text("There is not enough Census data to calculate a Financial Distress Index for \(county.county).")
                .font(.subheadline)

            if !county.missingIndicators.isEmpty {
                Text("Missing: " + ListFormatter.localizedString(byJoining: county.missingIndicators) + ".")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }

            Text("This usually happens in counties with very small populations, where the Census does not publish estimates. It does not mean the county is low risk — only that it cannot be measured here.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// Plain English, no statistics jargon. "Higher than 68% of counties" is
    /// more useful to a resident than "68th percentile".
    private func rankSentence(rank: Int, percentile: Double) -> String {
        let total = dataset.scoredCounties.count.formatted(.number)
        // Uses the shared phrasing helper: the top-ranked county is not
        // "higher than 100% of them", because it is not higher than itself.
        return "Ranked \(rank.formatted(.number)) of \(total) counties by financial distress — a higher score than \(PercentilePhrasing.shareOfThem(percentile))."
    }

    // MARK: Drivers

    private func driverBreakdown(for county: ScoredCounty) -> some View {
        let measured = county.drivers.filter(\.isMeasured)
        let unmeasured = county.drivers.filter { !$0.isMeasured }

        return Card {
            SectionHeader(
                title: "What drives the score",
                subtitle: "Each factor is scored 0 to 100, where higher means more pressure"
            )

            Chart(measured) { driver in
                BarMark(
                    x: .value("Score", driver.score),
                    y: .value("Factor", driver.title)
                )
                .foregroundStyle(Theme.brand)
                .annotation(position: .trailing) {
                    Text(driver.score.scoreText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                }
                .accessibilityLabel(driver.title)
                .accessibilityValue("\(driver.score.scoreText) out of 100")
            }
            .chartXScale(domain: 0...100)
            .chartXAxis {
                AxisMarks(values: [0, 25, 50, 75, 100])
            }
            .frame(height: max(120, CGFloat(measured.count) * 56))
            .accessibilityLabel("Risk factor breakdown chart")

            // The chart in words. Always visible, not a VoiceOver-only fallback.
            Text(measured.map { "\($0.title) \($0.score.scoreText)" }.joined(separator: " · "))
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)

            ForEach(measured) { driver in
                VStack(alignment: .leading, spacing: 2) {
                    Text(driver.title)
                        .font(.subheadline.weight(.semibold))
                    Text(driver.kind.whyThisMatters)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }

            if !unmeasured.isEmpty {
                Divider()
                Text("Not measured for this county: " + unmeasured.map(\.title).joined(separator: ", ") + ". The dataset has no source for these yet, so they are left out of the score rather than guessed.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    /// The county's detail screens.
    ///
    /// These were three of the five tabs until the Phase 5 restructure. They
    /// all operate on the selected county, so they belong under it — and moving
    /// them here keeps the tab bar at five, which is the point past which iOS
    /// collapses tabs into a system "More" list.
    ///
    /// Hidden for unscored counties: there are no drivers to rank, nothing to
    /// recommend, and no index to simulate against.
    @ViewBuilder
    private func exploreCard(for county: ScoredCounty) -> some View {
        if county.isScored {
            Card {
                SectionHeader(title: "Explore \(county.county)")

                NavigationLink {
                    RiskDriversView(dataset: dataset, county: county)
                } label: {
                    DetailNavigationRow(
                        title: "Risk drivers",
                        subtitle: "What pushes this county's score up, and how it compares nationally",
                        systemImage: "chart.bar.doc.horizontal"
                    )
                }
                .buttonStyle(.plain)

                Divider()

                NavigationLink {
                    RecommendationsView(dataset: dataset, county: county)
                } label: {
                    DetailNavigationRow(
                        title: "Recommendations",
                        subtitle: "Suggested areas of action for policymakers and residents",
                        systemImage: "lightbulb"
                    )
                }
                .buttonStyle(.plain)

                Divider()

                NavigationLink {
                    ScenarioSimulatorView(dataset: dataset, county: county)
                } label: {
                    DetailNavigationRow(
                        title: "Scenario simulator",
                        subtitle: "Estimate how the score would respond to different figures",
                        systemImage: "slider.horizontal.3"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Indicators

    /// One phrase for every absent value, so a missing number never renders as
    /// a blank, a dash, or a misleading zero.
    static let notReported = "Not reported"

    static func percent(_ value: Double?) -> String {
        value.map { "\($0.scoreText)%" } ?? notReported
    }

    static func currency(_ value: Double?) -> String {
        value.map { $0.formatted(.currency(code: "USD").precision(.fractionLength(0))) } ?? notReported
    }

    /// The raw Census numbers behind the score. The Streamlit profile never
    /// showed these, which made the index impossible to sanity-check.
    private func indicators(for county: ScoredCounty) -> some View {
        let record = county.record
        let rentToIncome = RiskScoring.rentToIncomeRatio(record)

        return Card {
            SectionHeader(
                title: "Underlying data",
                subtitle: record.year.map { "U.S. Census ACS 5-Year estimates, \($0)" } ?? "U.S. Census ACS 5-Year estimates"
            )

            IndicatorRow(
                label: "Median household income",
                value: Self.currency(record.medianHouseholdIncome)
            )
            Divider()
            IndicatorRow(
                label: "Median gross rent",
                value: record.medianGrossRent.map {
                    $0.formatted(.currency(code: "USD").precision(.fractionLength(0))) + " / month"
                } ?? Self.notReported
            )
            Divider()
            IndicatorRow(
                label: "Rent burden",
                value: Self.percent(record.rentBurdenPct),
                detail: "Share of renters spending over 30% of income on rent"
            )
            Divider()
            IndicatorRow(
                label: "Rent as share of income",
                value: Self.percent(rentToIncome),
                detail: "Annual median rent divided by median household income"
            )
            Divider()
            IndicatorRow(
                label: "Poverty rate",
                value: Self.percent(record.povertyRate)
            )
            Divider()
            IndicatorRow(
                label: "Unemployment rate",
                value: Self.percent(record.unemploymentRate)
            )
        }
    }
}

// MARK: - Indicator row

struct IndicatorRow: View {
    let label: String
    let value: String
    var detail: String?

    /// At the largest accessibility text sizes a side-by-side row truncates, so
    /// it stacks instead.
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) { labelStack; valueText }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    labelStack
                    Spacer(minLength: Theme.Spacing.regular)
                    valueText
                }
            }
        }
        .padding(.vertical, Theme.Spacing.tight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(detail.map { "\(value). \($0)" } ?? value)
    }

    private var labelStack: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.subheadline)
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
    }

    private var valueText: some View {
        Text(value)
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
    }
}
