# DebtShield — Monthly Retention

_Last updated: Phase 5._

The product is built around one recurring action: **"update this month and see
what changed."** Everything here is on-device, non-manipulative, and never
transmitted (see `CLAUDE.md`). No streaks, no guilt, no penalty for a missed
month.

## The monthly loop
1. **A new month begins.** `MoneyPlanStore.rollOverIfNeeded()` (called on launch)
   detects the calendar month changed, archives the finished month into
   `history` (capped at 12), and **carries the plan forward** as the new month's
   starting point — bills usually recur, and the person adjusts what changed.
2. **You update your numbers** (the existing edit sheet). Actual months
   accumulate in `history`; the in-progress month is the live `plan`.
3. **You see what changed.** The home shows a "Since last month" card
   (`MonthChangeEngine`) — the change in room and the single figure that moved
   most, in plain words. This is **actual history**, kept visually and
   conceptually separate from the **year-ahead simulation** (a projection).
4. **Trends** appear in Your Spending / The Year Ahead once there are ≥2 months.

## Components
| Piece | File | Notes |
|---|---|---|
| Carry-forward + archive | `Core/MoneyPlanStore.swift` (`rollOverIfNeeded`) | Pre-existing; the spine of the loop. |
| "What changed" read | `Core/MonthChange.swift` | Pure, tested. Neutral wording (never "good/bad"). |
| Retention signals | `Core/RetentionState.swift` | Pure, tested. Months tracked, first/last month, stage (fresh → firstMonth → building → established), and which areas were opened. |
| Monthly reminder | `Core/MonthlyReminder.swift` | Local `UNUserNotification`; opt-in; user picks the day; cancellable. |
| Reminder settings | `Views/MonthlyCheckInCard.swift` | In About. Requests permission only when enabled; explains how to re-enable if denied. |
| "Since last month" card | `Views/SafeLineView.swift` | Shown only when history exists (keeps first-run home compact). |

## Retention state (on-device only)
`RetentionState` can determine, locally: the number of months tracked, the first
and last completed month, whether a second month exists, the engagement stage,
and whether the year-ahead / comparison / save-&-earn areas have been opened
(persisted as local `UserDefaults` flags set on those screens' `onAppear`).

**These values are never transmitted.** They exist to let the app understand
engagement and, later, time gentle nudges. Any future off-device use requires
the separate, explicit consent designed in Phase 7 (opt-in analytics).

## Anti-dark-pattern rules
- Reminder copy is plain: _"When you have a minute, update this month's numbers
  to see where you stand."_ No urgency, no fear, no streak.
- Missing a month does nothing — no reset, no badge, no shame.
- The reminder is off by default and fully user-controlled (day + on/off).

## Follow-ups
- Wire a gentle, dismissible in-app nudge off `RetentionState` (e.g. suggest the
  year-ahead to someone who hasn't opened it) — kept optional and non-nagging.
- Device testing of the local notification (delivery can't be unit-tested).
