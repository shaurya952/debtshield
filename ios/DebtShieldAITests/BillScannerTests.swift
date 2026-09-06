import XCTest
@testable import DebtShieldAI

/// The bill-scan parser. It only reads numbers out of OCR text — never
/// categorises or stores anything — so these tests pin the reading itself:
/// commas, cents, the `$`, de-duping, ranking, and the sane-magnitude filter.
final class BillScannerTests: XCTestCase {

    func testReadsCommasCentsAndDollarSign() {
        let text = "Amount due: $1,234.56"
        XCTAssertEqual(BillScanner.amounts(in: text), [Decimal(string: "1234.56")!])
    }

    func testRanksLargestFirstAndDeduplicates() {
        let text = "Rent 1200\nTotal $1,240.00\nlate fee 45\nrent 1200 again"
        XCTAssertEqual(BillScanner.amounts(in: text),
                       [Decimal(1240), Decimal(1200), Decimal(45)])
    }

    func testBareIntegerAndDecimalBothParse() {
        XCTAssertEqual(BillScanner.amounts(in: "Payment 89"), [Decimal(89)])
        XCTAssertEqual(BillScanner.amounts(in: "Payment 89.9"), [Decimal(string: "89.9")!])
    }

    func testDropsOutOfRangeNumbers() {
        // Account number (too big) and a stray 0 (below range) are not money.
        let text = "Acct 000123456789  balance 0  due $350"
        XCTAssertEqual(BillScanner.amounts(in: text), [Decimal(350)])
    }

    func testEmptyWhenNoNumbers() {
        XCTAssertTrue(BillScanner.amounts(in: "Thank you for your payment").isEmpty)
    }
}
