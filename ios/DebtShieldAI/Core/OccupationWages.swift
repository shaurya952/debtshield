import Foundation

/// Occupation pay by state — the "same job, new place" layer.
///
/// The same career pays very differently by state (a nurse in Massachusetts vs.
/// Tennessee), and the app measures money against *local* costs. So when a person
/// picks their occupation, the ranking uses that job's **local** typical pay in
/// each state instead of one flat number — answering "where would my career go
/// furthest?", not just "where's cheap."
///
/// Source: BLS Occupational Employment & Wage Statistics (OEWS) May 2023, state
/// files — real published annual **median** wages. Bundled on the device.
struct OccupationWages: Sendable, Equatable {

    struct Occupation: Identifiable, Sendable, Equatable, Hashable {
        let code: String       // SOC code, e.g. "29-1141"
        let name: String       // friendly display name
        var id: String { code }
    }

    /// occ code → (full state name → annual **gross** median wage).
    let annualByOccupationState: [String: [String: Double]]
    /// The occupations we carry, in display order.
    let occupations: [Occupation]

    /// Gross annual wage is not take-home. The app works in monthly take-home, so
    /// a single documented estimate turns gross pay into a comparable figure. It's
    /// a national-ish blend of federal + FICA + typical state tax — a **named
    /// heuristic** (see THRESHOLD_REGISTRY), clearly labelled "estimated" in the
    /// UI, never presented as an exact paycheck.
    static let takeHomeRatio = 0.78

    /// Estimated monthly take-home for an occupation in one state, or `nil` if the
    /// job isn't reported there (then that state is simply left out — not guessed).
    func monthlyTakeHome(occupation code: String, state: String) -> Double? {
        guard let annual = annualByOccupationState[code]?[state] else { return nil }
        return annual / 12 * Self.takeHomeRatio
    }

    /// Every state's estimated monthly take-home for an occupation — the per-state
    /// income the ranking uses.
    func monthlyTakeHomeByState(occupation code: String) -> [String: Double] {
        (annualByOccupationState[code] ?? [:]).mapValues { $0 / 12 * Self.takeHomeRatio }
    }
}

// MARK: - Loading

enum OccupationWagesLoader {

    /// The curated, relatable occupations we surface, SOC code → display name.
    /// Only these are read from the bundled file; the file may hold more.
    static let displayNames: [String: String] = [
        "11-1021": "Operations Manager", "13-2011": "Accountant", "15-1252": "Software Developer",
        "15-2051": "Data Scientist", "17-2051": "Civil Engineer", "23-1011": "Lawyer",
        "25-2021": "Elementary School Teacher", "25-2031": "High School Teacher",
        "29-1021": "Dentist", "29-1051": "Pharmacist", "29-1123": "Physical Therapist",
        "29-1131": "Veterinarian", "29-1141": "Registered Nurse", "29-1215": "Family Physician",
        "29-2061": "Licensed Practical Nurse", "31-1131": "Nursing Assistant",
        "33-3051": "Police Officer", "35-2014": "Restaurant Cook", "41-2031": "Retail Salesperson",
        "43-4051": "Customer Service Rep", "47-2031": "Carpenter", "47-2111": "Electrician",
        "47-2152": "Plumber", "53-3032": "Truck Driver"
    ]

    static func load(bundle: Bundle = .main) -> OccupationWages {
        var map: [String: [String: Double]] = [:]
        for row in rows(of: "occupation_wages", bundle: bundle) {
            guard row.count >= 3 else { continue }
            let code = row[0].trimmingCharacters(in: .whitespaces)
            let state = row[1].trimmingCharacters(in: .whitespaces)
            guard displayNames[code] != nil, !state.isEmpty,
                  let annual = Double(row[2].trimmingCharacters(in: .whitespaces)), annual > 0
            else { continue }
            map[code, default: [:]][state] = annual
        }
        let occs = displayNames
            .filter { map[$0.key] != nil }
            .map { OccupationWages.Occupation(code: $0.key, name: $0.value) }
            .sorted { $0.name < $1.name }
        return OccupationWages(annualByOccupationState: map, occupations: occs)
    }

    private static func rows(of resource: String, bundle: Bundle) -> [[String]] {
        guard let url = bundle.url(forResource: resource, withExtension: "csv"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return text
            .components(separatedBy: .newlines)
            .dropFirst()                       // header
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { $0.components(separatedBy: ",") }
    }
}

#if DEBUG
extension OccupationWages {
    /// Small fixed sample for previews/tests, so they don't depend on the bundle.
    static let previewSample = OccupationWages(
        annualByOccupationState: [
            "29-1141": ["Massachusetts": 99730, "Tennessee": 76200, "California": 133990, "Mississippi": 69370],
            "15-1252": ["Massachusetts": 137130, "Tennessee": 110660, "California": 168660]
        ],
        occupations: [
            .init(code: "29-1141", name: "Registered Nurse"),
            .init(code: "15-1252", name: "Software Developer")
        ])
}
#endif
