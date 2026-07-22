import Foundation

/// The seven adjustable inputs of the Scenario Simulator.
struct ScenarioInputs: Equatable, Sendable {
    var medianHouseholdIncome: Double
    var rentBurdenPct: Double
    var povertyRate: Double
    var unemploymentRate: Double
    var debtToIncomeRatio: Double
    var energyBurdenPct: Double
    var lowIncomeLowAccessPct: Double

    /// Debt, energy, and food access have no source in the bundled dataset, so
    /// they are excluded from the real index. Turning this on adds them to the
    /// scenario — which also changes the weighting, so it is off by default and
    /// clearly labelled when on.
    var includesUnmeasuredDrivers: Bool

    /// Fallbacks for the three drivers the dataset cannot measure. These match
    /// the defaults baked into the Python `get_col()` calls, so a scenario that
    /// switches them on starts from the same place the Streamlit app would.
    static let defaultDebtToIncomeRatio = 1.41
    static let defaultEnergyBurdenPct = 6.5
    static let defaultLowIncomeLowAccessPct = 17.4

    static func baseline(for county: ScoredCounty) -> ScenarioInputs {
        let r = county.record
        return ScenarioInputs(
            medianHouseholdIncome: r.medianHouseholdIncome ?? 60000,
            rentBurdenPct: r.rentBurdenPct ?? 30,
            povertyRate: r.povertyRate ?? 12,
            unemploymentRate: r.unemploymentRate ?? 4,
            debtToIncomeRatio: r.debtToIncomeRatio ?? defaultDebtToIncomeRatio,
            energyBurdenPct: r.energyBurdenPct ?? defaultEnergyBurdenPct,
            lowIncomeLowAccessPct: r.lowIncomeLowAccessPct ?? defaultLowIncomeLowAccessPct,
            includesUnmeasuredDrivers: false
        )
    }
}

/// One slider on the simulator.
enum ScenarioField: String, CaseIterable, Identifiable, Sendable {
    case income
    case rentBurden
    case poverty
    case unemployment
    case debtToIncome
    case energyBurden
    case foodAccess

    var id: String { rawValue }

    var title: String {
        switch self {
        case .income: return "Median household income"
        case .rentBurden: return "Rent burden"
        case .poverty: return "Poverty rate"
        case .unemployment: return "Unemployment rate"
        case .debtToIncome: return "Debt-to-income ratio"
        case .energyBurden: return "Energy burden"
        case .foodAccess: return "Food access pressure"
        }
    }

    var explanation: String {
        switch self {
        case .income: return "What a typical household earns in a year."
        case .rentBurden: return "Share of renters spending more than 30% of income on rent."
        case .poverty: return "Share of people below the federal poverty line."
        case .unemployment: return "Share of the labour force out of work and looking."
        case .debtToIncome: return "Total household debt divided by annual income."
        case .energyBurden: return "Share of income spent on heating, cooling, and electricity."
        case .foodAccess: return "Share of low-income people living far from an affordable grocery store."
        }
    }

    var keyPath: WritableKeyPath<ScenarioInputs, Double> {
        switch self {
        case .income: return \.medianHouseholdIncome
        case .rentBurden: return \.rentBurdenPct
        case .poverty: return \.povertyRate
        case .unemployment: return \.unemploymentRate
        case .debtToIncome: return \.debtToIncomeRatio
        case .energyBurden: return \.energyBurdenPct
        case .foodAccess: return \.lowIncomeLowAccessPct
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .income: return 15000...250000
        case .rentBurden: return 0...80
        case .poverty: return 0...45
        case .unemployment: return 0...20
        case .debtToIncome: return 0...3
        case .energyBurden: return 0...20
        case .foodAccess: return 0...60
        }
    }

    var step: Double {
        switch self {
        case .income: return 1000
        case .rentBurden, .poverty, .foodAccess: return 0.5
        case .unemployment, .energyBurden: return 0.1
        case .debtToIncome: return 0.05
        }
    }

    /// Which driver this input feeds, so the UI can group and explain.
    var driver: DriverKind {
        switch self {
        case .income: return .housing
        case .rentBurden: return .housing
        case .poverty, .unemployment: return .cost
        case .debtToIncome: return .debt
        case .energyBurden: return .energy
        case .foodAccess: return .food
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .income:
            return value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        case .debtToIncome:
            return value.formatted(.number.precision(.fractionLength(2)))
        default:
            return "\(value.scoreText)%"
        }
    }
}

/// Runs a what-if scenario through the same scoring engine as the real index.
///
/// Nothing here re-implements the maths. The scenario builds a modified
/// `CountyRecord` and hands it to `RiskScoring`, so a simulated score can never
/// drift from a real one.
///
/// This is an **estimate of the index under different inputs**, not a forecast.
/// It says what the score would be if these numbers were different — it does
/// not predict that they will be, and it models no second-order effects (for
/// example, rising incomes tend to raise rents too; the simulator holds rent
/// burden fixed unless the user moves it).
enum ScenarioEngine {

