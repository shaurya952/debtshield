import Foundation

/// One cell in the state grid.
///
/// ## Why a tile grid and not a geographic map
///
/// A true county map needs a centroid or boundary for each of 3,142 counties.
/// `real_county_data.csv` carries FIPS codes but no coordinates, and there is no
/// bundled boundary file — so placing counties geographically would mean
/// inventing positions, which would be wrong in a way users could not detect.
///
/// The Streamlit version sidestepped this with 18 hardcoded centroids, which
/// meant its map silently omitted 3,124 counties.
///
/// A tile grid needs only a schematic layout: each state is one equal-sized
/// square in roughly its national position. It claims no cartographic
/// precision, gives small states the same visual weight as large ones (Rhode
/// Island is as readable as Texas), and every tile is a real tap target with a
/// full VoiceOver label — none of which is true of a pin map.
///
/// ## Adding a real map later
///
/// Drop a `fips,latitude,longitude` file into `Resources` (Census TIGER
/// publishes county centroids), extend `CountyRecord` with the coordinate, and
/// a MapKit view can render alongside this one. Nothing here blocks that.
struct StateTile: Identifiable, Sendable {
    let abbreviation: String
    let name: String
    /// 0 = north.
    let row: Int
    /// 0 = west.
    let column: Int

    var id: String { abbreviation }
}

enum StateGrid {

    static let columnCount = 11
    static let rowCount = 8

    /// Schematic layout of the 50 states plus the District of Columbia.
    ///
    /// Positions approximate each state's place in the country; they are not
    /// projections. Alaska and Hawaii sit at the west edge rather than in
    /// insets.
    static let tiles: [StateTile] = [
        .init(abbreviation: "AK", name: "Alaska", row: 0, column: 0),
        .init(abbreviation: "ME", name: "Maine", row: 0, column: 10),

        .init(abbreviation: "VT", name: "Vermont", row: 1, column: 9),
        .init(abbreviation: "NH", name: "New Hampshire", row: 1, column: 10),

        .init(abbreviation: "WA", name: "Washington", row: 2, column: 0),
        .init(abbreviation: "ID", name: "Idaho", row: 2, column: 1),
        .init(abbreviation: "MT", name: "Montana", row: 2, column: 2),
        .init(abbreviation: "ND", name: "North Dakota", row: 2, column: 3),
        .init(abbreviation: "MN", name: "Minnesota", row: 2, column: 4),
        .init(abbreviation: "WI", name: "Wisconsin", row: 2, column: 5),
        .init(abbreviation: "MI", name: "Michigan", row: 2, column: 6),
        .init(abbreviation: "NY", name: "New York", row: 2, column: 8),
        .init(abbreviation: "MA", name: "Massachusetts", row: 2, column: 9),
        .init(abbreviation: "RI", name: "Rhode Island", row: 2, column: 10),

        .init(abbreviation: "OR", name: "Oregon", row: 3, column: 0),
        .init(abbreviation: "NV", name: "Nevada", row: 3, column: 1),
        .init(abbreviation: "WY", name: "Wyoming", row: 3, column: 2),
        .init(abbreviation: "SD", name: "South Dakota", row: 3, column: 3),
        .init(abbreviation: "IA", name: "Iowa", row: 3, column: 4),
        .init(abbreviation: "IL", name: "Illinois", row: 3, column: 5),
        .init(abbreviation: "IN", name: "Indiana", row: 3, column: 6),
        .init(abbreviation: "OH", name: "Ohio", row: 3, column: 7),
        .init(abbreviation: "PA", name: "Pennsylvania", row: 3, column: 8),
        .init(abbreviation: "NJ", name: "New Jersey", row: 3, column: 9),
        .init(abbreviation: "CT", name: "Connecticut", row: 3, column: 10),

        .init(abbreviation: "CA", name: "California", row: 4, column: 0),
        .init(abbreviation: "UT", name: "Utah", row: 4, column: 1),
        .init(abbreviation: "CO", name: "Colorado", row: 4, column: 2),
        .init(abbreviation: "NE", name: "Nebraska", row: 4, column: 3),
        .init(abbreviation: "MO", name: "Missouri", row: 4, column: 4),
        .init(abbreviation: "KY", name: "Kentucky", row: 4, column: 5),
        .init(abbreviation: "WV", name: "West Virginia", row: 4, column: 6),
        .init(abbreviation: "VA", name: "Virginia", row: 4, column: 7),
        .init(abbreviation: "MD", name: "Maryland", row: 4, column: 8),
        .init(abbreviation: "DE", name: "Delaware", row: 4, column: 9),

        .init(abbreviation: "AZ", name: "Arizona", row: 5, column: 1),
        .init(abbreviation: "NM", name: "New Mexico", row: 5, column: 2),
        .init(abbreviation: "KS", name: "Kansas", row: 5, column: 3),
        .init(abbreviation: "AR", name: "Arkansas", row: 5, column: 4),
        .init(abbreviation: "TN", name: "Tennessee", row: 5, column: 5),
        .init(abbreviation: "NC", name: "North Carolina", row: 5, column: 6),
        .init(abbreviation: "SC", name: "South Carolina", row: 5, column: 7),
        .init(abbreviation: "DC", name: "District of Columbia", row: 5, column: 8),

        .init(abbreviation: "OK", name: "Oklahoma", row: 6, column: 3),
        .init(abbreviation: "LA", name: "Louisiana", row: 6, column: 4),
        .init(abbreviation: "MS", name: "Mississippi", row: 6, column: 5),
        .init(abbreviation: "AL", name: "Alabama", row: 6, column: 6),
        .init(abbreviation: "GA", name: "Georgia", row: 6, column: 7),

        .init(abbreviation: "HI", name: "Hawaii", row: 7, column: 0),
        .init(abbreviation: "TX", name: "Texas", row: 7, column: 3),
        .init(abbreviation: "FL", name: "Florida", row: 7, column: 7)
    ]

