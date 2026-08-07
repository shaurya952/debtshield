# Customer Data Boundaries

_The hard line that makes DebtShield's institutional model ethical. This clause
belongs in every agreement, verbatim in spirit._

## The rule
An institution **never** receives, and we never collect or transmit, any
individual participant's financial data or verdicts. Participants' numbers stay
on their own devices.

## What DOES flow (only these)
| Data | Between | Purpose |
|---|---|---|
| Organization contact + billing info | Org ↔ us | Run the relationship |
| Aggregate, voluntary survey results | Us → org | End-of-pilot reporting |
| Enrollment count (aggregate) | Org ↔ us | Rough sizing, if ethically valid |
| Support correspondence | Org ↔ us | Help |

## What NEVER flows
- Individual income, rent, food, energy, or debt figures.
- Individual verdicts, simulation odds/results, or "Could you move?" results.
- Any identifiable financial profile.
- A participant's identity tied to their financial data.

## Why it's technically enforceable
The app has no backend for personal financial data and makes no network requests
with it. There is no store from which individual data could be exported — by
architecture, not just by policy.

## Aggregate reporting rules
- Report only voluntary survey aggregates; suppress small cells (e.g. < 10) to
  avoid re-identification.
- Never combine survey data with any financial figures (there are none to
  combine).

## Roles & terms
- **Data we process:** organization-contact and (if surveys run) anonymous
  survey responses — not participant financial data.
- Any subprocessor (e.g. a form/survey tool) is disclosed, minimal, and covered
  by a data-processing agreement.
- Deletion honored per `../docs/impact/DATA_RETENTION_POLICY.md` and the
  waitlist data policy.

## Non-negotiable
If a prospective customer insists on individual participant data, decline the
deal. This boundary is not for sale.
