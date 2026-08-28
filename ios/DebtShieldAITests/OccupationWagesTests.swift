import XCTest
@testable import DebtShieldAI

/// The "same job, new place" wage layer — gross annual wage → estimated monthly
/// take-home, per state, never guessing a state the job isn't reported in.
final class OccupationWagesTests: XCTestCase {

    private let w = OccupationWages.previewSample

    func testTakeHomeConversion() {
        let expected = 99730.0 / 12 * OccupationWages.takeHomeRatio
        XCTAssertEqual(w.monthlyTakeHome(occupation: "29-1141", state: "Massachusetts")!, expected, accuracy: 0.5)
    }

    func testUnreportedStateIsNil() {
        XCTAssertNil(w.monthlyTakeHome(occupation: "29-1141", state: "Wyoming"))
        XCTAssertNil(w.monthlyTakeHome(occupation: "00-0000", state: "Massachusetts"))
    }

    func testByStateMapCarriesTheRealContrast() {
        let m = w.monthlyTakeHomeByState(occupation: "29-1141")
        XCTAssertEqual(Set(m.keys), ["Massachusetts", "Tennessee", "California", "Mississippi"])
        // A registered nurse takes home more in MA than TN — the whole point.
        XCTAssertGreaterThan(m["Massachusetts"]!, m["Tennessee"]!)
        XCTAssertGreaterThan(m["California"]!, m["Massachusetts"]!)
    }

    func testOccupationsListed() {
        XCTAssertEqual(w.occupations.count, 2)
        XCTAssertTrue(w.occupations.contains { $0.name == "Registered Nurse" })
    }
}
