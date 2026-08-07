# Product Requirements (PRD)

_What DebtShield is, who it's for, and the boundaries. Reflects the app as built._

## Problem
Many people — especially students and young adults — feel anxious and unclear
about their monthly money and worry about slipping into debt. Mainstream apps
demand bank connections, push products, or reduce people to a score. That's a
privacy cost and a dignity cost, and it excludes people who won't link a bank.

## Users
Primary: college students, young adults, first-generation students, community-
program participants, and anyone worried about monthly financial instability.
(See `USER_PERSONAS.md`.)

## Goal
Answer one question in plain dollars — *how does my money stand this month, and
where is it heading?* — privately, honestly, and without judgment, and point to
free help when needed.

## In scope (built)
- On-device profile (no server/account).
- Safe Line, dollar-aware verdict, year-ahead Monte Carlo (with assumptions),
  spending breakdown + trends, Compare (Census/EIA/BLS), deterministic Ask,
  "Could you move?", "Save & earn more" education, monthly "what changed",
  optional reminder, Face ID lock, delete-my-numbers, Trust Center, feedback.

## Non-goals / out of scope
- No backend for personal financial data; no bank connection.
- No ads; no payday-loan/credit/debt-settlement monetization.
- No individualized financial/legal/tax/housing advice.
- No score or grade; no fabricated social proof.
- No generative AI in Ask unless separately safety-reviewed and approved.

## Constraints (non-negotiable)
Privacy-first and on-device (see `../CLAUDE.md`); WCAG-AA accessibility;
educational framing with citations; releasable after every change; no
unnecessary dependencies.

## Success criteria (honest)
- People can state, in their own words, where their money stands this month.
- They return for a **second month** (the core retention signal).
- They trust it enough to enter real numbers.
- Institutions can sponsor it **without** seeing individual financial data.
See `METRICS_DEFINITIONS.md` for exact measures.

## Open questions
- Which institution type converts first (colleges vs nonprofits vs employers)?
- What's the smallest useful pilot?
- Does the year-ahead help or overwhelm first-time users? (Discovery + impact.)
