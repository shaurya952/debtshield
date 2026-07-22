import Foundation

// MARK: - Errors

/// Failures loading the model result files, phrased for a person.
///
/// Separate from `DataError` so the wording can be specific: a missing model
/// file degrades one section of one screen, whereas a missing county dataset
/// stops the app. These are shown as inline cards, not full-screen errors.
enum ModelDataError: LocalizedError, Equatable {
    case fileMissing(name: String)
    case unreadable(name: String, underlying: String)
    case missingColumns(name: String, columns: [String])
    case noRows(name: String)

    var title: String {
        switch self {
        case .fileMissing: return "Results file not found"
        case .unreadable: return "Results file could not be read"
        case .missingColumns: return "Results file is missing information"
        case .noRows: return "No results found"
        }
    }

    var message: String {
        switch self {
        case .fileMissing:
            return "The model results that belong in this section are not included in the app. Everything else on this page still works."
        case .unreadable:
            return "The model results could not be opened. They may have been damaged."
        case .missingColumns(_, let columns):
            return "The results are missing the columns needed to display them: \(ListFormatter.localizedString(byJoining: columns))."
        case .noRows:
            return "The results file loaded but contained no rows."
        }
    }

    var technicalDetail: String {
        switch self {
        case .fileMissing(let name):
            return "\(name) not found in Bundle.main. Check Target ▸ Build Phases ▸ Copy Bundle Resources."
        case .unreadable(let name, let underlying):
            return "\(name): \(underlying)"
        case .missingColumns(let name, let columns):
            return "\(name) missing columns: \(columns.joined(separator: ", "))"
        case .noRows(let name):
            return "\(name) parsed to zero rows."
        }
    }

    var errorDescription: String? { message }
}

// MARK: - Model results

/// One row of `phase2_model_comparison_results.csv`.
struct ModelResult: Identifiable, Sendable {
    let name: String
    let accuracy: Double
    let precision: Double
    let recall: Double
    let f1: Double
    let rocAuc: Double

    var id: String { name }

    func value(for metric: ModelMetric) -> Double {
        switch metric {
        case .accuracy: return accuracy
        case .precision: return precision
        case .recall: return recall
        case .f1: return f1
        case .rocAuc: return rocAuc
        }
    }
}

enum ModelMetric: String, CaseIterable, Identifiable, Sendable {
    case accuracy, precision, recall, f1, rocAuc

    var id: String { rawValue }

    var title: String {
        switch self {
        case .accuracy: return "Accuracy"
        case .precision: return "Precision"
        case .recall: return "Recall"
        case .f1: return "F1 score"
        case .rocAuc: return "ROC-AUC"
        }
    }

    /// One sentence, no statistics background assumed.
    var plainEnglish: String {
        switch self {
        case .accuracy:
            return "How often the model was right overall. Misleading when one answer is far more common than the other."
        case .precision:
            return "When the model flagged a county as distressed, how often it was correct."
        case .recall:
            return "Of the counties that really were distressed, how many the model found."
        case .f1:
            return "Precision and recall combined into one number. The fairest single summary here."
        case .rocAuc:
            return "How well the model separates distressed from non-distressed counties across all thresholds."
        }
    }

    /// Three decimals normally, but never rounds a value up into looking
    /// perfect: Logistic Regression's ROC-AUC of 0.99965 would print as "1.000"
    /// at three places, which claims a flawless separation the model did not
    /// achieve. Precision widens until the printed value is honestly below 1.
    func format(_ value: Double) -> String {
        guard value < 1 else {
            return value.formatted(.number.precision(.fractionLength(3)))
        }
        for digits in 3...6 {
            let scale = pow(10.0, Double(digits))
            if (value * scale).rounded() < scale {
                return value.formatted(.number.precision(.fractionLength(digits)))
            }
        }
        return value.formatted(.number.precision(.fractionLength(6)))
    }
}

// MARK: - Feature importance

/// One row of `phase2_feature_importance.csv`.
struct FeatureImportance: Identifiable, Sendable {
    /// Raw column name, e.g. `derived_housing_stress_score`.
    let rawName: String
    let importance: Double

    var id: String { rawName }

    /// True when the feature is one of the constructed sub-scores the index is
    /// built from, rather than a directly measured statistic. Central to the
    /// limitations section: these features are derived from the same formula
    /// that produced the training labels.
    var isDerived: Bool { rawName.hasPrefix("derived_") }

