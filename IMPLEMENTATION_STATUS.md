# DebtShield — Implementation Status & Session Handoff

_Living document + zero-context handoff. If you are a brand-new Claude Code
session with no conversation history, **this file plus `CLAUDE.md` is your
briefing.** Read both, then the "Files most important to understand" list, before
touching code. Update this file as work lands._

_Last verified: 2026-08-07 on branch `main` @ commit `9ac2991` (working tree
clean). Engine tests: **61 passing, 0 failures**. Xcode 26.6, iOS 17 SDK._

---

## 1. Current product state (what this is, right now)
DebtShield is a **working, releasable native iOS app** (SwiftUI, iOS 17+) plus a
**zero-dependency static marketing/trust website** and an extensive set of
startup/operations docs. It is a **privacy-first, on-device** personal finance
app that answers one question in plain dollars — *how does my money stand this
month, and where is it heading?* — with **no score, no grade, no judgment**.

- **No backend for personal financial data. No network calls with personal data
  at all.** Everything the user enters lives in `UserDefaults` on the device.
- County/national comparison data is **bundled** as read-only CSVs.
- The app builds green in **Debug and Release**; engines have a passing XCTest
  unit-test target; CI is **live and green** on GitHub (see §16).

**Functioning app features (all verified in build + simulator historically):**
Onboarding (landing → local sign-up → skippable feature tour); Home dashboard
(hero, verdict banner, 4 tiles, edit); The Year Ahead (Monte Carlo odds, CI,
sensitivity, transparency); Your Spending; Where You Stand; Compare (3-bar:
Census/EIA/BLS); **Ask** (deterministic, non-generative); Could You Move? +
Place detail; Save & earn more (education + free help links); in-app **Trust
Center**; optional **Face ID / passcode app lock**; **background-snapshot
masking**; prominent **"Delete my numbers"**; privacy-preserving **Send
feedback**; monthly retention ("Since last month" + opt-in reminder).

---

## 2. Current phase & exact roadmap position
The project runs a **16-phase startup-hardening program** (phases 0–16, defined
in `STARTUP_ROADMAP.md`). **All build-and-doc phases are complete: 0, 1, 2, 3,
4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16.** Phase **10** (institutional pilot
portal) is **deliberately deferred by design** until a signed pilot needs it
(building sooner would violate charter rule 13, "don't add premature
complexity").

Three phases are marked 🟡 because they have **code done but doc/verification
tails remaining** (details in §3–§4): **Phase 1** (log-hygiene audit doc),
**Phase 3** (data dictionary/sources docs), **Phase 4** (device VoiceOver walk),
and **Phase 5** (device-test the notification). No phase is blocked on code that
doesn't exist yet — what remains is mostly **human execution** (Apple submission,
GitHub push, website deploy, legal review, recruiting) plus a short list of eng
polish tasks (§17).

**Bottom line: the codebase is in a "ready to ship / ready to grow" state.** The
next real work is either (a) human go-to-market/launch actions, or (b) the small
eng follow-ups in §17, or (c) whatever new product direction the user requests.

