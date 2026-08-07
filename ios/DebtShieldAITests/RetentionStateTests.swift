import XCTest
@testable import DebtShieldAI

/// On-device retention signals — month counting and stage, without streaks.
final class RetentionStateTests: XCTestCase {

    func testFreshBeforeAnyCompleteMonth() {
        let s = RetentionState.from(historyKeys: [], currentMonthKey: "2026-07", currentComplete: false)
        XCTAssertEqual(s.monthsTracked, 0)
        XCTAssertEqual(s.stage, .fresh)
        XCTAssertNil(s.firstMonthKey)
        XCTAssertNil(s.lastCompletedMonthKey)
        XCTAssertFalse(s.hasSecondMonth)
    }

    func testFirstMonthCounts() {
        let s = RetentionState.from(historyKeys: [], currentMonthKey: "2026-07", currentComplete: true)
        XCTAssertEqual(s.monthsTracked, 1)
        XCTAssertEqual(s.stage, .firstMonth)
        XCTAssertEqual(s.firstMonthKey, "2026-07")
        XCTAssertEqual(s.lastCompletedMonthKey, "2026-07")
    }

    func testBuildingAtTwoMonths() {
        let s = RetentionState.from(historyKeys: ["2026-06"], currentMonthKey: "2026-07", currentComplete: true)
        XCTAssertEqual(s.monthsTracked, 2)
        XCTAssertEqual(s.stage, .building)
        XCTAssertTrue(s.hasSecondMonth)
        XCTAssertEqual(s.firstMonthKey, "2026-06")
        XCTAssertEqual(s.lastCompletedMonthKey, "2026-07")
    }

    func testEstablishedAtThreePlus() {
        let s = RetentionState.from(historyKeys: ["2026-04", "2026-05", "2026-06"],
                                    currentMonthKey: "2026-07", currentComplete: true)
        XCTAssertEqual(s.monthsTracked, 4)
        XCTAssertEqual(s.stage, .established)
        XCTAssertEqual(s.firstMonthKey, "2026-04")
        XCTAssertEqual(s.lastCompletedMonthKey, "2026-07")
    }

    func testCurrentIncompleteUsesHistoryForLast() {
        let s = RetentionState.from(historyKeys: ["2026-05", "2026-06"],
                                    currentMonthKey: "2026-07", currentComplete: false)
        XCTAssertEqual(s.monthsTracked, 2)
        XCTAssertEqual(s.lastCompletedMonthKey, "2026-06")
    }

    func testDeduplicatesRepeatedKeys() {
        let s = RetentionState.from(historyKeys: ["2026-06", "2026-06"],
                                    currentMonthKey: "2026-06", currentComplete: true)
        XCTAssertEqual(s.monthsTracked, 1)
    }

    func testEngagementFlagsCarry() {
        let s = RetentionState.from(historyKeys: [], currentMonthKey: "2026-07", currentComplete: true,
                                    openedYearAhead: true, openedComparison: false, savedAnAction: true)
        XCTAssertTrue(s.openedYearAhead)
        XCTAssertFalse(s.openedComparison)
        XCTAssertTrue(s.savedAnAction)
    }
}
