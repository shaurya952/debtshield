import Foundation

/// The Financial Distress Index, reimplemented in Swift.
///
/// This is a faithful port of `engineer_features()` in
/// `debtshield_streamlit_app.py`. Given the bundled dataset it reproduces the
/// deployed Streamlit numbers to within floating-point noise — see
/// `RiskScoringTests` for the pinned expectations.
///
/// ## Where Core ML fits later
///
/// This engine is deliberately a pure, synchronous, rule-based function:
/// `[CountyRecord] -> [ScoredCounty]`. It is transparent and explainable, which
/// is what the Risk Drivers and Recommendations screens need.
///
/// `phase2_best_random_forest_model.pkl` is a scikit-learn model and cannot be
/// loaded by Swift. When it is converted (`coremltools.converters.sklearn`
/// produces a `.mlmodel`, which Xcode compiles to `.mlmodelc`), the intended
/// shape is a *second, parallel* predictor rather than a replacement:
///
/// ```swift
/// protocol RiskPredictor {
///     func predict(_ record: CountyRecord) throws -> (label: RiskLevel, confidence: Double?)
/// }
/// ```
///
/// `RiskScoring` would conform to it as the rule-based baseline, and a
/// `CoreMLRiskPredictor` would conform as the learned model. The Model
/// Performance screen (Phase 7) then shows both side by side and labels which
/// is which — the same separation the Streamlit About page insists on. The
/// index must stay rule-based so the app can always explain *why*.
enum RiskScoring {

    // MARK: - Normalisation primitives

    /// Linear 0–100 scaling, clamped. Port of `score_between()`.
    static func score(_ value: Double, low: Double, high: Double) -> Double {
        guard high != low else { return 0 }
        return min(max((value - low) / (high - low) * 100, 0), 100)
    }

    /// Port of `inverse_score_between()`. Higher input means *lower* risk.
    static func inverseScore(_ value: Double, low: Double, high: Double) -> Double {
        min(max(100 - score(value, low: low, high: high), 0), 100)
    }

    // MARK: - Defaults
    //
    // These mirror the defaults baked into the Python `get_col()` calls. They
    // only apply to drivers that are *excluded* from the index for the bundled
    // dataset, so they never move a county's score — but keeping them here
    // documents the parity and keeps the code ready for richer data.

    private static let defaultEnergyBurdenPct = 6.5
    private static let defaultLowIncomeLowAccessPct = 17.4

    // MARK: - Per-driver scores

    static func housingScore(_ r: CountyRecord) -> Double {
        let annualRent = (r.medianGrossRent ?? 0) * 12
        let income = r.medianHouseholdIncome ?? 0
        // Python replaces income 0 with NaN, then fills the ratio with 0.
        let rentToIncome = income > 0 ? (annualRent / income * 100) : 0

        let value =
            0.45 * score(r.rentBurdenPct ?? 0, low: 20, high: 60) +
            0.35 * score(rentToIncome, low: 15, high: 45) +
            0.20 * score(r.evictionFilingRate ?? 0, low: 0, high: 8)
        return min(max(value, 0), 100)
    }

    static func rentToIncomeRatio(_ r: CountyRecord) -> Double? {
        guard let income = r.medianHouseholdIncome, income > 0,
              let rent = r.medianGrossRent else { return nil }
        return rent * 12 / income * 100
    }

    static func debtScore(_ r: CountyRecord) -> Double {
        let income = r.medianHouseholdIncome ?? 0
        let debtAmountRatio = income > 0 ? (r.avgHouseholdDebt ?? 0) / income : 0
        let value =
            0.40 * score(r.debtToIncomeRatio ?? 0, low: 0.4, high: 2.5) +
            0.30 * score(debtAmountRatio, low: 0.5, high: 3.0) +
            0.30 * score(r.creditCardDelinquencyRate ?? 0, low: 0, high: 8)
        return min(max(value, 0), 100)
    }

    static func costScore(_ r: CountyRecord) -> Double {
        let value =
            0.40 * score(r.povertyRate ?? 0, low: 5, high: 30) +
            0.40 * score(r.unemploymentRate ?? 0, low: 2, high: 12) +
            0.20 * inverseScore(r.jobGrowthPct ?? 0, low: -5, high: 5)
        return min(max(value, 0), 100)
    }

    // MARK: - Explainability

    /// One weighted input to a driver score.
    ///
    /// This is what turns "Housing: 12.6" into something a reader can argue
    /// with. `score` is nil when the dataset has no source for that input — and
    /// on the bundled data two of these are permanently nil, which is itself
    /// worth showing: a missing input contributes zero, which drags the driver
    /// down and is the main reason housing scores look so low nationally.
    struct DriverComponent: Identifiable, Sendable {
        let label: String
        let weightPercent: Int
        let score: Double?
        /// The underlying figure, e.g. "25.4%".
        let sourceValue: String?

        var id: String { label }
        var isMeasured: Bool { score != nil }
    }