    static let tilesByStateName: [String: StateTile] = Dictionary(
        uniqueKeysWithValues: tiles.map { ($0.name, $0) }
    )
}

// MARK: - Metric

/// What the grid is shaded by.
enum StateMetric: String, CaseIterable, Identifiable, Sendable {
    case averageIndex
    case elevatedShare

    var id: String { rawValue }

    var title: String {
        switch self {
        case .averageIndex: return "Average index"
        case .elevatedShare: return "% at risk"
        }
    }

    var description: String {
        switch self {
        case .averageIndex:
            return "The mean Financial Distress Index across the state's counties."
        case .elevatedShare:
            return "Share of the state's counties at medium or high risk."
        }
    }

    func value(_ summary: StateRiskSummary) -> Double {
        switch self {
        case .averageIndex: return summary.averageIndex
        case .elevatedShare: return summary.elevatedShare
        }
    }

    func format(_ value: Double) -> String {
        switch self {
        case .averageIndex: return value.scoreText
        case .elevatedShare: return "\(Int(value.rounded()))%"
        }
    }
}

// MARK: - Summary

/// Aggregate risk for one state.
struct StateRiskSummary: Identifiable, Sendable {
    let state: String
    let abbreviation: String
    let scoredCount: Int
    let unscoredCount: Int
    let averageIndex: Double
    let lowCount: Int
    let mediumCount: Int
    let highCount: Int

    var id: String { state }

    var totalCount: Int { scoredCount + unscoredCount }

    /// Percentage of scored counties at medium or high risk.
    var elevatedShare: Double {
        guard scoredCount > 0 else { return 0 }
        return Double(mediumCount + highCount) / Double(scoredCount) * 100
    }

    /// Full sentence for VoiceOver — a tile reads as information, not a letter
    /// pair.
    func accessibilityDescription(metric: StateMetric) -> String {
        var parts = ["\(state). \(metric.title) \(metric.format(metric.value(self)))."]
        parts.append("\(scoredCount) counties scored.")
        if mediumCount + highCount > 0 {
            parts.append("\(mediumCount) medium risk, \(highCount) high risk.")
        } else {
            parts.append("All low risk.")
        }
        return parts.joined(separator: " ")
    }
}

extension Dataset {

    /// One summary per state, ordered by the given metric, highest first.
    func stateSummaries(orderedBy metric: StateMetric = .averageIndex) -> [StateRiskSummary] {
        var grouped: [String: [ScoredCounty]] = [:]
        for county in counties {
            grouped[county.state, default: []].append(county)
        }

        return grouped.map { state, members in
            let scored = members.filter(\.isScored)
            let indices = scored.compactMap(\.index)
            return StateRiskSummary(
                state: state,
                // A state with no tile still gets a summary and appears in the
                // list — it simply cannot be drawn on the grid.
                abbreviation: StateGrid.tilesByStateName[state]?.abbreviation ?? "—",
                scoredCount: scored.count,
                unscoredCount: members.count - scored.count,
                averageIndex: indices.isEmpty ? 0 : indices.reduce(0, +) / Double(indices.count),
                lowCount: members.filter { $0.riskLevel == .low }.count,
                mediumCount: members.filter { $0.riskLevel == .medium }.count,
                highCount: members.filter { $0.riskLevel == .high }.count
            )
        }
        .sorted { metric.value($0) > metric.value($1) }
    }
}

// MARK: - Shading

/// Splits states into five bands for shading.
///
/// Bands are relative to the other states, not absolute. Every state's average
/// index falls in the "Low" risk band (the highest is Louisiana at 32.7, below
/// the 35 threshold), so shading by risk level would paint the entire map one
/// colour and say nothing. Ranking against the other states is what makes the
/// map informative — and the legend says so explicitly, because "darkest" here
/// means "highest of the 51", not "high risk".
struct StateShading: Sendable {
    /// Ascending band boundaries; `bands.count` is always 5.
    let thresholds: [Double]

    init(values: [Double]) {
        let sorted = values.sorted()
        guard !sorted.isEmpty else {
            thresholds = [0, 0, 0, 0]
            return
        }
        func quantile(_ q: Double) -> Double {
            let position = q * Double(sorted.count - 1)
            let lower = Int(position.rounded(.down))
            let upper = min(lower + 1, sorted.count - 1)
            let fraction = position - Double(lower)
            return sorted[lower] + (sorted[upper] - sorted[lower]) * fraction
        }
        thresholds = [quantile(0.2), quantile(0.4), quantile(0.6), quantile(0.8)]
    }

    /// 0 (lowest fifth) to 4 (highest fifth).
    func band(for value: Double) -> Int {
        for (index, threshold) in thresholds.enumerated() where value <= threshold {
            return index
        }
        return 4
    }

    static let bandCount = 5

    static func bandLabel(_ band: Int) -> String {
        switch band {
        case 0: return "Lowest fifth"
        case 1: return "Second fifth"
        case 2: return "Middle fifth"
        case 3: return "Fourth fifth"
        default: return "Highest fifth"
        }
    }
}
