import XCTest
@testable import DebtShieldAI

/// The deterministic Ask engine. It must compute from the entered numbers only,
/// stay deterministic, decline advice, and route the new money questions.
final class PersonalChatEngineTests: XCTestCase {

    private func answer(_ q: String, _ plan: MoneyPlan) -> ChatAnswer {
        PersonalChatEngine.respond(to: q, plan: plan)
    }

    // MARK: - New intents

    func testCushionGivesTheThreeToSixMonthGuideline() {
        let a = answer("how's my cushion?", .sampleOkay)
        XCTAssertTrue(a.text.contains("3 to 6 months of essentials"))
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.contains("month")) // build-time estimate present (surplus > 0)
    }

    func testSavingsRateReportsShareOfIncome() {
        let a = answer("how much do I keep each month?", .sampleOkay)
        XCTAssertTrue(a.text.contains("of your income"))
        XCTAssertTrue(a.text.lowercased().contains("keep"))
    }

    func testDebtBurdenUsesGuidelines() {
        let a = answer("how much of my income goes to debt?", .sampleTight) // debt 100 / 3000 ≈ 3%
        XCTAssertTrue(a.text.contains("of your income"))
        XCTAssertTrue(a.text.contains("20%"))
    }

    func testDebtBurdenWhenNoDebt() {
        let noDebt = MoneyPlan(monthlyIncome: 4000, housing: 1200, food: 350, energy: 160)
        let a = answer("how much goes to debt?", noDebt)
        XCTAssertTrue(a.text.lowercased().contains("no debt") || a.text.lowercased().contains("any debt"))
    }

    func testAnnualProjection() {
        let a = answer("how much over a year?", .sampleOkay)
        XCTAssertTrue(a.text.contains("over 12 months"))
    }

    func testPerCategoryAnswerForNewCategory() {
        let plan = MoneyPlan(monthlyIncome: 5000, housing: 1400, transportation: 450, debtPayments: 200)
        let a = answer("how much do I spend on transportation?", plan)
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.contains("450"))
        XCTAssertTrue(a.text.lowercased().contains("transportation"))
        XCTAssertEqual(a.provenance, "Your numbers")
    }

    func testUnmatchedQuestionDeclinesInsteadOfGuessing() {
        // A question the engine can't answer must decline honestly (and offer
        // what it *can* do) rather than return a random figure.
        let a = answer("what's the weather like tomorrow?", .sampleOkay)
        XCTAssertTrue(a.isDecline)
        XCTAssertFalse(a.followUps.isEmpty)
        XCTAssertFalse(a.text.contains("$")) // a decline never invents a number
    }

    // MARK: - Places (relocation) answers

    /// A tiny world with two metros so the place answer has something to rank.
    private func placesWorld() -> (Dataset, Benchmarks) {
        func place(_ fips: String, _ state: String, _ name: String, rent: Double) -> ScoredCounty {
            ScoredCounty(record: CountyRecord(fips: fips, state: state, county: name,
                                              medianHouseholdIncome: 60000, medianGrossRent: rent,
                                              displayOverride: name))
        }
        let dataset = Dataset(
            counties: [
                place("01", "Lowland", "Aville", rent: 700),   // cheapest → Lowland ranks best
                place("02", "Lowland", "Bville", rent: 900),
                place("10", "Highland", "Cville", rent: 2400)
            ],
            metros: [
                place("M1", "Lowland",  "Cheapville, AL", rent: 700),   // most room
                place("M2", "Highland", "Priceyburg, CA", rent: 2600)   // least room
            ])
        let bm = Benchmarks(
            energy: EnergyBenchmark(byState: ["Lowland": 150, "Highland": 150]),
            food: FoodBenchmark(bands: [.init(low: 0, high: nil, annual: 6000)]),
            nationalRent: 1300, nationalEnergy: 150, nationalFood: 500,
            nationalTransportation: 800, nationalPersonal: 300,
            nationalUtilitiesAddon: 100, nationalHomeUpkeep: 200)
        return (dataset, bm)
    }

    func testWhereMoneyGoesFurthestRanksRealPlaces() {
        let (data, bm) = placesWorld()
        let plan = MoneyPlan(monthlyIncome: 5000, food: 400, energy: 150)
        let a = PersonalChatEngine.respond(to: "where would my money go furthest?",
                                           plan: plan, benchmarks: bm, dataset: data)
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.contains("Cheapville, AL"), "should name the top metro")
        XCTAssertTrue(a.text.lowercased().contains("perspective"), "must stay perspective, not a nudge")
        XCTAssertFalse(a.followUps.isEmpty)
    }

    func testAskingForStatesRanksStatesNotFinancials() {
        let (data, bm) = placesWorld()
        let plan = MoneyPlan(monthlyIncome: 5000, food: 400, energy: 150)
        let a = PersonalChatEngine.respond(to: "which states should I move to?",
                                           plan: plan, benchmarks: bm, dataset: data)
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.contains("states"), "should answer at the STATE level")
        XCTAssertTrue(a.text.contains("Lowland"), "names the best state")
        XCTAssertFalse(a.text.contains("Cheapville"), "shouldn't fall back to metros")
    }

    func testAskingForCountiesRanksCounties() {
        let (data, bm) = placesWorld()
        let plan = MoneyPlan(monthlyIncome: 5000, food: 400, energy: 150)
        let a = PersonalChatEngine.respond(to: "best counties for my money?",
                                           plan: plan, benchmarks: bm, dataset: data)
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.contains("counties"))
        XCTAssertTrue(a.text.contains("Aville"), "names the cheapest county")
    }

    func testElectricityQuestionNotHijackedByPlaces() {
        // "electricity" contains the substring "city" — must NOT trigger a place
        // answer. It should stay a money answer, never the relocation ranking.
        let plan = MoneyPlan(monthlyIncome: 5000, housing: 1200, energy: 220)
        let a = answer("how much do I spend on electricity?", plan)
        XCTAssertFalse(a.text.contains("would leave you the most room"))
    }

    func testMoveQuestionWithoutDataPointsToPlacesTab() {
        // Relocation intent but no dataset wired → point to Places, don't guess.
        let a = PersonalChatEngine.respond(to: "should I move somewhere cheaper?", plan: .sampleOkay)
        XCTAssertTrue(a.isDecline)
        XCTAssertTrue(a.text.contains("Places"))
        XCTAssertFalse(a.text.contains("$")) // a decline never invents a figure
    }

    // MARK: - Robustness: no confident wrong answers; common questions handled

    func testOffTopicButMoneyish_wordsStillDecline() {
        // "what should I do" used to trigger the money "fastest fix" answer — a
        // confident wrong reply. Now an off-topic ask declines instead of guessing.
        let a = answer("what should I do this weekend?", .sampleOkay)
        XCTAssertTrue(a.isDecline)
        XCTAssertFalse(a.text.contains("$")) // never invents a figure
        XCTAssertFalse(a.followUps.isEmpty) // still offers what it can do
    }

    func testWhatCanYouDoListsCapabilities() {
        let a = answer("what can you do?", .sampleOkay)
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.lowercased().contains("where your money"))
        XCTAssertFalse(a.followUps.isEmpty)
    }

    func testPrivacyQuestionAnswered() {
        let a = answer("is my data safe?", .sampleOkay)
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.lowercased().contains("phone"))
        XCTAssertTrue(a.text.lowercased().contains("uploaded") || a.text.lowercased().contains("server"))
    }

    func testHowItWorksMentionsDeterministicSources() {
        let a = answer("how does this work?", .sampleOkay)
        XCTAssertFalse(a.isDecline)
        XCTAssertTrue(a.text.lowercased().contains("census") || a.text.lowercased().contains("compute") || a.text.lowercased().contains("bundled"))
    }

    func testGreetingIsFriendlyNotAMoneyAnswer() {
        let a = answer("hi", .sampleOkay)
        XCTAssertFalse(a.isDecline)
        XCTAssertFalse(a.text.contains("$"))
        XCTAssertFalse(a.followUps.isEmpty)
    }

    func testWordContainingHiDoesNotTriggerGreeting() {
        // "this month" contains the letters "hi" — must NOT be treated as "hi".
        let a = answer("how's this month?", .sampleOkay)
        XCTAssertFalse(a.text.hasPrefix("Hi!"))
    }

    // MARK: - Boundaries preserved

    func testDeclinesAdviceAndPointsTo211() {
        let a = answer("should I take out a loan to consolidate?", .sampleTight)
        XCTAssertTrue(a.isDecline)
        XCTAssertTrue(a.text.contains("211"))
    }

    func testNeedsNumbersWhenEmpty() {
        let a = answer("how's my cushion?", .empty)
        XCTAssertTrue(a.isDecline)
    }

    func testSafeLineWorksWithoutNumbers() {
        XCTAssertTrue(answer("what's the safe line?", .empty).text.lowercased().contains("safe line"))
    }

    // MARK: - Determinism (it can never invent a different figure)

    func testDeterministicAnswers() {
        for q in ["how's my cushion?", "how much do I keep each month?",
                  "how much over a year?", "why is it tight?"] {
            XCTAssertEqual(answer(q, .sampleTight).text, answer(q, .sampleTight).text, "‘\(q)’ must be deterministic")
        }
    }

    func testAnswersNeverInventBeyondPlan() {
        // The engine only quotes figures it can compute; a well-formed answer for
        // a complete plan is not a decline and carries provenance.
        let a = answer("how much do I keep each month?", .sampleOkay)
        XCTAssertFalse(a.isDecline)
        XCTAssertEqual(a.provenance, "Your numbers")
    }
}