### Phase table
| Phase | Title | Status | Notes |
|------:|-------|:------:|-------|
| 0 | Repository audit + foundational docs | ✅ | Audit/architecture/roadmap/registry/status + root `CLAUDE.md`. Safe checkpoint tag `checkpoint/pre-phase-0`. |
| 1 | Production hardening | 🟡 | ✅ Background-snapshot masking. ✅ Optional Face ID/Touch ID/passcode **app lock** (About ▸ Your data & security). ✅ Prominent **"Delete my numbers"** (`store.clear()`, bundled data untouched). **Remaining:** written log-hygiene/storage-protection note (code already avoids logging financial values). |
| 2 | Calculation & Monte Carlo validation | ✅* | `THRESHOLD_REGISTRY.md` done. XCTest target `DebtShieldAITests` — **61 tests, all passing**. Runner `scripts/test-engines.sh`. *Optional tail: ENGINE/MONTE_CARLO/ASSUMPTIONS methodology docs (methodology is currently disclosed in-app + on website). |
| 3 | Data pipeline & benchmark trust | 🟡 | `scripts/validate_datasets.py` passing (3,144 counties / 51 energy / 9 food bands, 0 warnings), wired into CI. **Remaining:** DATA_DICTIONARY / DATA_SOURCES / DATA_UPDATE_GUIDE docs. |
| 4 | UX, accessibility & Trust Center | 🟡 | Visual polish + **Trust Center** done. Accessibility audit done at largest Dynamic Type (AX5). UI-tests rewritten to current app. **Remaining:** physical-device VoiceOver walk-through. |
| 5 | Monthly retention | 🟡 | "Since last month" card (`MonthChangeEngine`), on-device `RetentionState`, opt-in non-manipulative monthly reminder (`MonthlyReminder` + `MonthlyCheckInCard`), all pure+tested. **Remaining:** device-test the local notification. |
| 6 | Privacy-preserving beta feedback | ✅ | In-app **Send feedback** (`FeedbackView`): type + note + opt-in device/a11y/features, live "exactly what will be shared" preview, copy-to-share, **no financial data ever, nothing auto-sent**. Pure `FeedbackReport` (+tests). Docs in `docs/`. |
| 7 | Opt-in analytics architecture | ✅ | `ANALYTICS_DECISION.md`: **Decision = Option A (no analytics SDK)**. Option B (strictly opt-in) fully specified as a future blueprint but **not implemented**. No app code added. |
| 8 | Public website (`/website`) | ✅ | Zero-dependency static site (15 pages). Build + link/meta/security checks pass. Deploy configs for Netlify/Vercel/Cloudflare + generated `dist/_headers` (strict CSP `script-src 'none'`, HSTS, etc.). **`[HUMAN]`:** set `SITE_URL`/`FORM_ENDPOINT`, deploy, add real contact, legal review. |
| 9 | Waitlist & pilot interest | ✅ | Three separate privacy-conscious forms (beta waitlist, institutional pilot, reviewer interest) — consent, honeypot, no financial fields, build-time `FORM_ENDPOINT` (shows "not connected" until set). `docs/WAITLIST_DATA_POLICY.md`. CI enforces consent+honeypot. **`[HUMAN]`:** choose provider, set `FORM_ENDPOINT`. |
| 10 | Institutional pilot portal | ⏸ Deferred (by design) | Boundaries specified (`SCALE_ARCHITECTURE.md`, `startup-docs/CUSTOMER_DATA_BOUNDARIES.md`). Build only when a signed pilot needs it. Aggregate-only, RBAC, never individual data. |
| 11 | Impact study | ✅ | Voluntary, anonymous pre/post survey design (no financial figures) in `docs/impact/`. `scripts/impact_summary.py` matches by anonymous code, small-n guard + **banned-column guard**, wired into CI. **`[HUMAN]`:** run via a survey tool; ethics oversight before "research" framing. |
| 12 | App Store launch system | ✅ | Launch kit in `docs/appstore/`. Complements `ios/APPSTORE.md`. **`[HUMAN]`:** bundle id + signing team, support email, screenshots, submit. |
| 13 | Automated testing & CI | 🟡 | Engine test target + `scripts/test-engines.sh`. GitHub Actions CI (`.github/workflows/ci.yml`) gated by `ci-ok`. PR/issue templates + `SECURITY.md`. **Remaining `[HUMAN]`:** push to a GitHub remote so Actions actually run. |
| 14 | Startup operations docs (`/startup-docs`) | ✅ | 24 docs + index (PRD, personas, positioning, business model, pricing, discovery, pilot, risk register, incident response, **METRICS_DEFINITIONS**, **PUBLIC_CLAIMS_REGISTER**). No fabricated traction. |
| 15 | Ethical revenue infrastructure | ✅ | LICENSING_MODEL, PRICING_TEST_PLAN, ORGANIZATION_REQUIREMENTS, CUSTOMER_DATA_BOUNDARIES, SAMPLE_PILOT_AGREEMENT_REQUIREMENTS (labeled drafts). Payments **not** activated. `[HUMAN]` attorney review. |
| 16 | Scale architecture | ✅ | `SCALE_ARCHITECTURE.md`: stages A→D, scaling triggers, deliberately-postponed components. Invariant: no personal-finance backend, ever; Ask stays deterministic. |

_Legend: ✅ done · 🟡 code done, doc/verify tail remains · ⏸ deferred by design ·
`[HUMAN]` needs a human/Apple/legal/partner action._

