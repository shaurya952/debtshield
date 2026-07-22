import Foundation

/// Who the guidance is written for.
///
/// The same underlying finding needs different language depending on whether
/// the reader can change policy or is living with the outcome.
enum RecommendationAudience: String, CaseIterable, Identifiable, Sendable {
    case policymakers
    case residents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .policymakers: return "For policymakers"
        case .residents: return "For residents"
        }
    }

    var shortTitle: String {
        switch self {
        case .policymakers: return "Policymakers"
        case .residents: return "Residents"
        }
    }

    var introduction: String {
        switch self {
        case .policymakers:
            return "Intervention areas suggested by this county's strongest pressures, ranked against every other U.S. county."
        case .residents:
            return "Types of support that commonly exist for the pressures measured here. Eligibility and availability vary by state and county."
        }
    }
}

/// A single suggested area of action.
struct Recommendation: Identifiable, Sendable {
    let driver: DriverKind
    let severity: DriverSeverity
    let percentile: Double
    let score: Double
    let headline: String
    let actions: [String]

    var id: String { driver.id }

    /// Why this appears, stated with the numbers that produced it.
    ///
    /// Shares the top-and-bottom phrasing rules with `DriverStanding` so the
    /// same county is never described two different ways on two screens.
    var rationale: String {
        "\(driver.title) scores \(score.scoreText) out of 100 here — \(PercentilePhrasing.comparison(percentile))."
    }
}

/// Builds recommendations from a county's driver standings.
///
/// ## Why this does not use the Streamlit threshold
///
/// `debtshield_streamlit_app.py` emits a recommendation when a driver scores
/// 50 or more. Measured against the bundled dataset that produces:
///
/// - housing recommendations for **2** counties out of 3,142
/// - no recommendation at all, beyond a generic monitoring line, for **2,659**
///   counties — 85% of the country
///
/// The cause is structural, not a tuning mistake: drivers whose sub-components
/// have no data source contribute zero, so housing tops out well below 100 and
/// its median sits at 10.5. A fixed cut-off cannot work against a compressed
/// scale.
///
/// This engine ranks each driver against the national distribution instead, so
/// guidance is produced for the pressures that are genuinely unusual *for that
/// county*, and every county gets something specific and honest.
enum RecommendationEngine {

    /// Drivers at or above the 75th percentile nationally. If nothing clears
    /// that bar the county's single strongest driver is still returned, so the
    /// screen is never empty — but it is labelled honestly as lower pressure.
    static func recommendations(
        for standings: [DriverStanding],
        audience: RecommendationAudience
    ) -> [Recommendation] {
        let actionable = standings.filter { $0.severity.warrantsAction }
        let chosen = actionable.isEmpty ? Array(standings.prefix(1)) : actionable

        return chosen.map { standing in
            Recommendation(
                driver: standing.kind,
                severity: standing.severity,
                percentile: standing.percentile,
                score: standing.score,
                headline: headline(for: standing.kind, audience: audience),
                actions: actions(for: standing.kind, audience: audience)
            )
        }
    }

    // MARK: - Content

    static func headline(for driver: DriverKind, audience: RecommendationAudience) -> String {
        switch (driver, audience) {
        case (.housing, .policymakers):
            return "Reduce the pressure of rent on household budgets"
        case (.housing, .residents):
            return "Help with rent and eviction"
        case (.cost, .policymakers):
            return "Close the gap between earnings and everyday costs"
        case (.cost, .residents):
            return "Help with everyday costs"
        case (.debt, .policymakers):
            return "Reduce household debt distress"
        case (.debt, .residents):
            return "Help with debt"
        case (.energy, .policymakers):
            return "Lower the cost of keeping homes warm and cool"
        case (.energy, .residents):
            return "Help with energy bills"
        case (.food, .policymakers):
            return "Improve access to affordable food"
        case (.food, .residents):
            return "Help with food costs"
        }
    }

    /// Concrete, well-established programme types. Deliberately descriptive
    /// ("these programmes exist") rather than directive ("you should apply"),
    /// because this app is educational and is not licensed to give financial,
    /// legal, or benefits advice.
    static func actions(for driver: DriverKind, audience: RecommendationAudience) -> [String] {
        switch (driver, audience) {
        case (.housing, .policymakers):
            return [
                "Emergency rental assistance, targeted at households one missed payment from arrears.",
                "Eviction diversion and right-to-counsel programmes, which keep cases out of court entirely.",
                "Faster permitting and zoning reform to expand the supply of lower-cost rental housing.",
                "Landlord–tenant mediation funded before filings begin rather than after."
            ]
        case (.housing, .residents):
            return [
                "Emergency rental assistance programmes operate in most states, usually reachable by dialling 211.",
                "HUD-approved housing counselling agencies offer free guidance on rent, arrears, and eviction notices.",
                "Local legal aid organisations can often represent tenants who receive an eviction filing, at no cost.",
                "Some utilities and landlords offer hardship or payment-plan arrangements on request."
            ]
        case (.cost, .policymakers):
            return [
                "Benefits enrolment outreach — SNAP, WIC, and the Earned Income Tax Credit are widely under-claimed.",
                "Childcare subsidies, which frequently decide whether work is affordable at all.",
                "Workforce placement and training aimed at sectors actually hiring locally.",
                "Transit access to job centres, a common hidden barrier in rural counties."
            ]
        case (.cost, .residents):
            return [
                "Benefits screening tools can check eligibility for several programmes at once.",
                "VITA sites provide free tax preparation and help claim the Earned Income Tax Credit.",
                "Dialling 211 connects to local help with food, rent, utilities, and childcare.",
                "Community action agencies administer many local basic-needs programmes."
            ]
        case (.debt, .policymakers):
            return [
                "Funding for nonprofit credit counselling capacity.",
                "Medical debt relief purchasing, which retires large balances at low cost per dollar.",
                "Consumer protection enforcement against unlawful collection practices."
            ]
        case (.debt, .residents):
            return [
                "Nonprofit credit counselling agencies offer free or low-cost budget and debt reviews.",
                "Federal law places limits on how and when debt collectors may contact people.",
                "Hospitals are often required to offer financial assistance policies for medical bills."
            ]
        case (.energy, .policymakers):
            return [
                "LIHEAP outreach, which reaches a small fraction of eligible households in most states.",
                "Weatherization assistance funding, which lowers bills permanently rather than once.",
                "Shutoff protections during extreme heat and cold."
            ]
        case (.energy, .residents):
            return [
                "LIHEAP helps with heating and cooling bills for households that qualify.",
                "The Weatherization Assistance Program can fund insulation and repairs at no cost.",
                "Many utilities offer levelised billing or hardship plans."
            ]
        case (.food, .policymakers):
            return [
                "SNAP outreach and simplified enrolment.",
                "Mobile markets and grocery incentives in areas far from a full-service store.",
                "School meal expansion, including summer provision."
            ]
        case (.food, .residents):
            return [
                "SNAP provides monthly grocery benefits for households that qualify.",
                "Food banks and pantries are searchable through national and local networks.",
                "WIC supports pregnant people, infants, and young children."
            ]
        }
    }

    /// Shown when nothing clears the action threshold.
    static let stableSummary = "No driver in this county stands out against the national distribution. The pressures measured here are around or below what most U.S. counties experience."
}
