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
        "11-1011": "Chief Executive",
        "11-1021": "Operations Manager",
        "11-2021": "Marketing Manager",
        "11-2022": "Sales Manager",
        "11-2032": "Public Relations Manager",
        "11-3012": "Administrative Services Manager",
        "11-3013": "Facilities Manager",
        "11-3021": "IT Manager",
        "11-3031": "Financial Manager",
        "11-3051": "Industrial Production Manager",
        "11-3061": "Purchasing Manager",
        "11-3071": "Transportation, Storage, and Distribution Manager",
        "11-3121": "Human Resources Manager",
        "11-9021": "Construction Manager",
        "11-9032": "Education Administrators, Kindergarten through Secondary",
        "11-9041": "Architectural and Engineering Manager",
        "11-9051": "Food Service Manager",
        "11-9111": "Healthcare Manager",
        "11-9121": "Natural Sciences Manager",
        "11-9141": "Property Manager",
        "11-9151": "Social and Community Service Manager",
        "13-1020": "Buyers and Purchasing Agent",
        "13-1031": "Claims Adjuster",
        "13-1041": "Compliance Officer",
        "13-1051": "Cost Estimator",
        "13-1071": "HR Specialist",
        "13-1075": "Labor Relations Specialist",
        "13-1081": "Logistician",
        "13-1082": "Project Management Specialist",
        "13-1111": "Management Consultant",
        "13-1121": "Meeting, Convention, and Event Planner",
        "13-1131": "Fundraiser",
        "13-1141": "Compensation, Benefits, and Job Analysis Specialist",
        "13-1151": "Training and Development Specialist",
        "13-1161": "Market Research Analyst",
        "13-2011": "Accountant",
        "13-2041": "Credit Analyst",
        "13-2051": "Financial Analyst",
        "13-2052": "Financial Advisor",
        "13-2053": "Insurance Underwriter",
        "13-2061": "Financial Examiner",
        "13-2072": "Loan Officer",
        "13-2082": "Tax Preparer",
        "15-1211": "Systems Analyst",
        "15-1212": "Information Security Analyst",
        "15-1231": "Computer Network Support Specialist",
        "15-1232": "IT Support Specialist",
        "15-1241": "Network Architect",
        "15-1242": "Database Administrator",
        "15-1244": "Network Administrator",
        "15-1251": "Computer Programmer",
        "15-1252": "Software Developer",
        "15-1253": "Software Quality Assurance Analysts and Tester",
        "15-1254": "Web Developer",
        "15-1255": "Web and Digital Interface Designer",
        "15-2011": "Actuary",
        "15-2031": "Operations Research Analyst",
        "15-2051": "Data Scientist",
        "17-1011": "Architect",
        "17-2051": "Civil Engineer",
        "17-2061": "Computer Hardware Engineer",
        "17-2071": "Electrical Engineer",
        "17-2112": "Industrial Engineer",
        "17-2141": "Mechanical Engineer",
        "17-3011": "Architectural and Civil Drafter",
        "17-3022": "Civil Engineering Technologists and Technician",
        "17-3023": "Electrical and Electronic Engineering Technologists and Technician",
        "17-3026": "Industrial Engineering Technologists and Technician",
        "19-1042": "Medical Scientist",
        "19-2031": "Chemist",
        "19-2041": "Environmental Scientists and Specialists, Including Health",
        "19-3033": "Psychologist",
        "19-4021": "Biological Technician",
        "19-5011": "Occupational Health and Safety Specialist",
        "21-1012": "School Counselor",
        "21-1015": "Rehabilitation Counselor",
        "21-1018": "Substance Abuse, Behavioral Disorder, and Mental Health Counselor",
        "21-1021": "Social Worker",
        "21-1022": "Healthcare Social Worker",
        "21-1023": "Mental Health and Substance Abuse Social Worker",
        "21-1092": "Probation Officers and Correctional Treatment Specialist",
        "21-1093": "Social and Human Service Assistant",
        "21-2011": "Clergy",
        "23-1011": "Lawyer",
        "23-2011": "Paralegals and Legal Assistant",
        "25-2011": "Preschool Teacher",
        "25-2021": "Elementary School Teacher",
        "25-2031": "High School Teacher",
        "25-2032": "Career/Technical Education Teachers, Secondary School",
        "25-2052": "Special Ed Teacher",
        "25-2057": "Special Education Teachers, Middle School",
        "25-2058": "Special Education Teachers, Secondary School",
        "25-3021": "Self-Enrichment Teacher",
        "25-3031": "Substitute Teachers, Short-Term",
        "25-3041": "Tutor",
        "25-4022": "Librarian",
        "25-4031": "Library Technician",
        "25-9031": "Instructional Coordinator",
        "25-9045": "Teaching Assistant",
        "27-1024": "Graphic Designer",
        "27-1025": "Interior Designer",
        "27-1026": "Merchandise Displayers and Window Trimmer",
        "27-2012": "Producers and Director",
        "27-2022": "Sports Coach",
        "27-3023": "Journalist",
        "27-3031": "Public Relations Specialist",
        "27-3041": "Editor",
        "27-3043": "Writer",
        "27-4011": "Audio and Video Technician",
        "27-4021": "Photographer",
        "29-1011": "Chiropractor",
        "29-1021": "Dentist",
        "29-1031": "Dietitian",
        "29-1041": "Optometrist",
        "29-1051": "Pharmacist",
        "29-1071": "Physician Assistant",
        "29-1122": "Occupational Therapist",
        "29-1123": "Physical Therapist",
        "29-1126": "Respiratory Therapist",
        "29-1127": "Speech Pathologist",
        "29-1131": "Veterinarian",
        "29-1141": "Registered Nurse",
        "29-1151": "Nurse Anesthetist",
        "29-1171": "Nurse Practitioner",
        "29-1215": "Family Physician",
        "29-1292": "Dental Hygienist",
        "29-2010": "Clinical Laboratory Technologists and Technician",
        "29-2032": "Sonographer",
        "29-2034": "Radiologic Technologist",
        "29-2042": "EMT",
        "29-2043": "Paramedic",
        "29-2052": "Pharmacy Technician",
        "29-2053": "Psychiatric Technician",
        "29-2055": "Surgical Technologist",
        "29-2056": "Veterinary Technologists and Technician",
        "29-2057": "Ophthalmic Medical Technician",
        "29-2061": "Licensed Practical Nurse",
        "29-2072": "Medical Records Specialist",
        "29-2081": "Opticians, Dispensing",
        "31-1120": "Home Health Aide",
        "31-1131": "Nursing Assistant",
        "31-2021": "Physical Therapist Assistant",
        "31-9011": "Massage Therapist",
        "31-9091": "Dental Assistant",
        "31-9092": "Medical Assistant",
        "31-9093": "Medical Equipment Preparer",
        "31-9096": "Veterinary Assistants and Laboratory Animal Caretaker",
        "31-9097": "Phlebotomist",
        "33-1012": "Police and Detective",
        "33-1021": "Firefighting and Prevention Worker",
        "33-1091": "Security Worker",
        "33-2011": "Firefighter",
        "33-3012": "Correctional Officer",
        "33-3021": "Detectives and Criminal Investigator",
        "33-3051": "Police Officer",
        "33-9032": "Security Guard",
        "33-9091": "Crossing Guards and Flagger",
        "33-9092": "Lifeguards, Ski Patrol, and Other Recreational Protective Service Worker",
        "33-9094": "School Bus Monitor",
        "35-1011": "Chef",
        "35-1012": "Food Service Supervisor",
        "35-2011": "Cooks, Fast Food",
        "35-2012": "Cooks, Institution and Cafeteria",
        "35-2014": "Restaurant Cook",
        "35-2015": "Cooks, Short Order",
        "35-2021": "Food Preparation Worker",
        "35-3011": "Bartender",
        "35-3023": "Fast Food and Counter Worker",
        "35-3031": "Server",
        "35-3041": "Food Servers, Nonrestaurant",
        "35-9011": "Dining Room and Cafeteria Attendants and Bartender Helper",
        "35-9021": "Dishwasher",
        "35-9031": "Hosts and Hostesses, Restaurant, Lounge, and Coffee Shop",
        "37-1011": "Housekeeping and Janitorial Worker",
        "37-1012": "Landscaping, Lawn Service, and Groundskeeping Worker",
        "37-2011": "Janitor",
        "37-2012": "Maids and Housekeeping Cleaner",
        "37-2021": "Pest Control Worker",
        "37-3011": "Landscaper",
        "39-1022": "Personal Service Worker",
        "39-2021": "Animal Caretaker",
        "39-3031": "Ushers, Lobby Attendants, and Ticket Taker",
        "39-3091": "Amusement and Recreation Attendant",
        "39-5012": "Hairdresser",
        "39-5092": "Manicurists and Pedicurist",
        "39-5094": "Skincare Specialist",
        "39-9011": "Childcare Worker",
        "39-9031": "Fitness Trainer",
        "39-9032": "Recreation Worker",
        "39-9041": "Residential Advisor",
        "41-1011": "Retail Supervisor",
        "41-1012": "Non-Retail Sales Worker",
        "41-2011": "Cashier",
        "41-2021": "Counter and Rental Clerk",
        "41-2022": "Parts Salesperson",
        "41-2031": "Retail Salesperson",
        "41-3011": "Advertising Sales Agent",
        "41-3021": "Insurance Agent",
        "41-3031": "Securities, Commodities, and Financial Services Sales Agent",
        "41-4011": "Sales Representatives, Wholesale and Manufacturing, Technical and Scientific Product",
        "41-4012": "Sales Representative",
        "41-9022": "Real Estate Agent",
        "41-9041": "Telemarketer",
        "43-1011": "Office and Administrative Support Worker",
        "43-3011": "Bill and Account Collector",
        "43-3021": "Billing and Posting Clerk",
        "43-3031": "Bookkeeper",
        "43-3051": "Payroll and Timekeeping Clerk",
        "43-3071": "Teller",
        "43-4031": "Court, Municipal, and License Clerk",
        "43-4051": "Customer Service Rep",
        "43-4061": "Eligibility Interviewers, Government Program",
        "43-4071": "File Clerk",
        "43-4081": "Hotel, Motel, and Resort Desk Clerk",
        "43-4121": "Library Assistants, Clerical",
        "43-4131": "Loan Interviewers and Clerk",
        "43-4151": "Order Clerk",
        "43-4171": "Receptionist",
        "43-4181": "Reservation and Transportation Ticket Agents and Travel Clerk",
        "43-5011": "Cargo and Freight Agent",
        "43-5021": "Couriers and Messenger",
        "43-5031": "Public Safety Telecommunicator",
        "43-5051": "Postal Service Clerk",
        "43-5052": "Postal Service Mail Carrier",
        "43-5053": "Postal Service Mail Sorters, Processors, and Processing Machine Operator",
        "43-5061": "Production, Planning, and Expediting Clerk",
        "43-5071": "Shipping, Receiving, and Inventory Clerk",
        "43-6011": "Executive Secretaries and Executive Administrative Assistant",
        "43-6012": "Legal Secretaries and Administrative Assistant",
        "43-6013": "Medical Secretaries and Administrative Assistant",
        "43-6014": "Admin Assistant",
        "43-9021": "Data Entry Keyer",
        "43-9041": "Insurance Claims and Policy Processing Clerk",
        "43-9061": "Office Clerk",
        "45-2092": "Farmworkers and Laborers, Crop, Nursery, and Greenhouse",
        "47-1011": "Construction Supervisor",
        "47-2031": "Carpenter",
        "47-2051": "Cement Masons and Concrete Finisher",
        "47-2061": "Construction Laborer",
        "47-2073": "Equipment Operator",
        "47-2081": "Drywall and Ceiling Tile Installer",
        "47-2111": "Electrician",
        "47-2141": "Painter",
        "47-2152": "Plumber",
        "47-2181": "Roofer",
        "47-2211": "Sheet Metal Worker",
        "47-4011": "Construction and Building Inspector",
        "47-4051": "Highway Maintenance Worker",
        "49-1011": "Mechanics, Installers, and Repairer",
        "49-2011": "Computer, Automated Teller, and Office Machine Repairer",
        "49-2098": "Security and Fire Alarm Systems Installer",
        "49-3011": "Aircraft Mechanics and Service Technician",
        "49-3021": "Automotive Body and Related Repairer",
        "49-3023": "Auto Mechanic",
        "49-3031": "Diesel Mechanic",
        "49-3093": "Tire Repairers and Changer",
        "49-9021": "HVAC Technician",
        "49-9041": "Industrial Machinery Mechanic",
        "49-9051": "Electrical Power-Line Installers and Repairer",
        "49-9052": "Telecommunications Line Installers and Repairer",
        "49-9062": "Medical Equipment Repairer",
        "49-9071": "Maintenance Worker",
        "51-1011": "Production and Operating Worker",
        "51-3011": "Baker",
        "51-3021": "Butchers and Meat Cutter",
        "51-3022": "Meat, Poultry, and Fish Cutters and Trimmer",
        "51-3023": "Slaughterers and Meat Packer",
        "51-3092": "Food Batchmaker",
        "51-4031": "Cutting, Punching, and Press Machine Setters, Operators, and Tenders, Metal and Plastic",
        "51-4033": "Grinding, Lapping, Polishing, and Buffing Machine Tool Setters, Operators, and Tenders, Metal and Plastic",
        "51-4041": "Machinist",
        "51-4072": "Molding, Coremaking, and Casting Machine Setters, Operators, and Tenders, Metal and Plastic",
        "51-4081": "Multiple Machine Tool Setters, Operators, and Tenders, Metal and Plastic",
        "51-4121": "Welder",
        "51-5112": "Printing Press Operator",
        "51-6011": "Laundry and Dry-Cleaning Worker",
        "51-6031": "Sewing Machine Operator",
        "51-7011": "Cabinetmakers and Bench Carpenter",
        "51-8031": "Water and Wastewater Treatment Plant and System Operator",
        "51-9011": "Chemical Equipment Operators and Tender",
        "51-9023": "Mixing and Blending Machine Setters, Operators, and Tender",
        "51-9061": "Inspectors, Testers, Sorters, Samplers, and Weigher",
        "51-9111": "Packaging and Filling Machine Operators and Tender",
        "51-9124": "Coating, Painting, and Spraying Machine Setters, Operators, and Tender",
        "51-9161": "Computer Numerically Controlled Tool Operator",
        "51-9196": "Paper Goods Machine Setters, Operators, and Tender",
        "53-3031": "Driver/Sales Worker",
        "53-3032": "Truck Driver",
        "53-3033": "Delivery Driver",
        "53-3051": "Bus Drivers, School",
        "53-3052": "Bus Drivers, Transit and Intercity",
        "53-3053": "Shuttle Drivers and Chauffeur",
        "53-6021": "Parking Attendant",
        "53-6031": "Automotive and Watercraft Service Attendant",
        "53-7051": "Industrial Truck and Tractor Operator",
        "53-7061": "Cleaners of Vehicles and Equipment",
        "53-7062": "Warehouse Worker",
        "53-7064": "Packers and Packagers, Hand",
        "53-7065": "Stockers and Order Filler",
        "53-7081": "Refuse and Recyclable Material Collector",
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