---

## 3. Completed vs partial vs not-started

### Completed
- The entire functioning iOS app (all features in §1).
- Engine unit-test target (`DebtShieldAITests`, 61 tests passing).
- Production hardening code: app lock, snapshot masking, delete-my-numbers.
- In-app Trust Center, privacy-preserving feedback, monthly retention loop.
- Dataset validation + impact-summary scripts, secret scan, full CI definition.
- 15-page website with deploy configs and security headers.
- All doc-only phases (7, 12, 14, 15, 16) and their supporting `startup-docs/`,
  `docs/`, `docs/appstore/`, `docs/impact/` sets.

### Partially completed
- **Methodology docs (Phase 2/3):** methodology *is* disclosed in-app and on the
  website, but standalone `ENGINE.md` / `MONTE_CARLO.md` / `ASSUMPTIONS.md` /
  `DATA_DICTIONARY.md` / `DATA_SOURCES.md` / `DATA_UPDATE_GUIDE.md` are not
  written. Nice-to-have, not a blocker.
- **Log-hygiene note (Phase 1):** code already avoids logging financial values;
  a short written audit/confirmation doc is missing.
- **Device verification (Phase 4/5):** VoiceOver walk-through and the local
  monthly-notification firing have not been checked on a physical device (only
  in code + simulator).

### Not started (intentionally)
- **Phase 10 partner portal** — deferred by design until a real signed pilot.
- **Opt-in analytics (Phase 7 Option B)** — deliberately not built; decision was
  "no analytics." Only build if the product owner reverses that decision.
- Any backend for personal data — **forbidden by charter**, never to be built.

---

## 4. Key facts a new session must not re-derive wrong

### Architecture (see `ARCHITECTURE.md`)
- **Two-layer app:** `Core/` = pure Swift (Foundation only, **no SwiftUI
  import**) so engines are headlessly testable; `Views/` = SwiftUI.
- **State/persistence:** `MoneyPlanStore` + `@AppStorage`/`UserDefaults` under
  `debtshield.*` keys. No database.
- **Determinism:** `MonteCarloEngine` runs off the main thread with a **fixed
  seed (42)**, 500 runs × {6, 12} months, Box–Muller gaussian. Results are
  reproducible — tests assert this. Do **not** introduce randomness without a
  seed.
- **Benchmarks** load once from three bundled CSVs via `CSVLoader` /
  `BenchmarksLoader` (`Benchmarks.swift`).

### Important architectural decisions
1. Engines stay pure and SwiftUI-free so `swiftc`/XCTest can run them without a
   simulator. Keep new calculation logic in `Core/`.
2. Thresholds are **named `static let`s** with doc comments, indexed in
   `THRESHOLD_REGISTRY.md`. They are **educational heuristics, not universal
   facts** — never present them as absolute truth, never inline magic numbers.
3. The **Ask** feature (`PersonalChatEngine` in `Core/PersonalAnswers.swift`) is
   **deterministic and non-generative** — it answers only from the user's entered
   figures + engines + bundled benchmarks, never fabricates numbers, and
   redirects loans/bankruptcy/benefits/serious distress to free resources (211,
   HUD). **Do not make it call an LLM or any network service** unless a
   separately-approved, safety-reviewed product change says so.

### Privacy decisions
- **No backend for personal financial data; nothing financial is ever
  transmitted off-device.** No bank connections, no ads, no analytics SDK, no
  payday/credit/debt-settlement/referral monetization.
- `PrivacyInfo.xcprivacy` declares **`NSPrivacyTracking = false`** and
  **`NSPrivacyCollectedDataTypes` empty** ("Data Not Collected"); the only
  required-reason API is UserDefaults (reason `CA92.1`). Every entry was checked
  against source — don't add a data type unless the app genuinely collects it.
- Background-snapshot masking + optional Face ID lock protect on-device data.
- Website transmits **no financial data**; forms have no financial fields, show
  "not connected" until `FORM_ENDPOINT` is set, and include consent + honeypot.

### Security decisions
- CI runs a **secret scan** (`scripts/scan_secrets.sh`); `SECURITY.md` defines
  private disclosure via GitHub Security tab. Never commit secrets/keys/certs.
