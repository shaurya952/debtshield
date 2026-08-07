# DebtShield — Implementation Status

_Living document. Update it as work lands. Read it (and the Git diff) before
starting a phase._

## Legend
✅ done · 🟡 in progress · ⬜ not started · `[HUMAN]` needs a human/Apple/legal/partner action

## Program phases
| Phase | Title | Status | Notes |
|------:|-------|:------:|-------|
| 0 | Repository audit + foundational docs | ✅ | This commit. Audit/architecture/roadmap/registry/status + root CLAUDE.md created; safe checkpoint tag `checkpoint/pre-phase-0`. |
| 1 | Production hardening | 🟡 | ✅ Background-snapshot masking. ✅ Optional Face ID/Touch ID/passcode **app lock** (About ▸ Your data & security). ✅ Prominent **"Delete my numbers"** (scoped to the user's own entries via `store.clear()`; bundled data untouched, wording makes this explicit). **Still needed:** log-hygiene audit for Release, storage-protection doc. |
| 2 | Calculation & Monte Carlo validation | 🟡 | `THRESHOLD_REGISTRY.md` done. **XCTest unit-test target `DebtShieldAITests` added — 33 tests, all passing** (MoneyPlan, Situation, MonteCarlo determinism/bounds/sensitivity, CostComparisons). Runner: `scripts/test-engines.sh`. **Still needed:** methodology docs (ENGINE/MONTE_CARLO/ASSUMPTIONS). |
| 3 | Data pipeline & benchmark trust | 🟡 | **Validation script `scripts/validate_datasets.py`** added and passing (3,144 counties / 51 energy / 9 food bands, 0 warnings), wired into CI. **Still needed:** DATA_DICTIONARY / DATA_SOURCES / DATA_UPDATE_GUIDE docs. |
| 4 | UX, accessibility & Trust Center | 🟡 | Visual/ease-of-use polish + **Trust Center** done. **Accessibility audit done** at the largest Dynamic Type (AX5): screens scale/scroll without clipping; fixed long large-title truncation (Compare + How-it-works → inline). See `ACCESSIBILITY.md`. **Still needed:** rewrite the **stale v1 accessibility UI-tests** to the current UI + a physical-device VoiceOver walk-through. |
| 5 | Monthly retention | 🟡 | Carry-forward + archive already existed (`rollOverIfNeeded`). **Added:** "Since last month" card (`MonthChangeEngine`, pure+tested), on-device `RetentionState` (pure+tested), and an opt-in, non-manipulative **monthly reminder** (`MonthlyReminder` + `MonthlyCheckInCard`). Engagement flags wired on-device. See `RETENTION.md`. **Still needed:** device-test the notification; optional gentle in-app nudge. |
| 6 | Privacy-preserving beta feedback | ✅ | In-app **Send feedback** (`FeedbackView`, from About + Trust Center): type + note + opt-in device/accessibility/features, a live "exactly what will be shared" preview, copy-to-share, **no financial data ever, nothing auto-sent**. Pure `FeedbackReport` (+6 tests). Docs in `docs/` (BETA_TESTING_GUIDE, TESTER_RECRUITMENT_GUIDE, USER_INTERVIEW_GUIDE, BETA_FEEDBACK_SCHEMA, BUG_REPORT_TEMPLATE, RELEASE_CHECKLIST). |
| 7 | Opt-in analytics architecture | ✅ | `ANALYTICS_DECISION.md` compares Option A (no analytics) vs B (strictly opt-in). **Decision: Option A** — no analytics SDK; learn via App Store Connect aggregates + voluntary surveys + feedback. Option B fully specified as a blueprint (abstraction seam, 7 broad parameterless events, hard never-transmit list, opt-in flow, manifest/label/policy updates, tests) but **not implemented**. No app code added. |
| 8 | Public website (`/website`) | ✅ | Zero-dependency static site (12 pages): Home, How it works, Methodology, Privacy, Data sources, Accessibility, For organizations, Impact, Help, About, Privacy policy, Terms. Build + link/meta checks pass (`node build.mjs` / `node test.mjs`). Responsive, light/dark, WCAG-AA, SEO/OG, sitemap, robots. Deploy `dist/` to Vercel/Netlify/CF Pages. **`[HUMAN]`:** set `SITE_URL`, add real contact address, attorney-review the legal drafts. |
| 9 | Waitlist & pilot interest | ✅ | Three **separate** privacy-conscious forms — beta waitlist, institutional pilot (on For organizations), reviewer interest — with consent, spam honeypot, no financial fields, and a build-time `FORM_ENDPOINT` (clearly "not connected" until set). Data policy in `docs/WAITLIST_DATA_POLICY.md`; CI checks enforce consent+honeypot. **`[HUMAN]`:** choose a provider/endpoint and set `FORM_ENDPOINT`. |
| 10 | Institutional pilot portal | ⏸ Deferred (by design) | Architecture + hard data boundaries specified (`SCALE_ARCHITECTURE.md`, `startup-docs/CUSTOMER_DATA_BOUNDARIES.md`). Build only when a signed pilot needs self-serve setup / aggregate reports — sooner would be premature enterprise complexity (charter rule 13). Aggregate-only, RBAC, never individual data. |
| 11 | Impact study | ✅ | Voluntary, anonymous pre/post survey design (no financial figures): protocol, instrument, consent, retention, report template in `docs/impact/`. **`scripts/impact_summary.py`** matches pre/post by anonymous code and prints an honest aggregate (counts, Δ, actions) with a small-n guard and a **banned-column guard** (refuses financial/identifying fields); verified on synthetic sample + wired into CI. **`[HUMAN]`:** run via a survey tool; obtain ethics oversight before calling it research. |
| 12 | App Store launch system | ✅ | Launch kit in `docs/appstore/`: `APP_STORE_LAUNCH` (listing copy, subtitle/keywords, versioning, known limits, contact), `APP_REVIEW_NOTES`, `PRIVACY_DISCLOSURE_WORKSHEET` (verified vs the privacy manifest → "Data Not Collected"), `SCREENSHOT_PLAN` (+ app-preview storyboard), `RELEASE_NOTES_TEMPLATE`. Complements `ios/APPSTORE.md`. **`[HUMAN]`:** own bundle id + signing team, support email, capture screenshots, submit. |
| 13 | Automated testing & CI | 🟡 | Engine unit-test target + `scripts/test-engines.sh`. **GitHub Actions CI added** (`.github/workflows/ci.yml`): engine tests (macOS), dataset validation, secret scan, all gated by `ci-ok`. PR + issue templates, `SECURITY.md` added. Scripts verified locally. **Still needed:** `[HUMAN]` push to a GitHub remote so Actions run; optional deeper secret scanner. |
| 14 | Startup operations docs (`/startup-docs`) | ✅ | 18 docs + index: PRD, personas, positioning, business model, pricing experiments, customer discovery, pilot proposal, partner one-pager, demo script, sales pipeline schema, adviser packet, trust & safety, security/accessibility checklists, risk register, incident response, **METRICS_DEFINITIONS** (no vanity metrics), **PUBLIC_CLAIMS_REGISTER** (every claim + evidence). No fabricated traction. |
| 15 | Ethical revenue infrastructure | ✅ | `startup-docs/`: LICENSING_MODEL, PRICING_TEST_PLAN, ORGANIZATION_REQUIREMENTS, CUSTOMER_DATA_BOUNDARIES (hard no-individual-data line), SAMPLE_PILOT_AGREEMENT_REQUIREMENTS (term-sheet outline, labeled draft). Payments **not** activated; no personal-data sale. `[HUMAN]` attorney review before any agreement. |
| 16 | Scale architecture | ✅ | `SCALE_ARCHITECTURE.md`: stages A→D, components now vs deliberately postponed, scaling triggers (build X only when Y), operational/security/cost/vendor-lock-in risks, migration paths. Invariant: no personal-finance backend, ever; Ask stays deterministic; avoid premature microservices/DBs/AI. |

## What exists already (pre-program, verified)
- Working v3 iOS app (all features in `AUDIT_REPORT.md` §2), Debug + Release green.
- `Core/` engines pure & headlessly testable; Monte Carlo deterministic.
- UI-test target with accessibility/contrast probes (`ios/DebtShieldAIUITests/`).
- Seed docs: `ios/APPSTORE.md`, `ios/PHASE1-SETUP.md`.

## Human actions outstanding
- `[HUMAN]` Set Apple signing Team for device/TestFlight (Signing & Capabilities).
- `[HUMAN]` Decide on waitlist/feedback provider (Phases 6/9) before wiring any
  external endpoint.
- `[HUMAN]` Legal review of any policy/agreement drafts (Phases 12/15).
- `[HUMAN]` Restart Claude Code session to enable the live simulator panel
  (xcode-select fix already applied on the machine).

## Program status
All build-and-doc phases are complete: **0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12,
13, 14, 15, 16**. Phase **10** (partner portal) is deliberately deferred until a
real pilot requires it. The repo is releasable; app builds green Debug + Release
with 45 engine tests + website/data/impact CI checks passing.

## What's left is human execution, not code
- `[HUMAN]` Own bundle id + Apple signing Team; capture screenshots; submit to
  the App Store (`docs/appstore/`).
- `[HUMAN]` Push to a GitHub remote to activate CI; deploy the website
  (`SITE_URL`, `FORM_ENDPOINT`).
- `[HUMAN]` Attorney review of legal drafts (terms, privacy policy, pilot
  agreement requirements).
- `[HUMAN]` Add a real support/corrections address (site + Trust Center + review
  notes); choose form/survey providers.
- `[HUMAN]` Recruit beta testers / pilot partners; run the voluntary impact
  survey; obtain ethics oversight before any "research" framing.
- `[HUMAN]` Restart Claude Code to enable the live simulator panel (xcode-select
  fix already applied).
- Follow-up eng: rewrite the stale v1 accessibility UI-tests to the current UI.
