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

### Phase 6 — Privacy-preserving beta feedback
- **In-app "Send feedback"** (`FeedbackView`, reachable from About and the Trust
  Center): pick a type, write a note, and opt into non-sensitive diagnostics
  (device, accessibility settings, features tried). A **live preview shows
  exactly what will be shared**, and the action is copy-to-clipboard — nothing
  is sent automatically. Financial data can never be attached (`FeedbackReport`
  has no field for it).
- Pure `FeedbackReport` builder, unit-tested (+6 tests → 51 total).
- Beta process docs under `docs/`: BETA_TESTING_GUIDE, TESTER_RECRUITMENT_GUIDE,
  USER_INTERVIEW_GUIDE, BETA_FEEDBACK_SCHEMA, BUG_REPORT_TEMPLATE,
  RELEASE_CHECKLIST.

### Phase 5 — Monthly retention (in progress)
- **"Since last month" card** on the home (`MonthChangeEngine`): the change in
  room and the single figure that moved most, in plain, neutral words — actual
  history, kept separate from the year-ahead projection. Shows only once there's
  history, so the first-run home stays compact.
- **On-device `RetentionState`** (pure, tested): months tracked, first/last
  month, engagement stage, and which areas were opened — never transmitted.
- **Opt-in monthly reminder** (`MonthlyReminder` + `MonthlyCheckInCard` in
  About): a local notification, off by default, user picks the day, cancellable.
  Plain copy, no streaks, no shame. Asks permission only when enabled.
- Two new pure engines fully unit-tested (+12 tests → 45 total, all passing).
- See `RETENTION.md`.

### Phase 4 — UX, accessibility & Trust Center (in progress)
- **Accessibility audit** at the largest Dynamic Type (AX5): the screens scale
  and scroll without clipping or overlap. Fixed the one real finding — long
  large-style nav titles truncated ("How you compare" → "How you co…"); Compare
  and How-it-works now use inline titles (Home and detail screens already did).
  Documented commitments, method, per-screen status, and known gaps in
  `ACCESSIBILITY.md` (incl. the stale v1 accessibility UI-tests to rewrite).
- **In-app Trust Center** (`TrustCenterView`, linked prominently from About):
  an honest "what it does / never does" ledger, a privacy summary, how the
  numbers are worked out, the data sources with vintages, an accessibility
  statement, the data & security controls, free help (211 / HUD / Benefits.gov),
  and an honest corrections note (no fabricated contact address).
- Extracted the app-lock + delete controls into a shared `DataSecurityCard`
  used by both About and the Trust Center.

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