- Website ships a **strict JS-free CSP** (`script-src 'none'`), plus HSTS,
  nosniff, frame-deny, permissions-policy, COOP — generated into `dist/_headers`.
  CI asserts the headers and that a set `FORM_ENDPOINT` origin is injected into
  `form-action` (and only then).

---

## 5. Files most important to understand
**Read these first (in order):**
1. `CLAUDE.md` — the permanent engineering charter / non-negotiable rules.
2. This file (`IMPLEMENTATION_STATUS.md`).
3. `ARCHITECTURE.md`, `AUDIT_REPORT.md`, `THRESHOLD_REGISTRY.md`.

**iOS app (`ios/DebtShieldAI/`):**
- `DebtShieldAIApp.swift` — app entry, scene phase, snapshot masking, app-lock.
- `Core/MoneyPlan.swift` — core model + Safe Line / verdict math + thresholds.
- `Core/Situation.swift` — verdict engine (`SituationEngine`).
- `Core/MonteCarloEngine.swift` — deterministic year-ahead simulation (~22 KB,
  the most complex engine).
- `Core/PersonalAnswers.swift` — `PersonalChatEngine`, the **deterministic Ask**
  (~34 KB; largest file; edit carefully, keep it non-generative).
- `Core/Benchmarks.swift` + `Core/CSVLoader.swift` — bundled-data loading.
- `Core/CostComparisons.swift`, `Core/Affordability.swift`, `Core/Trajectory.swift`.
- `Core/MoneyPlanStore.swift` — persistence + `clear()` (delete-my-numbers).
- `Views/ContentView.swift` — tab host; `Views/SafeLineView.swift` — home;
  `Views/PersonalChatView.swift` — Ask UI; `Views/TrustCenterView.swift`;
  `Views/CompareView.swift`; `Views/OnboardingView.swift`.
- `PrivacyInfo.xcprivacy` — App Store privacy manifest.
- Tests: `ios/DebtShieldAITests/*` (unit), `ios/DebtShieldAIUITests/*` (UI/a11y).

**Website (`website/`):** `build.mjs` (generator), `test.mjs` (checks),
`src/pages/*.html`, `src/layout.html`, `src/styles.css`, `netlify.toml` /
`vercel.json`.

**Scripts (`scripts/`):** `test-engines.sh`, `validate_datasets.py`,
`impact_summary.py`, `scan_secrets.sh`.

**Program docs:** `STARTUP_ROADMAP.md`, `CHANGELOG.md`, `ANALYTICS_DECISION.md`,
`SCALE_ARCHITECTURE.md`, `RETENTION.md`, `ACCESSIBILITY.md`, `SECURITY.md`,
`startup-docs/` (24 files), `docs/` + `docs/appstore/` + `docs/impact/`.

---

## 6. Build the iOS app
```bash
# Debug (from repo root)
xcodebuild -project ios/DebtShieldAI.xcodeproj -scheme DebtShieldAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```
```bash
# Release
xcodebuild -project ios/DebtShieldAI.xcodeproj -scheme DebtShieldAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Release build
```
Build **both Debug and Release** before declaring any phase done (charter rule).
Engines can also be compiled headlessly: copy the relevant `Core/*.swift` files +
a `main.swift` and run `swiftc -D DEBUG`.

- Scheme: **`DebtShieldAI`** (shared). Bundle id: `com.debtshield.DebtShieldAI`.
- Deployment target: **iOS 17.0**. Swift 5.0. `MARKETING_VERSION=1.0`, build `1`.
- **`DEVELOPMENT_TEAM` is unset** — signing is a `[HUMAN]` step for device/TestFlight.

## 7. Run the tests
```bash
# Engine unit tests (fast, pure logic). Uses iPhone 17 Pro by default.
scripts/test-engines.sh
```
```bash
# Override the simulator if 17 Pro isn't installed:
DEST='platform=iOS Simulator,name=iPhone 17' scripts/test-engines.sh
```
```bash
# Full xcodebuild form (what the script wraps):
xcodebuild test -project ios/DebtShieldAI.xcodeproj -scheme DebtShieldAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:DebtShieldAITests
```
Data/impact/secret scripts (also run in CI):
```bash
python3 scripts/validate_datasets.py
python3 scripts/impact_summary.py docs/impact/sample_responses.example.csv
bash scripts/scan_secrets.sh
```

