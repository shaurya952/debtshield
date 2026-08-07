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

### Phase 15 — Ethical revenue infrastructure (docs; payments not activated)
- `startup-docs/`: `LICENSING_MODEL` (license sponsored access + services, never
  data), `PRICING_TEST_PLAN` (validate price in real pilots),
  `ORGANIZATION_REQUIREMENTS`, `CUSTOMER_DATA_BOUNDARIES` (the hard line: no
  individual financial data or verdicts ever reach an institution — enforced by
  architecture, not just policy), and `SAMPLE_PILOT_AGREEMENT_REQUIREMENTS`
  (a term-sheet outline explicitly labeled a draft requiring attorney review).
- No payments enabled; no personal-data sale; placeholders never presented as
  real prices or customers.

### Phase 16 — Scale architecture
- `SCALE_ARCHITECTURE.md`: staged growth A→D, what to build now vs postpone,
  explicit scaling triggers, and operational/security/cost/vendor-lock-in risks
  with migration paths. Invariants: no backend for personal financial data ever,
  Ask stays deterministic, and no premature microservices/databases/AI.

### Phase 7 — Analytics decision
- `ANALYTICS_DECISION.md`: compares Option A (no analytics SDK) vs Option B
  (strictly opt-in, minimal events). **Decision: Option A** — keep "Data Not
  Collected"; learn from App Store Connect aggregates, voluntary surveys, and
  in-app feedback. No analytics implemented, no app code added.
- Option B is specified only as a ready-but-unbuilt blueprint: an abstraction
  seam (NoOp default so a provider can be removed), exactly seven broad
  **parameterless** events, the hard never-transmit list, an opt-in flow (no
  ATT/IDFA), and the privacy-manifest / App Store label / policy / test changes
  required before any event could ever be sent.

### Phase 11 — Impact study
- Voluntary, anonymous pre/post survey design (no financial figures, ever):
  `docs/impact/` — protocol, instrument (5 Likert items + 8 self-reported
  actions, matched by an anonymous self-generated code), consent language,
  data-retention policy, and an honest report template.
- `scripts/impact_summary.py` — matches pre/post by code and prints an aggregate
  summary (improved/same/worse counts, means + Δ once n≥20, action counts) with
  a hard causation caveat, a small-n "preliminary" guard, and a **banned-column
  guard** that refuses any file containing financial/identifying fields.
  Verified on a clearly-labeled synthetic sample; added to CI.
- Framed as a voluntary product survey, not academic research (needs ethics
  oversight first); results are self-report/correlation, never causation.

### Phase 14 — Startup operations docs (`/startup-docs`)
- 18 founder-facing docs + an index, honest by rule (no fabricated users,
  partners, advisers, revenue, or metrics): PRD, personas, competitive
  positioning, business model, pricing experiments, customer discovery, pilot
  proposal, partner one-pager, demo script, sales-pipeline schema, adviser
  review packet, trust & safety, security checklist, accessibility checklist,
  risk register, incident-response plan.
- `METRICS_DEFINITIONS.md` — exact funnel definitions (visitor → download →
  activated → second-month → pilot → paying → retained) with source and
  verification status; explicitly bans vanity/inflated metrics and notes most
  in-app behavior is unobservable by design (private/on-device).
- `PUBLIC_CLAIMS_REGISTER.md` — every public claim mapped to its evidence, plus
  a list of claims we must not make.

### Phase 12 — App Store launch system
- `docs/appstore/` launch kit: `APP_STORE_LAUNCH.md` (listing name/subtitle/
  keywords/description, age rating, versioning, known limitations, contact),
  `APP_REVIEW_NOTES.md`, `PRIVACY_DISCLOSURE_WORKSHEET.md` (answers verified
  against `PrivacyInfo.xcprivacy` → "Data Not Collected"), `SCREENSHOT_PLAN.md`
  (screenshot set, captions, sizes, capture commands, app-preview storyboard),
  and `RELEASE_NOTES_TEMPLATE.md` (+ a v1.0 draft). Complements the existing
  technical checklist in `ios/APPSTORE.md`. Docs only — no submission performed.