    static func components(of kind: DriverKind, for r: CountyRecord) -> [DriverComponent] {
        switch kind {
        case .housing:
            let rentToIncome = rentToIncomeRatio(r)
            return [
                DriverComponent(
                    label: "Rent burden",
                    weightPercent: 45,
                    score: r.rentBurdenPct.map { score($0, low: 20, high: 60) },
                    sourceValue: r.rentBurdenPct.map { "\($0.scoreText)%" }
                ),
                DriverComponent(
                    label: "Rent as share of income",
                    weightPercent: 35,
                    score: rentToIncome.map { score($0, low: 15, high: 45) },
                    sourceValue: rentToIncome.map { "\($0.scoreText)%" }
                ),
                DriverComponent(
                    label: "Eviction filings",
                    weightPercent: 20,
                    score: r.evictionFilingRate.map { score($0, low: 0, high: 8) },
                    sourceValue: r.evictionFilingRate.map { "\($0.scoreText)%" }
                )
            ]
        case .cost:
            return [
                DriverComponent(
                    label: "Poverty rate",
                    weightPercent: 40,
                    score: r.povertyRate.map { score($0, low: 5, high: 30) },
                    sourceValue: r.povertyRate.map { "\($0.scoreText)%" }
                ),
                DriverComponent(
                    label: "Unemployment rate",
                    weightPercent: 40,
                    score: r.unemploymentRate.map { score($0, low: 2, high: 12) },
                    sourceValue: r.unemploymentRate.map { "\($0.scoreText)%" }
                ),
                DriverComponent(
                    label: "Job growth",
                    weightPercent: 20,
                    score: r.jobGrowthPct.map { inverseScore($0, low: -5, high: 5) },
                    sourceValue: r.jobGrowthPct.map { "\($0.scoreText)%" }
                )
            ]
        case .debt:
            return [
                DriverComponent(label: "Debt-to-income ratio", weightPercent: 40,
                                score: r.debtToIncomeRatio.map { score($0, low: 0.4, high: 2.5) },
                                sourceValue: r.debtToIncomeRatio.map { $0.scoreText }),
                DriverComponent(label: "Household debt vs income", weightPercent: 30,
                                score: nil, sourceValue: nil),
                DriverComponent(label: "Credit card delinquency", weightPercent: 30,
                                score: r.creditCardDelinquencyRate.map { score($0, low: 0, high: 8) },
                                sourceValue: r.creditCardDelinquencyRate.map { "\($0.scoreText)%" })
            ]
        case .energy:
            return [
                DriverComponent(label: "Energy burden", weightPercent: 100,
                                score: r.energyBurdenPct.map { score($0, low: 2, high: 12) },
                                sourceValue: r.energyBurdenPct.map { "\($0.scoreText)%" })
            ]
        case .food:
            return [
                DriverComponent(label: "Low income, low food access", weightPercent: 100,
                                score: r.lowIncomeLowAccessPct.map { score($0, low: 0, high: 30) },
                                sourceValue: r.lowIncomeLowAccessPct.map { "\($0.scoreText)%" })
            ]
        }
    }

    // MARK: - Scorability

    /// Indicators the index cannot be computed without, named the way a person
    /// would say them.
    ///
    /// The Census publishes no median household income for the very smallest
    /// counties — Esmeralda County, Nevada and Kenedy County, Texas are the two
    /// in the current dataset. They are reported as unscored rather than
    /// dropped, and rather than being given a substituted value.
    static func missingRequiredIndicators(_ r: CountyRecord) -> [String] {
        var missing: [String] = []
        if r.medianHouseholdIncome == nil { missing.append("median household income") }
        if r.rentBurdenPct == nil { missing.append("rent burden") }
        if r.povertyRate == nil { missing.append("poverty rate") }
        if r.unemploymentRate == nil { missing.append("unemployment rate") }
        return missing
    }

    static func energyScore(_ r: CountyRecord) -> Double {
        score(r.energyBurdenPct ?? defaultEnergyBurdenPct, low: 2, high: 12)
    }

    static func foodScore(_ r: CountyRecord) -> Double {
        score(r.lowIncomeLowAccessPct ?? defaultLowIncomeLowAccessPct, low: 0, high: 30)
    }

    // MARK: - Index

    /// Weights renormalised over the drivers the dataset can actually measure.
    ///
    /// Port of the `active_weights` / `norm_weights` block in Python. With the
    /// bundled 9-column CSV this resolves to Housing 0.60 and Cost 0.40.
    static func normalisedWeights(for capabilities: DatasetCapabilities) -> [DriverKind: Double] {
        let active = capabilities.measuredDrivers
        let total = active.reduce(0.0) { $0 + $1.baseWeight }
        guard total > 0 else { return [:] }
        return Dictionary(uniqueKeysWithValues: active.map { ($0, $0.baseWeight / total) })
    }

    static func drivers(for record: CountyRecord, capabilities: DatasetCapabilities) -> [DriverScore] {
        let measured = capabilities.measuredDrivers
        let raw: [DriverKind: Double] = [
            .housing: housingScore(record),
            .debt: debtScore(record),
            .cost: costScore(record),
            .energy: energyScore(record),
            .food: foodScore(record)
        ]
        // Stable, presentation-friendly order.
        return DriverKind.allCases.map { kind in
            DriverScore(kind: kind, score: raw[kind] ?? 0, isMeasured: measured.contains(kind))
        }
    }

    static func index(from drivers: [DriverScore], capabilities: DatasetCapabilities) -> Double {
        let weights = normalisedWeights(for: capabilities)
        let value = drivers.reduce(0.0) { total, driver in
            total + (weights[driver.kind] ?? 0) * driver.score
        }
        return min(max(value, 0), 100)
    }

    static func score(_ record: CountyRecord, capabilities: DatasetCapabilities) -> ScoredCounty {
        let missing = missingRequiredIndicators(record)
        guard missing.isEmpty else {
            return ScoredCounty(
                record: record,
                drivers: [],
                index: nil,
                riskLevel: nil,
                missingIndicators: missing
            )
        }

        let drivers = drivers(for: record, capabilities: capabilities)
        let index = index(from: drivers, capabilities: capabilities)
        return ScoredCounty(
            record: record,
            drivers: drivers,
            index: index,
            riskLevel: .from(index: index),
            missingIndicators: []
        )
    }

    static func scoreAll(_ records: [CountyRecord], capabilities: DatasetCapabilities) -> [ScoredCounty] {
        records.map { score($0, capabilities: capabilities) }
    }
}
