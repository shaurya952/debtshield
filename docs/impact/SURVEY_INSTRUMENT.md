# Impact Survey Instrument

_Voluntary, anonymous pre/post surveys. **No financial figures are collected** —
only self-reported understanding, confidence, awareness, and actions. Keep it
short (a few minutes)._

## Anonymous matching code (no identity)
So a person's pre and post responses can be matched **without** collecting who
they are, ask them to create a code they can reproduce later — for example:
> First two letters of a street you grew up on + the two-digit day of your birth
> (e.g. "MA" + "07" → **MA07**).
This is not linkable to identity and is used only to pair pre/post. Store it as
`code`. If someone forgets it, their post response is counted as unmatched.

## Scale
Likert 1–5: 1 = strongly disagree … 5 = strongly agree. ("Prefer not to say" is
allowed and recorded as blank.)

## Pre survey (before first real use)
Consent first (see `CONSENT_LANGUAGE.md`). Then:
- `code` (matching code, above)
- `q_understand_position` — "I understand where my money stands each month."
- `q_understand_left` — "I know roughly how much I have left after essentials."
- `q_aware_pressure` — "I know my biggest financial pressure right now."
- `q_confidence_plan` — "I feel confident planning next month."
- `q_aware_help` — "I know where to find free help if money gets tight."

## Post survey (after ~4–6 weeks of use)
Same code + the same five items (to compare), plus **actions taken** (yes/no,
optional — "did you do any of these, at least partly because of DebtShield?"):
- `a_reviewed_expense` — reviewed a recurring expense
- `a_reduced_category` — reduced a spending category
- `a_started_cushion` — started building a cushion
- `a_reconsidered_payment` — reconsidered taking on a new payment
- `a_used_resource` — used a free educational resource
- `a_contacted_counselor` — contacted a free counselor (e.g. 211/HUD)
- `a_compared_housing` — compared housing costs / a move
- `a_updated_plan` — updated a monthly plan
- `open_feedback` — optional free text (ask them not to include private dollar
  amounts)

## Data schema (CSV) — see `sample_responses.example.csv`
Columns: `code, phase (pre|post), q_understand_position, q_understand_left,
q_aware_pressure, q_confidence_plan, q_aware_help,
a_reviewed_expense, a_reduced_category, a_started_cushion,
a_reconsidered_payment, a_used_resource, a_contacted_counselor,
a_compared_housing, a_updated_plan`
(Action columns are blank on `pre` rows.) **No name, email, income, rent, debt,
verdict, county, or simulation results — ever.**

## Delivery
Run through a privacy-conscious survey tool or a simple anonymous form (no email
required). Never tie a response to a person or to their in-app financial data.