    /// Human-readable label.
    var displayName: String {
        Self.knownNames[rawName] ?? Self.humanise(rawName)
    }

    private static let knownNames: [String: String] = [
        "derived_housing_stress_score": "Housing stress score",
        "derived_cost_pressure_score": "Cost pressure score",
        "derived_energy_stress_score": "Energy stress score",
        "derived_debt_stress_score": "Debt stress score",
        "derived_food_access_risk_score": "Food access risk score",
        "derived_rent_to_income_ratio": "Rent-to-income ratio",
        "bls_unemployment_rate": "Unemployment rate",
        "acs_poverty_rate": "Poverty rate",
        "doe_total_energy_burden_pct": "Total energy burden",
        "usda_low_income_low_access_pct": "Low income, low food access",
        "nyfed_credit_card_delinquency_rate": "Credit card delinquency rate",
        "nyfed_mortgage_delinquency_rate": "Mortgage delinquency rate",
        "scf_debt_to_income_ratio": "Debt-to-income ratio"
    ]

    /// Fallback for any column not in the table above, so a re-trained model
    /// with new features still reads sensibly.
    private static func humanise(_ raw: String) -> String {
        let prefixes = ["derived_", "acs_", "bls_", "doe_", "usda_", "nyfed_", "scf_", "cdc_", "fhfa_", "mit_", "zillow_"]
        var text = raw
        for prefix in prefixes where text.hasPrefix(prefix) {
            text = String(text.dropFirst(prefix.count))
            break
        }
        text = text
            .replacingOccurrences(of: "_pct", with: " percentage")
            .replacingOccurrences(of: "_", with: " ")
        return text.prefix(1).uppercased() + text.dropFirst()
    }
}

// MARK: - Loader

/// Loads the two Phase 2 result files from the app bundle.
///
/// ## About `phase2_best_random_forest_model.pkl`
///
/// That file is a pickled scikit-learn estimator. Swift cannot load it: pickle
/// is a Python-specific serialisation format that embeds Python class paths and
/// requires a Python interpreter plus the exact scikit-learn version to
/// reconstruct. There is no Swift reader for it, and there should not be —
/// unpickling arbitrary data executes code.
///
/// **The conversion path, for a future phase:**
///
/// 1. In Python, `pip install coremltools`, then
///    `coremltools.converters.sklearn.convert(model, input_features, output_feature)`
///    which produces a `.mlmodel`.
/// 2. Drag the `.mlmodel` into Xcode. It compiles to `.mlmodelc` at build time
///    and Xcode generates a Swift class with a typed `prediction(input:)`.
/// 3. Implement a `CoreMLRiskPredictor` conforming to the `RiskPredictor`
///    protocol sketched in `RiskScoring`, and show its output *alongside* the
///    rule-based index rather than replacing it.
///
/// The rule-based index must stay the primary score regardless: it can explain
/// why a county scores what it does, and a converted forest cannot.
///
/// Until that work happens, this screen reports the metrics recorded during
/// Python training. Nothing here runs a model.
struct ModelPerformanceLoader {

    let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    static let comparisonResource = "phase2_model_comparison_results"
    static let importanceResource = "phase2_feature_importance"

    // MARK: Comparison

    func loadModelResults() -> Result<[ModelResult], ModelDataError> {
        let fileName = "\(Self.comparisonResource).csv"
        return readTable(resource: Self.comparisonResource, fileName: fileName).flatMap { table in
            let required = ["model", "accuracy", "precision", "recall", "f1 score", "roc-auc"]
            let missing = required.filter { table.columnIndex[$0] == nil }
            guard missing.isEmpty else {
                return .failure(.missingColumns(name: fileName, columns: missing))
            }

            let results = table.rows.compactMap { row -> ModelResult? in
                func number(_ column: String) -> Double? {
                    guard let i = table.columnIndex[column], i < row.count else { return nil }
                    return Double(row[i])
                }
                guard let nameIndex = table.columnIndex["model"], nameIndex < row.count else { return nil }
                let name = row[nameIndex]
                guard !name.isEmpty,
                      let accuracy = number("accuracy"),
                      let precision = number("precision"),
                      let recall = number("recall"),
                      let f1 = number("f1 score"),
                      let rocAuc = number("roc-auc")
                else { return nil }
                return ModelResult(name: name, accuracy: accuracy, precision: precision,
                                   recall: recall, f1: f1, rocAuc: rocAuc)
            }

            guard !results.isEmpty else { return .failure(.noRows(name: fileName)) }
            return .success(results)
        }
    }

