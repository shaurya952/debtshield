import Foundation

/// On-device retention signals — how far along someone is in the monthly habit,
/// plus which parts of the app they've explored.
///
/// These are computed and kept **only on the device** and are never transmitted
/// (see `CLAUDE.md`). Their purpose is to let the app understand engagement and
/// time gentle, non-manipulative nudges — never to track a person. There are no
/// streaks and no penalties for missed months.
struct RetentionState: Equatable, Sendable {
    /// Distinct months with real data, including the current one if complete.
    let monthsTracked: Int
    /// "yyyy-MM" of the earliest and latest tracked months, if any.
    let firstMonthKey: String?
    let lastCompletedMonthKey: String?
    /// Which parts of the app have been opened (persisted locally).
    let openedYearAhead: Bool
    let openedComparison: Bool
    let savedAnAction: Bool

    var hasSecondMonth: Bool { monthsTracked >= 2 }

    enum Stage: String, Sendable, Equatable {
        case fresh        // no complete month yet
        case firstMonth   // exactly one month tracked
        case building     // two months tracked
        case established  // three or more
    }

    var stage: Stage {
        switch monthsTracked {
        case ..<1: return .fresh
        case 1: return .firstMonth
        case 2: return .building
        default: return .established
        }
    }

    /// Builds the state from the store's month data plus the engagement flags.
    /// `historyKeys` is the finished months (any order); `currentMonthKey` and
    /// `currentComplete` describe the in-progress month.
    static func from(
        historyKeys: [String],
        currentMonthKey: String,
        currentComplete: Bool,
        openedYearAhead: Bool = false,
        openedComparison: Bool = false,
        savedAnAction: Bool = false
    ) -> RetentionState {
        var keys = Set(historyKeys.filter { !$0.isEmpty })
        if currentComplete, !currentMonthKey.isEmpty { keys.insert(currentMonthKey) }
        let sorted = keys.sorted()
        let last: String? = {
            if currentComplete, !currentMonthKey.isEmpty { return currentMonthKey }
            return sorted.last
        }()
        return RetentionState(
            monthsTracked: sorted.count,
            firstMonthKey: sorted.first,
            lastCompletedMonthKey: last,
            openedYearAhead: openedYearAhead,
            openedComparison: openedComparison,
            savedAnAction: savedAnAction
        )
    }
}