## 8. Run / build the website
```bash
cd website
node build.mjs      # generate ./dist  (or: npm run build)
node test.mjs       # link/meta/security-header checks  (or: npm test)
npm start           # build + serve locally (serve.mjs)
```
Zero npm dependencies; needs Node ≥18. Optional build-time env:
`SITE_URL` (canonical/OG/sitemap) and `FORM_ENDPOINT` (wires the forms and
injects the endpoint origin into the CSP `form-action`). Without `FORM_ENDPOINT`
the forms render as "not connected" and CSP `form-action` stays `'self'`.

---

## 9. Most recent successful build/test results
- **2026-08-07:** `scripts/test-engines.sh` → **`** TEST SUCCEEDED **`,
  **61 tests, 0 failures** (MoneyPlan, Situation, MonteCarlo determinism/bounds/
  sensitivity, CostComparisons, FeedbackReport, MonthChange, RetentionState,
  PersonalChatEngine). Ran on booted **iPhone 17 Pro**, Xcode 26.6.
- App Debug + Release builds were green as of the pre-session state; the app
  compiles under Xcode 26.6 / iOS 17 SDK. (Re-run §6 to reconfirm after edits.)
- Website `node test.mjs` and the Python scripts pass locally and in the CI
  definition.

## 10. Known bugs
- **None currently known / open.** No failing tests, no crash reports. If you
  find one, add it here with a repro.

## 11. Known warnings
- No blocking warnings recorded. Expected environmental notes: signing/team
  warnings when building for a device (no `DEVELOPMENT_TEAM` set — see §6/§15).
  If new compiler warnings appear after an Xcode upgrade, record them here.

---

## 12. Failed approaches — do NOT repeat
- **Do not make Ask (`PersonalChatEngine`) generative / LLM-backed / networked.**
  It is deliberately deterministic. This is a charter rule, not an oversight.
- **Do not add a backend, bank connection, analytics SDK, or any off-device
  transmission of financial data.** Charter non-negotiables 1–5.
- **Do not remove the tracked legacy v1 files** (`debtshield_streamlit_app.py`,
  `phase2_*.pkl/csv`, `week1_*.csv`, `real_county_data.csv` at root, the
  `pull_real_county_data*.py`) without an explicit human OK — the audit flagged
  them as dead weight but removal is a destructive history change (safe
  checkpoint tag `checkpoint/pre-phase-0` exists). They are **not** the app; the
  app's data lives in `ios/DebtShieldAI/Resources/`.
- **Do not treat the `v2-teardown` branch as current.** It is a divergent
  experimental branch ("retire the county-analysis app", Steps 8–11) that
  *deletes* much of the website and app surface. `main` is the source of truth.
- **Do not present thresholds as universal financial facts**, inline magic
  numbers, or remove citations/methodology — repeatedly reinforced constraints.
- **Do not rewrite the working app** to "modernize" it (charter rule 13).

## 13. External credentials / services still needed
- **Apple Developer account + signing Team** (device builds, TestFlight, App
  Store). `DEVELOPMENT_TEAM` is intentionally blank.
- **GitHub remote** — none configured yet (`git remote -v` is empty). Needed to
  activate CI. Also install `gh` or set up an SSH key / PAT to push.
- **A form/survey provider** (Phase 9/11) — to set `FORM_ENDPOINT` and run the
  impact survey. None chosen.
- **Website host** (Netlify/Vercel/Cloudflare) + `SITE_URL`.
- **A real support/corrections email address** (site + Trust Center + review
  notes currently reference a placeholder).
- No API keys or secrets are required by the app itself (it has no network layer).

## 14. Human-only actions remaining
- `[HUMAN]` Create a GitHub repo + push `main` (activates CI). _(No remote is set;
  a `git push` today fails with "repository not found / access rights" — expected.)_
- `[HUMAN]` Own the bundle id, set the Apple signing Team, capture screenshots
  (`docs/appstore/SCREENSHOT_PLAN.md`), and submit to the App Store.
- `[HUMAN]` Choose a form/survey provider; set `FORM_ENDPOINT`; deploy the
  website; set `SITE_URL`; add a real contact address.
- `[HUMAN]` Attorney review of the legal drafts (terms, privacy policy, pilot
  agreement requirements) before any public/contractual use.
