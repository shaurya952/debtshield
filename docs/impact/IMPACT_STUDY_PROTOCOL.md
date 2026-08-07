# Impact Study Protocol

_A lightweight, honest, voluntary pre/post survey to learn whether DebtShield
helps people understand and act on their monthly money. Not a clinical trial and
not formal human-subjects research unless proper oversight is obtained first._

## Question
Does using DebtShield for a month or two improve people's **self-reported**
understanding of their monthly finances, confidence in planning, and awareness
of free help — and do they report taking concrete actions?

## Design
- **Pre/post, within-person**, matched by an anonymous self-generated code.
- No control group by default → this measures change over time, **not** proof
  the app caused it. Say so plainly (see "Interpretation").
- No financial figures collected (see `SURVEY_INSTRUMENT.md`).

## Participants
Voluntary beta testers and pilot participants who consent
(`CONSENT_LANGUAGE.md`). 18+.

## Procedure
1. Consent → **pre-survey** before first real use.
2. Use the app for ~4–6 weeks (ideally into a second month).
3. **Post-survey** with the same code + actions taken.
4. Analyze aggregates with `scripts/impact_summary.py`.

## Measures
Five Likert items (understanding position, money left, biggest pressure,
confidence planning, awareness of help) pre and post; eight self-reported actions
post-only.

## Analysis
- Match pre/post by code; report **n matched pairs**.
- Per item: mean pre, mean post, and the change (delta).
- Actions: percent who reported each.
- Report raw counts alongside any average.
- **Small samples:** if matched n < 20, report counts only and label results as
  preliminary/illustrative — no averages presented as findings.

## Interpretation (the honesty core)
- These are **self-reports**, not observed behavior.
- A pre→post change is **correlation over time**, not demonstrated **causation**
  (no control, self-selection, expectancy effects). Do not say "DebtShield
  improved X" — say "participants reported X changed."
- Never publish a number without n, period, and this caveat
  (see `IMPACT_REPORT_TEMPLATE.md`).

## Ethics & privacy
- Voluntary, anonymous, no financial data, deletable (`DATA_RETENTION_POLICY.md`).
- No incentives tied to positive answers.
- If this becomes formal research, obtain IRB/ethics oversight and revise consent.

## Deliverables
`scripts/impact_summary.py` (aggregate + summary), `IMPACT_REPORT_TEMPLATE.md`
(honest writeup), and the instrument/consent/retention docs here.
