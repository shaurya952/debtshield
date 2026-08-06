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
- **Optional app lock.** A Face ID / Touch ID / passcode lock (LocalAuthentication,
  `.deviceOwnerAuthentication`), off by default, toggled in About ▸ Your data &
  security. Falls back gracefully (never locks out a device without biometrics/
  passcode). Added `NSFaceIDUsageDescription`.
- **"Delete my numbers".** A prominent, clearly-worded destructive control (About)
  that calls `MoneyPlanStore.clear()` — erasing only the user's entered income,
  essentials, saved months, and area from this device. The bundled comparison
  data (Census/EIA/BLS) lives in the app bundle and is explicitly untouched;
  the copy says so.

### Phase 2 — Calculation validation (in progress)
- **Engine unit-test target `DebtShieldAITests`** added to the Xcode project and
  the shared scheme (mirrors the UI-test target; `@testable`, host = app).
  33 tests covering MoneyPlan verdict classification (incl. the dollar-cushion
  boundary), SituationEngine verdicts, MonteCarlo determinism / unit-range
  probabilities / percentile ordering / no-NaN / mode selection / sensitivity
  monotonicity, and CostComparisons (incl. food's U.S. row). **All passing.**
- Added `scripts/test-engines.sh` (CI-ready runner).
- `THRESHOLD_REGISTRY.md` documents every configurable heuristic.

### Phase 13 — Automated testing & CI (in progress)
- **GitHub Actions CI** (`.github/workflows/ci.yml`): three gated jobs —
  engine unit tests (macOS runner, dynamic simulator pick), dataset validation,
  and a secret scan — with a `ci-ok` gate for branch protection.
- **`scripts/validate_datasets.py`** — structural/sanity validation of the
  bundled CSVs (columns, numeric, non-negative, unique FIPS, band ordering).
  Passing locally: 3,144 counties, 51 energy rows, 9 food bands, 0 warnings.
- **`scripts/scan_secrets.sh`** — dependency-free high-signal secret scan.
- Governance: `SECURITY.md`, PR template, bug/feature issue templates.
- Note: CI runs once the repo has a GitHub remote (`[HUMAN]`); every script is
  verified locally here.

## Prior product work (v3, pre-program)
See Git history `0b86e56`…`60d3436`: compact dashboard home, unified
`AppIconBadge` visual system, dollar-aware "tight" verdict, food comparison U.S.
row, feature tour, Monte Carlo confidence/sensitivity/transparency.
