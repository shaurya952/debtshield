import Foundation

// MARK: - County record

/// One county from `real_county_data.csv`, kept only as the comparison layer
/// behind the personal app — its typical rent and income, used by the rent/
/// energy comparison and the "could you afford a move?" engine.
///
/// (v1 scored counties for a "Financial Distress Index"; that engine is gone.
/// Only the raw figures the personal features compare against remain.)
struct CountyRecord: Identifiable, Hashable, Sendable {
    let fips: String
    let state: String
    let county: String

    /// The Census publishes no median household income or rent for the very
    /// smallest counties, so both are optional; a county missing them is kept
    /// and simply offers no comparison rather than being dropped.
    var medianHouseholdIncome: Double?
    var medianGrossRent: Double?

    /// For metro areas, whose own title already carries the state(s) (e.g.
    /// "Austin-Round Rock-Georgetown, TX"), so the display name isn't doubled up.
    var displayOverride: String? = nil

    var id: String { fips }

    /// "Autauga County, Alabama" — or the metro's own title when set.
    var displayName: String { displayOverride ?? "\(county), \(state)" }

    /// True for the rolled-up metro-area pseudo-records (FIPS starts with "M").
    var isMetro: Bool { fips.hasPrefix("M") }
}

// MARK: - County

/// A county in the app. Named `ScoredCounty` for historical continuity across
/// the codebase; it no longer carries a score — just the record and a few
/// display helpers.
struct ScoredCounty: Identifiable, Hashable, Sendable {
    let record: CountyRecord

    var id: String { record.fips }
    var displayName: String { record.displayName }
    var county: String { record.county }
    var state: String { record.state }
}

// MARK: - Dataset

/// The loaded place data — counties, plus **metro areas** rolled up from them.
///
/// Metros are the honest primary unit for "where would my money go furthest":
/// ranking ~3,000 counties surfaces depopulating rural counties whose rent is low
/// only because demand is, and whose ACS estimates carry margins wider than the
/// gaps being ranked. Metro areas (~390 population-weighted Census CBSAs) are how
/// people actually think about moving, so they lead; counties stay as a drill-down.
struct Dataset: Sendable {
    let counties: [ScoredCounty]
    /// Metro areas, each stored as a `ScoredCounty` whose FIPS is `"M" + CBSA code`
    /// so it never collides with a real county FIPS.
    let metros: [ScoredCounty]

    init(counties: [ScoredCounty], metros: [ScoredCounty] = []) {
        self.counties = counties
        self.metros = metros
    }

    /// Look up a single place (county *or* metro) by its FIPS code — used by the
    /// rent comparison and the move engine to find typical costs for a place.
    func county(fips: String) -> ScoredCounty? {
        counties.first { $0.record.fips == fips } ?? metros.first { $0.record.fips == fips }
    }
}
