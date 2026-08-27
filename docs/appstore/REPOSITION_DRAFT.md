# Reposition draft — from "budgeting app" to "where you could afford to live"

Draft App Store copy for the relocation pivot. This does **not** overwrite the
live `SUBMISSION_COPY.md` — adopting it is a product-identity call for the owner.
Everything here is honest and matches what the app actually does now (Places
ranking + occupation pay + Monte Carlo risk, all on-device).

## The one-line positioning
> A private, on-device way to see **where in the U.S. your money would actually
> stretch** — ranked from your real numbers against real local costs.

The budgeting basics (enter your numbers → are you okay, how's your debt) stay as
the on-ramp; the *hero* is the question no other app answers well.

## Name
- **Keep the bundle id** `com.debtshield.DebtShieldAI` — it's live on TestFlight;
  changing it would orphan the build. This is not up for debate technically.
- The **display name** could evolve to say what it does. Options to consider
  (owner's call — not changed in code):
  - Keep **DebtShield** (equity already built, TestFlight link, domain).
  - Add a descriptive subtitle rather than rename (recommended, lowest-risk).

## Subtitle (≤30 chars) — pick one
- `Where your money goes far`
- `See where you could thrive`
- `Cost of living, your numbers`

## Promotional text (≤170 chars)
> Enter your real numbers and see where in the U.S. they'd leave you the most
> breathing room — by state, by county, even by your job's local pay. Private,
> on-device.

## Keywords (≤100 chars, comma-separated, no spaces)
`costofliving,relocation,move,affordability,rent,salary,bystate,budget,takehome,county,wages,cheapest`

## Description (draft)
Most money apps look backward at the city you're already in. DebtShield looks
forward: given your real numbers, **where could you actually afford to build a
life?**

- **Rank every place by breathing room.** See which states stretch your money,
  then drill into a county for the specifics — sorted by how much you'd have left
  over each month.
- **Same job, new place.** Pick your occupation and see how its *local* pay in
  each state stacks up against local costs. The same career can mean a very
  different life across state lines.
- **Not just cheap — safe.** Each place carries a plain risk read from an on-device
  simulation of the year ahead, so a cheap-but-fragile spot is flagged, not hidden.
- **Your month, in plain dollars.** Enter what comes in and goes out and see where
  you stand — no score, no grade, no lecture.

Private by design: there's no account and no server. Your numbers never leave your
phone. Comparison figures come from public data — U.S. Census (rent), EIA (energy),
and BLS (spending and wages). Educational information, not financial advice.

## What's New (for the build that ships the pivot)
> New: a Places tab that ranks where your money would stretch furthest across the
> U.S. — by state, by county, and by your job's typical local pay — each with a
> plain year-ahead risk read. All private and on-device.

## Screenshots to reshoot (see SCREENSHOT_PLAN.md)
1. Places → States ("Best states first") — the hero.
2. A state's counties, drilled in.
3. "Same job, new place" — occupation picked, map re-ranked.
4. A place detail (here vs. there).
5. Home (the on-ramp) + About/Methodology (the credibility).

## Owner decisions before adopting
- Whether to change the display name / subtitle.
- Whether to lead the App Store description with relocation (this draft) or keep
  the current budgeting-first copy.
- Which occupations to feature in the screenshots.