- `[HUMAN]` Recruit beta testers / pilot partners; run the voluntary impact
  survey; obtain ethics oversight before any "research" framing.
- `[HUMAN]` Physical-device VoiceOver walk-through + confirm the monthly local
  notification fires (Phases 4/5).
- `[HUMAN]` (Optional) Decide whether to delete the tracked legacy v1 files.

---

## 15. Git / branch info
- Default & working branch: **`main`**. Working tree **clean** at handoff.
- Current HEAD: **`9ac2991`** — _"Polish Compare visuals (status pills, focal
  'You' bar, colored amounts)."_
- Safe checkpoint tag: **`checkpoint/pre-phase-0`** (pre-program baseline; use it
  as the rollback point before any destructive change).
- Other branch: **`v2-teardown`** — divergent/experimental, **do not build on it**
  (see §12).
- Remote: **`origin` → https://github.com/shaurya952/debtshield** (public). CI runs
  there on every push/PR.
- **`main` is a protected branch** (ruleset "protect main"): direct pushes are
  rejected — changes must go through a pull request that passes the `CI passed`
  check before merging. Force-pushes and branch deletion are blocked. Work on a
  feature branch and open a PR.
- Charter rule: create a safe checkpoint (tag/branch) before any destructive
  change; keep the repo releasable after every phase.

## 16. CI status
`.github/workflows/ci.yml` defines five jobs gated by `ci-ok`: `datasets`
(validate + impact smoke test), `secret-scan`, `website` (build+test with and
without `FORM_ENDPOINT`), `engine-tests` (macOS-15, auto-picks an available
iPhone sim by UDID). **CI is live and green** at
https://github.com/shaurya952/debtshield/actions — all five checks pass on
every push to `main` and on pull requests.

---

## 17. Next 10 technical tasks (priority order)
These are the concrete eng follow-ups if continuing the program (most launch
progress is human execution, §14). Reassess against any new user request first.

1. **Write the Phase-3 data docs** — `DATA_DICTIONARY.md`, `DATA_SOURCES.md`,
   `DATA_UPDATE_GUIDE.md` (columns, vintages Census 2019–2023 / EIA / BLS CE
   2023, transform steps). Closes Phase 3.
2. **Write the Phase-1 log-hygiene / storage-protection note** confirming no
   financial values reach Release logs and describing on-device storage
   protection. Closes Phase 1.
3. **Write methodology docs** — `ENGINE.md`, `MONTE_CARLO.md`, `ASSUMPTIONS.md`
   (mirror in-app/website disclosures). Closes the Phase-2 doc tail.
4. **Re-run and record a full Debug + Release build** after the current Xcode
   26.6 toolchain; capture any new warnings into §11.
5. **Consolidate thresholds** into a single `Core/Thresholds` namespace
   referenced by the engines (registry §"future Phase-2 code task"); keep
   `THRESHOLD_REGISTRY.md` as the index. Update tests.
6. **Expand engine test coverage** for `AffordabilityEngine` and
   `TrajectoryEngine` (currently lighter than MoneyPlan/MonteCarlo); add
   edge-case matrix rows called out in the audit.
7. **Add a snapshot / Dynamic-Type UI test** that renders key screens at AX5 and
   asserts no clipping, to lock in the Phase-4 accessibility work in CI.
8. **Localization-readiness pass** — wrap user-facing strings in
   `String(localized:)` (audit gap #9), no behavior change.
9. **Verify the monthly local notification** end-to-end in the simulator/device
   and wire a lightweight test/harness around `MonthlyReminder`/`RetentionState`.
10. **Optionally scaffold Phase-7 Option B analytics behind the documented
    abstraction seam** (opt-in, 7 parameterless events, hard never-transmit
    list) — **only if the product owner decides to enable analytics**; otherwise
    leave as the documented blueprint.

---

## 18. What exists already (pre-program, verified)
- Working v3 iOS app (features §1), historically green Debug + Release.
- `Core/` engines pure & headlessly testable; Monte Carlo deterministic (seed 42).
- UI-test target with accessibility/contrast probes (`ios/DebtShieldAIUITests/`).
- Seed docs: `ios/APPSTORE.md`, `ios/PHASE1-SETUP.md`.
