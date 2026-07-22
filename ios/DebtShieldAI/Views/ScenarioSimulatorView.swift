import SwiftUI

/// Phase 5 Scenario Simulator.
///
/// The Streamlit version had four sliders and three metrics. This adds the
/// remaining three inputs, an explanation of what actually changed and why, and
/// an honest treatment of the drivers this dataset cannot measure.
struct ScenarioSimulatorView: View {
    let dataset: Dataset
    let county: ScoredCounty

    @State private var inputs: ScenarioInputs
    private let baseline: ScenarioInputs

    init(dataset: Dataset, county: ScoredCounty) {
        self.dataset = dataset
        self.county = county
        let base = ScenarioInputs.baseline(for: county)
        baseline = base
        _inputs = State(initialValue: base)
    }

    private var simulated: ScoredCounty {
        ScenarioEngine.simulate(county: county, inputs: inputs, baseCapabilities: dataset.capabilities)
    }

    private var explanation: ScenarioExplanation {
        ScenarioExplanation.build(
            original: county, simulated: simulated, baseline: baseline, inputs: inputs
        )
    }

    @ScaledMetric(relativeTo: .title) private var resultNumberSize: CGFloat = 34

    private var hasChanges: Bool { inputs != baseline }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                estimateBanner
                resultCard
                explanationCard
                measuredSliders
                unmeasuredSection
                resetButton
                EducationalDisclaimer()
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Scenario")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Reset") { reset() }
                    .font(.body)
                    .disabled(!hasChanges)
                    .accessibilityHint("Returns every slider to this county's real figures")
            }
        }
    }

    private func reset() {
        withAnimation(.easeOut(duration: 0.2)) { inputs = baseline }
    }

    // MARK: - Estimate banner

    /// Requirement: this must never read as a forecast. It leads the screen
    /// rather than sitting in a footnote.
    private var estimateBanner: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.tight) {
            Image(systemName: "slider.horizontal.3")
                .foregroundStyle(Theme.brand)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text("This is an estimate, not a prediction")
                    .font(.subheadline.weight(.semibold))
                Text("It shows what the index would be if these figures were different. It does not forecast that they will change, and it does not model knock-on effects — raising income here does not raise rents, though in reality it often would.")
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(Theme.Spacing.comfortable)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Result

    private var resultCard: some View {
        let originalIndex = county.index ?? 0
        let simulatedCounty = simulated
        let simulatedIndex = simulatedCounty.index ?? 0
        let delta = simulatedIndex - originalIndex

        return Card {
            SectionHeader(title: county.displayName, subtitle: "Financial Distress Index")

            HStack(alignment: .top, spacing: Theme.Spacing.comfortable) {
                indexColumn(title: "Now", index: originalIndex, level: county.riskLevel)
                Divider().frame(maxHeight: 90)
                indexColumn(title: "Scenario", index: simulatedIndex, level: simulatedCounty.riskLevel)
            }

            Divider()

            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: deltaSymbol(delta))
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
                Text(deltaText(delta))
                    .font(.subheadline.weight(.semibold))
                    .contentTransition(.numericText())
            }
            .padding(.vertical, Theme.Spacing.regular)
            .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Change")
            .accessibilityValue(deltaText(delta))
        }
    }

    private func indexColumn(title: String, index: Double, level: RiskLevel?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.secondaryText)
            Text(index.scoreText)
                .font(.system(size: resultNumberSize, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
            if let level {
                RiskBadge(level: level, compact: true)
            } else {
                UnscoredBadge()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(index.scoreText) out of 100. \(level?.label ?? "No") risk.")
    }

    private func deltaSymbol(_ delta: Double) -> String {
        if abs(delta) < 0.05 { return "equal.circle" }
        return delta > 0 ? "arrow.up.right" : "arrow.down.right"
    }

    private func deltaText(_ delta: Double) -> String {
        if abs(delta) < 0.05 { return "No change to the index" }
        return delta > 0
            ? "Up \(delta.scoreText) points — more financial pressure"
            : "Down \(abs(delta).scoreText) points — less financial pressure"
    }

    // MARK: - Explanation

    private var explanationCard: some View {
        let detail = explanation

        return Card {
            SectionHeader(title: "What changed")

            if detail.isUnchanged {
                Text("Nothing yet. Move a slider below to see how this county's score would respond.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                    ForEach(detail.inputChanges, id: \.self) { line in
                        bullet(line)
                    }
                    ForEach(detail.driverEffects, id: \.self) { line in
                        bullet(line)
                    }
                }

                Divider()

                Text(detail.summary)
                    .font(.subheadline.weight(.semibold))
                Text(detail.riskChange)
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondaryText)

                if let note = detail.weightingNote {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        // One utterance rather than a dozen fragments.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("What changed")
        .accessibilityValue(detail.isUnchanged
            ? "Nothing yet. Move a slider to see how this county's score would respond."
            : detail.spoken)
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.tight) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .padding(.top, 7)
                .foregroundStyle(Theme.secondaryText)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Sliders

    private var measuredFields: [ScenarioField] {
        ScenarioField.allCases.filter { dataset.capabilities.measuredDrivers.contains($0.driver) }
    }

    private var unmeasuredFields: [ScenarioField] {
        ScenarioField.allCases.filter { !dataset.capabilities.measuredDrivers.contains($0.driver) }
    }

    private var measuredSliders: some View {
        Card {
            SectionHeader(
                title: "Adjust the figures",
                subtitle: "These are the indicators this county has real data for"
            )
            ForEach(measuredFields) { field in
                ScenarioSlider(
                    field: field,
                    value: binding(for: field),
                    original: baseline[keyPath: field.keyPath]
                )
            }
        }
    }

    /// The three drivers with no data source. Shown because the scenario is
    /// still a useful thought experiment, but off by default and explicit that
    /// switching them on changes the weighting.
    @ViewBuilder
    private var unmeasuredSection: some View {
        if !unmeasuredFields.isEmpty {
            Card {
                SectionHeader(
                    title: "Drivers with no data",
                    subtitle: "This county has no debt, energy, or food-access figures"
                )

                Toggle(isOn: $inputs.includesUnmeasuredDrivers) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Include them in this scenario")
                            .font(.subheadline.weight(.semibold))
                        Text("Adds these drivers to the calculation using the values below. The index is then weighted differently from the real one.")
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
                .frame(minHeight: Theme.minimumTapTarget)
                .accessibilityHint("Adds debt, energy, and food access to the simulated score")

                if inputs.includesUnmeasuredDrivers {
                    ForEach(unmeasuredFields) { field in
                        ScenarioSlider(
                            field: field,
                            value: binding(for: field),
                            original: baseline[keyPath: field.keyPath],
                            originalLabel: "assumed"
                        )
                    }
                    Text("Starting values are national assumptions, not measurements for this county. Debt is estimated from the debt-to-income ratio alone, so it cannot reach its full range.")
                        .font(.footnote)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
    }

    private func binding(for field: ScenarioField) -> Binding<Double> {
        Binding(
            get: { inputs[keyPath: field.keyPath] },
            set: { inputs[keyPath: field.keyPath] = $0 }
        )
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button {
            reset()
        } label: {
            Label("Reset to this county's real figures", systemImage: "arrow.counterclockwise")
                .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
        }
        .buttonStyle(.bordered)
        .disabled(!hasChanges)
    }
}

// MARK: - Slider row

/// One labelled slider with its current value and a reminder of the real figure.
///
/// `Slider` is natively VoiceOver-adjustable, so the work here is giving it a
/// value that reads as a real quantity ("12.6 percent") rather than a bare
/// number, and keeping the label legible at large text sizes.
struct ScenarioSlider: View {
    let field: ScenarioField
    @Binding var value: Double
    let original: Double
    var originalLabel: String = "now"

    private var isChanged: Bool { abs(value - original) > 0.0001 }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            HStack(alignment: .firstTextBaseline) {
                Text(field.title)
                    .font(.subheadline.weight(.medium))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Theme.Spacing.tight)
                Text(field.format(value))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .contentTransition(.numericText())
                    .layoutPriority(1)
            }

            Slider(value: $value, in: field.range, step: field.step)
                .frame(minHeight: Theme.minimumTapTarget)
                .accessibilityLabel(field.title)
                .accessibilityValue(field.format(value))
                .accessibilityHint(field.explanation)

            HStack {
                Text(field.explanation)
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                Spacer(minLength: Theme.Spacing.tight)
                if isChanged {
                    Text("\(originalLabel): \(field.format(original))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.secondaryText)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.tight)
    }
}
