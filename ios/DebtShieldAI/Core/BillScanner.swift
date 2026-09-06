import Foundation

/// Reads dollar amounts out of the raw text of a scanned bill.
///
/// This is the whole "scanner" brain, and it is deliberately narrow: it only
/// *finds numbers* so a person can drop one into a monthly field faster. It never
/// categorises spending, never keeps a transaction, and never remembers the bill —
/// Headroom stays a cost-of-living tool, not an expense tracker. Pure Foundation,
/// with no Vision or UIKit, so it unit-tests headlessly alongside the other
/// engines; the camera, OCR, and UI live in the view layer.
enum BillScanner {
    /// The plausible range for a single monthly figure, in dollars. Keeps years,
    /// phone numbers, and account ids from being mistaken for money.
    private static let plausible: ClosedRange<Decimal> = 1...100_000

    /// Distinct dollar amounts found in `text`, largest first.
    ///
    /// Matches `$1,234.56`, `1,234`, `45.00`, and bare `1200` — a leading `$` and
    /// the cents are both optional. Amounts outside `plausible` are dropped, and
    /// duplicates are collapsed, so the caller gets a short, ranked list to choose
    /// from rather than every number on the page.
    static func amounts(in text: String) -> [Decimal] {
        let pattern = #/\$?\s?(\d{1,3}(?:,\d{3})+|\d+)(?:\.(\d{1,2}))?/#
        var found: [Decimal] = []
        var seen: Set<Decimal> = []
        for match in text.matches(of: pattern) {
            let whole = String(match.1).replacingOccurrences(of: ",", with: "")
            let numeric = match.2.map { "\(whole).\($0)" } ?? whole
            guard let value = Decimal(string: numeric), plausible.contains(value) else { continue }
            if seen.insert(value).inserted { found.append(value) }
        }
        return found.sorted(by: >)
    }
}