    // MARK: Importance

    func loadFeatureImportance() -> Result<[FeatureImportance], ModelDataError> {
        let fileName = "\(Self.importanceResource).csv"
        return readTable(resource: Self.importanceResource, fileName: fileName).flatMap { table in
            let required = ["feature", "importance"]
            let missing = required.filter { table.columnIndex[$0] == nil }
            guard missing.isEmpty else {
                return .failure(.missingColumns(name: fileName, columns: missing))
            }

            let features = table.rows.compactMap { row -> FeatureImportance? in
                guard let nameIndex = table.columnIndex["feature"], nameIndex < row.count,
                      let valueIndex = table.columnIndex["importance"], valueIndex < row.count,
                      !row[nameIndex].isEmpty,
                      let importance = Double(row[valueIndex])
                else { return nil }
                return FeatureImportance(rawName: row[nameIndex], importance: importance)
            }
            .sorted { $0.importance > $1.importance }

            guard !features.isEmpty else { return .failure(.noRows(name: fileName)) }
            return .success(features)
        }
    }

    // MARK: Shared

    /// Reuses the county loader's CSV parser so all three bundled files are
    /// read the same way.
    private func readTable(resource: String, fileName: String) -> Result<CSVLoader.Table, ModelDataError> {
        guard let url = bundle.url(forResource: resource, withExtension: "csv") else {
            return .failure(.fileMissing(name: fileName))
        }
        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            return .success(try CSVLoader.parseTable(text, fileName: fileName))
        } catch {
            return .failure(.unreadable(name: fileName, underlying: error.localizedDescription))
        }
    }
}

// MARK: - Interpretation

/// Facts about the recorded results that the screen states out loud.
///
/// These are computed rather than hardcoded, so they stay true if the CSVs are
/// regenerated from a different training run.
struct ModelInterpretation: Sendable {

    let results: [ModelResult]
    let features: [FeatureImportance]

    /// Best by F1 — the fairest single summary when positives are rare.
    var bestByF1: ModelResult? {
        results.max { $0.f1 < $1.f1 }
    }

    /// Worst by F1, so the screen can name the spread honestly.
    var worstByF1: ModelResult? {
        results.min { $0.f1 < $1.f1 }
    }

    /// True when one model wins on every single metric.
    var sweepsAllMetrics: Bool {
        guard let best = bestByF1 else { return false }
        return ModelMetric.allCases.allSatisfy { metric in
            results.allSatisfy { $0.value(for: metric) <= best.value(for: metric) }
        }
    }

    /// The model actually shipped as a `.pkl` in this project.
    static let bundledModelName = "Random Forest"

    var bundledModel: ModelResult? {
        results.first { $0.name == Self.bundledModelName }
    }

    /// Rank of the bundled model by F1, 1 = best.
    var bundledModelRank: Int? {
        guard let bundled = bundledModel else { return nil }
        return results.filter { $0.f1 > bundled.f1 }.count + 1
    }

    /// Share of total importance held by constructed `derived_*` features.
    ///
    /// The training labels were produced from the Financial Distress Index,
    /// which is itself computed from these same sub-scores. A high share here
    /// means the model is largely rediscovering the formula that generated its
    /// own answers — which is why the scores are near-perfect.
    var derivedFeatureShare: Double {
        let total = features.reduce(0) { $0 + $1.importance }
        guard total > 0 else { return 0 }
        let derived = features.filter(\.isDerived).reduce(0) { $0 + $1.importance }
        return derived / total * 100
    }

    func topFeatures(_ count: Int = 10) -> [FeatureImportance] {
        Array(features.prefix(count))
    }

    /// Spoken summary of the importance chart.
    var featureChartDescription: String {
        let top = topFeatures()
        guard let first = top.first else { return "No feature importance data." }
        let listed = top.prefix(3).map {
            "\($0.displayName) at \(($0.importance * 100).scoreText) percent"
        }
        return "Top \(top.count) features by importance. "
            + listed.joined(separator: ", ")
            + ". \(first.displayName) is the single largest contributor."
    }
}
