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

    var id: String { fips }

    /// "Autauga County, Alabama".
    var displayName: String { "\(county), \(state)" }
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

/// The loaded county file — a searchable list, looked up by FIPS for the
/// comparison features.
struct Dataset: Sendable {
    let counties: [ScoredCounty]

    /// Look up a single county by its FIPS code — used by the rent/energy
    /// comparison and the move engine to find typical costs where someone lives.
    func county(fips: String) -> ScoredCounty? {
        counties.first { $0.record.fips == fips }
    }
}
