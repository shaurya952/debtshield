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
    /// occ code → (full state name → number of people employed in that job there,
    /// BLS OEWS. Lets the UI warn when a state's median pay for a job rests on very
    /// few actual jobs — a wage shown where the work barely exists.
    let employmentByOccupationState: [String: [String: Int]]
    /// The occupations we carry, in display order.
    let occupations: [Occupation]

    /// How many people hold this job in a state, or `nil` if not reported.
    func employment(occupation code: String, state: String) -> Int? {
        employmentByOccupationState[code]?[state]
    }

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
        "11-1011": "Chief Executive", "11-1021": "Operations Manager", "11-2021": "Marketing Manager",
        "11-2022": "Sales Manager", "11-3021": "IT Manager", "11-3031": "Financial Manager",
        "11-9021": "Construction Manager", "11-9111": "Healthcare Manager", "11-9141": "Property Manager",
        "13-1031": "Claims Adjuster", "13-1071": "HR Specialist", "13-1111": "Management Consultant",
        "13-1161": "Market Research Analyst", "13-2011": "Accountant", "13-2051": "Financial Analyst",
        "13-2052": "Financial Advisor", "13-2072": "Loan Officer", "15-1211": "Systems Analyst",
        "15-1232": "IT Support Specialist", "15-1241": "Network Architect", "15-1244": "Network Administrator",
        "15-1252": "Software Developer", "15-1254": "Web Developer", "15-2011": "Actuary",
        "15-2051": "Data Scientist", "17-1011": "Architect", "17-2051": "Civil Engineer",
        "17-2071": "Electrical Engineer", "17-2112": "Industrial Engineer", "17-2141": "Mechanical Engineer",
        "19-1042": "Medical Scientist", "19-2031": "Chemist", "19-3033": "Psychologist",
        "21-1012": "School Counselor", "21-1021": "Social Worker", "21-2011": "Clergy",
        "23-1011": "Lawyer", "25-2011": "Preschool Teacher", "25-2021": "Elementary School Teacher",
        "25-2031": "High School Teacher", "25-2052": "Special Ed Teacher", "25-4022": "Librarian",
        "25-9045": "Teaching Assistant", "27-1024": "Graphic Designer", "27-1025": "Interior Designer",
        "27-2022": "Sports Coach", "27-3023": "Journalist", "27-3043": "Writer",
        "27-4021": "Photographer", "29-1011": "Chiropractor", "29-1021": "Dentist",
        "29-1031": "Dietitian", "29-1041": "Optometrist", "29-1051": "Pharmacist",
        "29-1071": "Physician Assistant", "29-1122": "Occupational Therapist", "29-1123": "Physical Therapist",
        "29-1126": "Respiratory Therapist", "29-1127": "Speech Pathologist", "29-1131": "Veterinarian",
        "29-1141": "Registered Nurse", "29-1151": "Nurse Anesthetist", "29-1171": "Nurse Practitioner",
        "29-1215": "Family Physician", "29-1292": "Dental Hygienist", "29-2032": "Sonographer",
        "29-2034": "Radiologic Technologist", "29-2042": "EMT", "29-2052": "Pharmacy Technician",
        "29-2055": "Surgical Technologist", "29-2061": "Licensed Practical Nurse", "31-1120": "Home Health Aide",
        "31-1131": "Nursing Assistant", "31-9091": "Dental Assistant", "31-9092": "Medical Assistant",
        "33-2011": "Firefighter", "33-3012": "Correctional Officer", "33-3051": "Police Officer",
        "33-9032": "Security Guard", "35-1011": "Chef", "35-1012": "Food Service Supervisor",
        "35-2014": "Restaurant Cook", "35-3031": "Server", "37-2011": "Janitor",
        "37-3011": "Landscaper", "39-5012": "Hairdresser", "39-9011": "Childcare Worker",
        "39-9031": "Fitness Trainer", "39-9032": "Recreation Worker", "41-1011": "Retail Supervisor",
        "41-2011": "Cashier", "41-2031": "Retail Salesperson", "41-3021": "Insurance Agent",
        "41-4012": "Sales Representative", "41-9022": "Real Estate Agent", "43-3031": "Bookkeeper",
        "43-4051": "Customer Service Rep", "43-4171": "Receptionist", "43-6014": "Admin Assistant",
        "43-9061": "Office Clerk", "47-1011": "Construction Supervisor", "47-2031": "Carpenter",
        "47-2061": "Construction Laborer", "47-2073": "Equipment Operator", "47-2111": "Electrician",
        "47-2141": "Painter", "47-2152": "Plumber", "49-3023": "Auto Mechanic",
        "49-3031": "Diesel Mechanic", "49-9021": "HVAC Technician", "49-9071": "Maintenance Worker",
        "51-3011": "Baker", "51-4121": "Welder", "53-3032": "Truck Driver",
        "53-3033": "Delivery Driver", "53-7062": "Warehouse Worker"
    ]

    static func load(bundle: Bundle = .main) -> OccupationWages {
        var map: [String: [String: Double]] = [:]
        var emp: [String: [String: Int]] = [:]
        for row in rows(of: "occupation_wages", bundle: bundle) {
            guard row.count >= 3 else { continue }
            let code = row[0].trimmingCharacters(in: .whitespaces)
            let state = row[1].trimmingCharacters(in: .whitespaces)
            guard displayNames[code] != nil, !state.isEmpty,
                  let annual = Double(row[2].trimmingCharacters(in: .whitespaces)), annual > 0
            else { continue }
            map[code, default: [:]][state] = annual
            // Optional 4th column: number employed in that job in that state.
            if row.count >= 4, let count = Int(row[3].trimmingCharacters(in: .whitespaces)) {
                emp[code, default: [:]][state] = count
            }
        }
        let occs = displayNames
            .filter { map[$0.key] != nil }
            .map { OccupationWages.Occupation(code: $0.key, name: $0.value) }
            .sorted { $0.name < $1.name }
        return OccupationWages(annualByOccupationState: map,
                               employmentByOccupationState: emp, occupations: occs)
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
        employmentByOccupationState: [
            "29-1141": ["Massachusetts": 89000, "Tennessee": 66000, "California": 324000, "Mississippi": 29000],
            "15-1252": ["Massachusetts": 46000, "Tennessee": 21000, "California": 189000]
        ],
        occupations: [
            .init(code: "29-1141", name: "Registered Nurse"),
            .init(code: "15-1252", name: "Software Developer")
        ])
}
#endif
