# Changelog

All notable changes to DebtShield. Dates are intentionally omitted in favor of
phase/commit references; see Git history for exact timing.

## Startup-hardening program

### Phase 0 — Repository audit + foundations
- Added root `CLAUDE.md` engineering charter (privacy non-negotiables + rules).
- Added `AUDIT_REPORT.md`, `ARCHITECTURE.md`, `STARTUP_ROADMAP.md`,
  `IMPLEMENTATION_STATUS.md`, `THRESHOLD_REGISTRY.md`.
- Created safe checkpoint tag `checkpoint/pre-phase-0`.
- Audit finding: engines are already robust (guarded divisions, deterministic
  Monte Carlo). Primary gaps: no engine unit-test target, no app-lock /
  snapshot masking, data-provenance docs/validation, in-app Trust Center.

### Phase 1 — Production hardening (in progress)
- **Privacy: background-snapshot masking.** The app now covers its UI with a
  neutral branded screen the moment it becomes inactive, so financial figures
  are not captured in the iOS app-switcher snapshot. (`DebtShieldAIApp.swift`)

### Phase 2 — Calculation validation (in progress)
- **Engine unit-test target `DebtShieldAITests`** added to the Xcode project and
  the shared scheme (mirrors the UI-test target; `@testable`, host = app).
  33 tests covering MoneyPlan verdict classification (incl. the dollar-cushion
  boundary), SituationEngine verdicts, MonteCarlo determinism / unit-range
  probabilities / percentile ordering / no-NaN / mode selection / sensitivity
  monotonicity, and CostComparisons (incl. food's U.S. row). **All passing.**
- Added `scripts/test-engines.sh` (CI-ready runner).
- `THRESHOLD_REGISTRY.md` documents every configurable heuristic.

## Prior product work (v3, pre-program)
See Git history `0b86e56`…`60d3436`: compact dashboard home, unified
`AppIconBadge` visual system, dollar-aware "tight" verdict, food comparison U.S.
row, feature tour, Monte Carlo confidence/sensitivity/transparency.
