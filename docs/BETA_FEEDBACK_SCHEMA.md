# Beta Feedback Schema

_What the in-app "Send feedback" screen can produce. Source of truth:
`Core/FeedbackReport.swift` (+ `FeedbackReportTests`)._

Feedback is **assembled on-device and copied by the tester** — nothing is sent
automatically, and there is **no field for financial data** (income, expenses,
debt, verdicts, county, simulation results can never be attached).

## Fields
| Field | Always? | Source | Notes |
|---|---|---|---|
| Type | yes | tester picks | Bug · Confusing result · Accessibility issue · Incorrect benchmark · Feature request · Other |
| Description | yes | tester types | Free text. UI asks them not to paste private dollar amounts. |
| App version | opt-in (default on) | `Bundle` | e.g. `1.0 (1)` |
| Device model | opt-in (default on) | `utsname` / `SIMULATOR_MODEL_IDENTIFIER` | e.g. `iPhone17,1` |
| iOS version | opt-in (default on) | `UIDevice` | e.g. `iOS 26.5` |
| Text size | opt-in (default off) | `dynamicTypeSize` | accessibility setting |
| VoiceOver on/off | opt-in (default off) | `UIAccessibility` | accessibility setting |
| Reduce Motion on/off | opt-in (default off) | `UIAccessibility` | accessibility setting |
| Features tried | opt-in (default off) | `RetentionState` | e.g. "Tracked 2 months", "Opened the year-ahead" — engagement, not finances |
| Assurance line | yes | constant | "(No income, expenses, debt, verdicts, county, or simulation results are included.)" |

## Guarantees
- The tester sees the **exact** text before copying (the preview and the copied
  string are the same builder output).
- Toggling a section off removes it from the output (verified by tests).
- No network call is made by the app. Sharing is manual (paste).
