# DebtShield — Startup Roadmap

_Last updated: Phase 0. This organizes the 16-phase program by launch stage.
Status lives in `IMPLEMENTATION_STATUS.md`; this file is the plan of record._

## Guiding constraints
Privacy-first and on-device for personal data (see `CLAUDE.md`). Never fabricate
traction. Keep the repo releasable after every phase. Many later phases require
**human/Apple/legal/partner actions** — those are labeled `[HUMAN]`.

---

## Immediate launch blockers (before any public beta)
- **P1 Production hardening** — app lock (Face ID/Touch ID, optional),
  background-snapshot masking, prominent "Delete all financial data",
  no financial values in Release logs, edge-case robustness (mostly already
  solid — see audit).
- **P2 Calculation validation** — threshold registry (doc ✔), **XCTest unit
  target** with the full edge-case matrix, methodology docs.
- **P3 Data trust** — data dictionary/sources, validation script, update guide.
- **P4 UX + accessibility + Trust Center** — screen-by-screen a11y pass; in-app
  Trust Center (what it does/doesn't, privacy, methodology, limits, delete,
  help). Also the standing UX ask: keep making it easier + more visually
  appealing without weakening a11y or rewriting what works.

## Beta requirements
- **P5 Monthly retention** — start-a-new-month, carry-forward, "what changed",
  history/trends, on-device non-manipulative reminders.
- **P6 Privacy-preserving beta feedback** — in-app feedback that never
  auto-includes financial data; shows exactly what will be sent.
- **P13 (partial) Testing + CI** — engine unit tests in CI, dataset validation,
  secret scanning.

## App Store requirements
- **P12 App Store launch system** — description, screenshots, privacy labels,
  review notes, release checklist. `[HUMAN]` submission + Apple account actions.

## User-validation infrastructure
- **P7 Opt-in privacy-safe analytics** — decision doc first; only broad,
  non-sensitive events; opt-in; abstraction layer. Not enabled by default.
- **P11 Impact study** — voluntary pre/post surveys, anonymous matching code,
  aggregate export, honest (no fabricated causal claims). `[HUMAN]` oversight.

## Institutional-pilot infrastructure
- **P8 Public website** (`/website`) — marketing + methodology + data sources +
  accessibility + "for organizations" + help resources + legal.
- **P9 Waitlist / pilot-interest** — separate general / institutional / adviser
  forms; privacy-conscious; no financial fields. `[HUMAN]` provider choice.
- **P10 Institutional pilot portal** — minimal partner portal; **never** exposes
  individual financial data; aggregate-only; RBAC. Build only when a real pilot
  requires it.

## Revenue infrastructure
- **P15 Ethical revenue** — institutional licensing model, pricing tests,
  customer-data boundaries. No personal-data sale, ever. Legal templates are
  `[HUMAN]` discussion drafts requiring attorney review.

## Long-term scale infrastructure
- **P14 Startup operations docs** (`/startup-docs`) — PRD, business model,
  personas, positioning, risk register, security/accessibility checklists,
  metrics definitions, public-claims register.
- **P16 Scale architecture** — staged growth A→D, scaling triggers, deliberately
  postponed components; avoid premature microservices/DBs/AI.

---

## Success scoreboard (verified only — no invented values)
Tracked in `/startup-docs/METRICS_DEFINITIONS.md` (Phase 14). Every metric needs:
exact definition · time period · data source · verification status · last-updated.
Tier-1 progress = functioning public product + real activated users + monthly
retention + verified pilots + paying customers + methodology review + measured
benefit + strong privacy/a11y — **not** code complexity.

## Current position
Phase 0 in progress (this commit). Product is a working v3 personal app; the
startup scaffolding (docs, tests, website, portal) is being built up in order.
