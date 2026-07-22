import SwiftUI
import Charts

/// Phase 7 Model Performance.
///
/// Reports the metrics recorded during Python training. Nothing here runs a
/// model — see `ModelPerformanceLoader` for why the `.pkl` cannot be loaded in
/// Swift and what converting it to Core ML would involve.
///
/// Each of the two files is loaded independently, so one missing file degrades
/// its own section rather than the whole screen.
struct ModelPerformanceView: View {

    @State private var modelResults: Result<[ModelResult], ModelDataError>?
    @State private var features: Result<[FeatureImportance], ModelDataError>?

    private let loader = ModelPerformanceLoader()

    private var interpretation: ModelInterpretation {
        ModelInterpretation(
            results: (try? modelResults?.get()) ?? [],
            features: (try? features?.get()) ?? []
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                introCard
                comparisonSection
                featureSection
                interpretationCard
                limitationsCard
                coreMLCard
            }
            .padding(Theme.Spacing.comfortable)
        }
        .background(Theme.screenGradient)
        .navigationTitle("Model Performance")
        .navigationBarTitleDisplayMode(.large)
        .task {
            if modelResults == nil { modelResults = loader.loadModelResults() }
            if features == nil { features = loader.loadFeatureImportance() }
        }
    }

    // MARK: - Intro

    private var introCard: some View {
        Card {
            SectionHeader(
                title: "About these results",
                subtitle: "Recorded during model training, in Python"
            )
            Text("DebtShield AI scores counties with a transparent, rule-based formula — not with these models. They were trained separately during research to test whether a machine-learning model could reproduce the same risk labels. Their scores are shown here for completeness.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    // MARK: - Comparison

    @ViewBuilder
    private var comparisonSection: some View {
        switch modelResults {
        case .none:
            Card { SkeletonBlock(height: 120, cornerRadius: 8) }
        case .failure(let error):
            InlineErrorCard(title: error.title, message: error.message, detail: error.technicalDetail)
        case .success(let results):
            comparisonCard(results)
        }
    }

    private func comparisonCard(_ results: [ModelResult]) -> some View {
        let interpretation = self.interpretation
        let best = interpretation.bestByF1

        return VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            SectionHeader(
                title: "Model comparison",
                subtitle: "Four models trained on the same data. Ranked by F1 score."
            )
            .padding(.horizontal, Theme.Spacing.comfortable)

            ForEach(results.sorted { $0.f1 > $1.f1 }) { result in
                ModelResultCard(
                    result: result,
                    isBest: result.id == best?.id,
                    isBundled: result.name == ModelInterpretation.bundledModelName
                )
            }
        }
    }

    // MARK: - Features

    @ViewBuilder
    private var featureSection: some View {
        switch features {
        case .none:
            Card { SkeletonBlock(height: 200, cornerRadius: 8) }
        case .failure(let error):
            InlineErrorCard(title: error.title, message: error.message, detail: error.technicalDetail)
        case .success:
            featureCard
        }
    }

    private var featureCard: some View {
        let interpretation = self.interpretation
        let top = interpretation.topFeatures()

        return Card {
            SectionHeader(
                title: "Feature importance",
                subtitle: "The 10 inputs the Random Forest leaned on most"
            )

            Chart(top) { feature in
                BarMark(
                    x: .value("Importance", feature.importance * 100),
                    y: .value("Feature", feature.displayName)
                )
                .foregroundStyle(feature.isDerived ? Theme.brand : Theme.brand.opacity(0.45))
                .accessibilityLabel(feature.displayName)
                .accessibilityValue("\((feature.importance * 100).scoreText) percent")
            }
            .chartXAxis {
                AxisMarks(format: Decimal.FormatStyle.Percent.percent.scale(1))
            }
            .frame(height: max(240, CGFloat(top.count) * 30))
            .accessibilityLabel("Feature importance chart")

            // The chart stated in words, always visible.
            Text(interpretation.featureChartDescription)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)

            Divider()

            ForEach(Array(top.enumerated()), id: \.element.id) { position, feature in
                HStack(spacing: Theme.Spacing.regular) {
                    Text("\(position + 1)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.secondaryText)
                        .frame(minWidth: 20, alignment: .trailing)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.displayName)
                            .font(.subheadline)
                        if feature.isDerived {
                            Text("Constructed sub-score")
                                .font(.caption)
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    Spacer(minLength: Theme.Spacing.tight)
                    Text("\((feature.importance * 100).scoreText)%")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(position + 1). \(feature.displayName)")
                .accessibilityValue("\((feature.importance * 100).scoreText) percent"
                    + (feature.isDerived ? ". Constructed sub-score." : ""))
            }
        }
    }

    // MARK: - Plain English

    @ViewBuilder
    private var interpretationCard: some View {
        let interpretation = self.interpretation
        if let best = interpretation.bestByF1, let worst = interpretation.worstByF1 {
            Card {
                SectionHeader(title: "What these numbers mean")

                Text("**\(best.name)** scored highest, with an F1 of \(ModelMetric.f1.format(best.f1))\(interpretation.sweepsAllMetrics ? " — and it led on every metric measured" : "").")
                    .font(.subheadline)

                if let bundled = interpretation.bundledModel,
                   let rank = interpretation.bundledModelRank,
                   bundled.id != best.id {
                    // Worth stating plainly: the file shipped with this project
                    // is called "best_random_forest", but the recorded results
                    // do not support that name.
                    Text("The model saved with this project is the **\(bundled.name)**, which ranked \(rank) of \(interpretation.results.count) by F1 (\(ModelMetric.f1.format(bundled.f1))). Its filename says \"best\", but on these recorded results it was the weakest of the four.")
                        .font(.subheadline)
                }

                Text("The spread between them is smaller than it looks. Working back from the reported precision and recall, the test set held about 250 counties of which only 12 were labelled distressed — so \(best.name) found all 12 and \(worst.name) found 10. The whole difference between best and worst is **two counties**.")
                    .font(.subheadline)

                Divider()

                ForEach(ModelMetric.allCases) { metric in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.title)
                            .font(.subheadline.weight(.semibold))
                        Text(metric.plainEnglish)
                            .font(.footnote)
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 2)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: - Limitations

    private var limitationsCard: some View {
        let share = interpretation.derivedFeatureShare

        return Card {
            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.riskColor(.medium))
                    .accessibilityHidden(true)
                Text("Limitations")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
            }

            limitation(
                "This is a research model, not a production one.",
                "It was built to explore the data during a student research project. It is not monitored, retrained, or validated on an ongoing basis."
            )

            if share > 0 {
                limitation(
                    "The model is largely rediscovering its own answer key.",
                    "\(share.scoreText)% of its predictive weight sits in constructed sub-scores — housing stress, cost pressure, and the rest. Those same sub-scores are what the Financial Distress Index is calculated from, and the index is what produced the training labels. Scores this high measure internal consistency, not an ability to predict real hardship."
                )
            }

            limitation(
                "The risk labels are constructed, not observed.",
                "No county in this data was labelled using a real-world outcome such as an eviction filing, a default, or a bankruptcy. The labels come from a formula this project defined."
            )

            limitation(
                "The test set was small.",
                "Roughly 250 counties with about 12 positive cases. A single misclassification moves accuracy by 0.4 points, so small differences between these models are noise."
            )

            limitation(
                "This is not advice.",
                "Nothing on this page is financial, legal, or government-benefit advice, and none of it describes any individual's circumstances."
            )

            limitation(
                "What a future version would need.",
                "Labels drawn from independently observed outcomes, a held-out test set large enough to separate the models, and validation against counties the model never saw during development."
            )
        }
    }

    private func limitation(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(body)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Core ML

    private var coreMLCard: some View {
        Card {
            SectionHeader(
                title: "Why the model does not run in the app",
                subtitle: "phase2_best_random_forest_model.pkl"
            )
            Text("The trained model is a Python pickle file. Swift cannot read it — pickle embeds Python class paths and needs a Python interpreter and the exact scikit-learn version to rebuild the object.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
            Text("Converting it with Apple's coremltools would produce a Core ML model Xcode can compile and call from Swift. Even then it would sit alongside the Financial Distress Index rather than replace it: the index can explain why a county scores what it does, and a converted forest cannot.")
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)
        }
    }
}

// MARK: - Model card

/// One model's five metrics. A card rather than a table row, because a
/// five-column table is unreadable at phone width and collapses badly under
/// larger Dynamic Type sizes.
struct ModelResultCard: View {
    let result: ModelResult
    let isBest: Bool
    let isBundled: Bool

    var body: some View {
        Card {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.tight) {
                Text(result.name)
                    .font(.headline)
                Spacer(minLength: Theme.Spacing.tight)
                if isBest {
                    // Badge carries an icon and words, never colour alone.
                    Label("Best F1", systemImage: "rosette")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.riskColor(.low))
                        .padding(.horizontal, Theme.Spacing.tight)
                        .padding(.vertical, 4)
                        .background(Theme.riskColor(.low).opacity(0.12), in: Capsule())
                }
            }

            if isBundled {
                Text("Saved with this project as a .pkl file")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            ForEach(ModelMetric.allCases) { metric in
                HStack(alignment: .firstTextBaseline) {
                    Text(metric.title)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer(minLength: Theme.Spacing.tight)
                    Text(metric.format(result.value(for: metric)))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                }
                .padding(.vertical, 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(result.name + (isBest ? ", best F1 score" : ""))
        .accessibilityValue(
            ModelMetric.allCases
                .map { "\($0.title) \($0.format(result.value(for: $0)))" }
                .joined(separator: ", ")
        )
    }
}

// MARK: - Inline error

/// Section-level failure. Friendly first, technical detail behind a disclosure.
struct InlineErrorCard: View {
    let title: String
    let message: String
    var detail: String?

    @State private var showsDetail = false

    var body: some View {
        Card {
            HStack(spacing: Theme.Spacing.tight) {
                Image(systemName: "doc.questionmark")
                    .foregroundStyle(Theme.secondaryText)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            Text(message)
                .font(.footnote)
                .foregroundStyle(Theme.secondaryText)

            if let detail {
                DisclosureGroup("Technical details", isExpanded: $showsDetail) {
                    Text(detail)
                        .font(.caption.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.top, Theme.Spacing.tight)
                }
                .font(.footnote)
            }
        }
    }
}