### Phase 9 — Waitlist & pilot-interest capture
- Three **separate**, privacy-conscious website forms:
  **beta waitlist** (`/waitlist.html`), **institutional pilot** (on
  `/for-organizations.html`), and **professional reviewer** (`/reviewers.html`).
- Each has a required consent checkbox, a hidden spam honeypot, accessible
  labels, and **no financial fields**. Forms POST to a build-time
  `FORM_ENDPOINT`; until it's set they render a clear "not connected yet" state
  and submit nowhere.
- The site states plainly that these forms collect what you type — separate from
  the app, which sends nothing.
- `docs/WAITLIST_DATA_POLICY.md` covers fields, purpose, retention, access,
  deletion, spam, consent, security, and the provider options. CI form checks
  now enforce consent + honeypot + no financial fields.

### Visual polish — Ask & Compare
- **Ask:** gradient send button with a clear enabled/disabled state, brand-tinted
  suggestion chips (with press feedback), and chat bubbles with real depth
  (gradient user bubble + shadow; bordered, shadowed assistant bubble).
- **Compare:** comparison bars now use a subtle vertical gradient and are a touch
  taller, matching the app-icon category badges added earlier.
- No behavior change; Ask stays deterministic and on-device.

### Website deploy config
- Wired one-click deploys: `website/netlify.toml`, `website/vercel.json`, and
  Cloudflare Pages support (root=`website`, build `node build.mjs`, output `dist`).
- The build now emits `dist/_headers` (Netlify/Cloudflare) with a strict,
  JS-free **Content-Security-Policy** (`script-src 'none'`; `form-action` = self
  + the injected `FORM_ENDPOINT` origin), plus HSTS, `X-Content-Type-Options`,
  `X-Frame-Options: DENY`, a locked-down `Permissions-Policy`, and COOP; Vercel
  gets the equivalent via `vercel.json`.
- Added a branded **404 page**. README documents per-host deploy + how to verify
  headers. Build/tests pass (15 pages); `dist/` stays gitignored.
- **CI now guards the headers:** `website/test.mjs` asserts `dist/_headers` has
  the CSP directives + HSTS/nosniff/frame-deny/permissions/COOP, that
  `form-action` reflects `FORM_ENDPOINT` (self, or self + injected origin), and
  that `vercel.json` keeps parity. The CI `website` job runs it twice — once
  default, once with a sample `FORM_ENDPOINT` — so header or origin-injection
  regressions fail the build.

### Phase 8 — Public website (`/website`)
- A **zero-dependency static website** (Node stdlib generator — no framework, no
  trackers, no supply chain; documented rationale). 12 pages: Home, How it
  works, Methodology, Privacy, Data sources, Accessibility, For organizations,
  Impact, Help, About, Privacy policy, Terms.
- Responsive, light/dark, WCAG-AA, semantic HTML, skip link, visible focus.
  SEO + Open Graph + canonical per page; generated `sitemap.xml` + `robots.txt`.
- `node build.mjs` builds to `dist/`; `node test.mjs` validates links + meta +
  no placeholders/secrets (all passing). `serve.mjs` for local preview.
- Honest content: no fabricated metrics/testimonials/partners; Impact page says
  "nothing to report yet"; contact addresses omitted until real; legal pages
  labeled drafts pending attorney review. Deploy `dist/` anywhere (`SITE_URL` env).

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

### Accessibility UI-test rewrite
- Rewrote the accessibility UI-tests (`ios/DebtShieldAIUITests/`) to drive the
  **current** app (Home/Compare/Ask/About + detail screens), replacing the stale
  v1 tests (removed `ContrastHypothesis.swift`). Launched with onboarding skipped
  and a DEBUG-only seeded plan (`uitest-seed`) so populated screens are audited.
- `DebtShieldAIUITests` enforces reachability/structure and records a
  `performAccessibilityAudit` per screen; `AccessibilityDiagnostics` enumerates
  findings app-wide. The audit is recorded (not gating) due to known Xcode audit
  false positives (ScaledMetric Dynamic Type, under-bar contrast, intentional
  decorative truncation); Dynamic Type + contrast verified manually. All 7 UI
  tests pass.

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