    static func capabilities(
        base: DatasetCapabilities,
        includingUnmeasured: Bool
    ) -> DatasetCapabilities {
        guard includingUnmeasured else { return base }
        var extended = base
        extended.hasDebtSources = true
        extended.hasEnergySource = true
        extended.hasFoodSource = true
        return extended
    }

    static func record(for county: ScoredCounty, inputs: ScenarioInputs) -> CountyRecord {
        var record = county.record
        record.medianHouseholdIncome = inputs.medianHouseholdIncome
        record.rentBurdenPct = inputs.rentBurdenPct
        record.povertyRate = inputs.povertyRate
        record.unemploymentRate = inputs.unemploymentRate
        if inputs.includesUnmeasuredDrivers {
            record.debtToIncomeRatio = inputs.debtToIncomeRatio
            record.energyBurdenPct = inputs.energyBurdenPct
            record.lowIncomeLowAccessPct = inputs.lowIncomeLowAccessPct
        }
        return record
    }

    static func simulate(
        county: ScoredCounty,
        inputs: ScenarioInputs,
        baseCapabilities: DatasetCapabilities
    ) -> ScoredCounty {
        RiskScoring.score(
            record(for: county, inputs: inputs),
            capabilities: capabilities(base: baseCapabilities,
                                       includingUnmeasured: inputs.includesUnmeasuredDrivers)
        )
    }
}

/// A scenario turned into plain sentences.
struct ScenarioExplanation: Sendable {
    /// "Poverty rate lowered from 35.7% to 20.0%."
    var inputChanges: [String]
    /// "Cost of Living pressure falls 24.6 points."
    var driverEffects: [String]
    /// The headline outcome.
    var summary: String
    /// Risk band movement, or a statement that it held.
    var riskChange: String
    /// Extra caveat when the weighting was altered mid-scenario.
    var weightingNote: String?

    var isUnchanged: Bool { inputChanges.isEmpty }

    /// Everything as one string, for VoiceOver.
    var spoken: String {
        var parts = inputChanges + driverEffects
        parts.append(summary)
        parts.append(riskChange)
        if let weightingNote { parts.append(weightingNote) }
        return parts.joined(separator: " ")
    }

    static func build(
        original: ScoredCounty,
        simulated: ScoredCounty,
        baseline: ScenarioInputs,
        inputs: ScenarioInputs
    ) -> ScenarioExplanation {
        var changes: [String] = []
        for field in ScenarioField.allCases {
            // Unmeasured inputs only count as changes when they are switched on.
            if !inputs.includesUnmeasuredDrivers,
               [DriverKind.debt, .energy, .food].contains(field.driver) {
                continue
            }
            let from = baseline[keyPath: field.keyPath]
            let to = inputs[keyPath: field.keyPath]
            guard abs(from - to) > 0.0001 else { continue }
            let verb = to > from ? "raised" : "lowered"
            changes.append("\(field.title) \(verb) from \(field.format(from)) to \(field.format(to)).")
        }

        var effects: [String] = []
        for driver in DriverKind.allCases {
            guard let before = original.driver(driver), before.isMeasured,
                  let after = simulated.driver(driver), after.isMeasured else { continue }
            let delta = after.score - before.score
            guard abs(delta) >= 0.05 else { continue }
            let direction = delta > 0 ? "rises" : "falls"
            effects.append("\(driver.title) pressure \(direction) \(abs(delta).scoreText) points.")
        }

        let originalIndex = original.index ?? 0
        let simulatedIndex = simulated.index ?? 0
        let delta = simulatedIndex - originalIndex

        let summary: String
        if abs(delta) < 0.05 {
            summary = "The Financial Distress Index stays at about \(originalIndex.scoreText)."
        } else {
            let direction = delta > 0 ? "rises" : "falls"
            summary = "The Financial Distress Index \(direction) \(abs(delta).scoreText) points, from \(originalIndex.scoreText) to \(simulatedIndex.scoreText)."
        }

        let riskChange: String
        switch (original.riskLevel, simulated.riskLevel) {
        case let (before?, after?) where before != after:
            riskChange = "Risk level moves from \(before.label) to \(after.label)."
        case let (before?, _):
            riskChange = "Risk level stays \(before.label)."
        default:
            riskChange = "Risk level cannot be determined."
        }

        let weightingNote = inputs.includesUnmeasuredDrivers
            ? "This scenario includes debt, energy, and food access, which this county has no real data for. That changes how the index is weighted, so the simulated score is not directly comparable with the original."
            : nil

        return ScenarioExplanation(
            inputChanges: changes,
            driverEffects: effects,
            summary: summary,
            riskChange: riskChange,
            weightingNote: weightingNote
        )
    }
}
