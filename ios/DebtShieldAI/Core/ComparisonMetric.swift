import Foundation

/// The indicators shown side by side on the Compare screen.
///
/// `value(for:)` returns nil when the bundled dataset has no source for that
/// indicator. Three of these — debt-to-income, energy burden, and food access —
/// are nil for every county today. They are listed anyway, labelled "Not
/// reported", because hiding them would misrepresent what the index is built
/// from. When those sources are added to the CSV they light up with no UI work.
enum ComparisonMetric: String, CaseIterable, Identifiable, Sendable {
    case index
    case poverty
    case rentBurden
    case unemployment
    case debtToIncome
    case energyBurden
    case foodAccess

    var id: String { rawValue }

    var title: String {
        switch self {
        case .index: return "Financial Distress Index"
        case .poverty: return "Poverty rate"
        case .rentBurden: return "Rent burden"
        case .unemployment: return "Unemployment rate"
        case .debtToIncome: return "Debt-to-income ratio"
        case .energyBurden: return "Energy burden"
        case .foodAccess: return "Food access"
        }
    }

    /// Plain English, for the "why this matters" line under each card.
    var explanation: String {
        switch self {
        case .index:
            return "The overall 0–100 score. Higher means more financial pressure."
        case .poverty:
            return "Share of people living below the federal poverty line."
        case .rentBurden:
            return "Share of renters spending more than 30% of their income on rent."
        case .unemployment:
            return "Share of the labour force without work and looking for it."
        case .debtToIncome:
            return "How much households owe compared with what they earn."
        case .energyBurden:
            return "Share of household income spent on heating, cooling, and electricity."
        case .foodAccess:
            return "Share of people on low incomes who live far from an affordable grocery store."
        }
    }

    func value(for county: ScoredCounty) -> Double? {
        switch self {
        case .index: return county.index
        case .poverty: return county.record.povertyRate
        case .rentBurden: return county.record.rentBurdenPct
        case .unemployment: return county.record.unemploymentRate
        case .debtToIncome: return county.record.debtToIncomeRatio
        case .energyBurden: return county.record.energyBurdenPct
        case .foodAccess: return county.record.lowIncomeLowAccessPct
        }
    }

    func formatted(_ value: Double) -> String {
        switch self {
        case .index:
            return value.scoreText
        case .debtToIncome:
            return value.formatted(.number.precision(.fractionLength(2)))
        case .poverty, .rentBurden, .unemployment, .energyBurden, .foodAccess:
            return "\(value.scoreText)%"
        }
    }

    /// Upper bound for the comparison bars. The index is always drawn against
    /// the full 0–100 scale so a 15 never looks like a 90; the rest scale to
    /// the largest value on screen, which is what makes differences visible.
    var fixedScaleMax: Double? {
        self == .index ? 100 : nil
    }

    /// Why it exists in the app even when the data is missing.
    var missingDataNote: String {
        "Not reported in this dataset"
    }
}
