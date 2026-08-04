# DebtShield — Phase 0 Audit Report

_Last updated: Phase 0. Auditor: engineering (AI-assisted). Basis: direct
inspection of the repository at commit `60d3436` (tag `checkpoint/pre-phase-0`)._

## 1. Current architecture (as-built)
- **Client:** native SwiftUI app, iOS 17+, Xcode 16, one application target
  (`DebtShieldAI`) plus one UI-test target (`DebtShieldAIUITests`).
- **Pattern:** `Core/` holds pure, `SwiftUI`-free calculation engines and models;
  `Views/` holds the UI. Engines are deterministic and headlessly testable.
- **State/persistence:** `MoneyPlanStore` + `@AppStorage`/`UserDefaults` under
  `debtshield.*` keys. No database, no network for personal data.
- **Data:** three bundled CSVs (Census county rent/income, EIA state energy, BLS
  food-by-income) loaded by `CSVLoader`/`BenchmarksLoader`, plus hardcoded
  official national figures.

## 2. Functioning features (verified in build + simulator)
Onboarding (landing → local sign-up → skippable feature tour); Home dashboard
(hero, verdict banner, 4 tiles, edit); The Year Ahead (Monte Carlo odds, CI,
sensitivity, transparency); Your Spending; Where You Stand; Compare (3-bar,
Census/EIA/BLS); Ask (deterministic); Could You Move? + Place detail;
Save & earn more (education + free help). Builds green in Debug and Release.

## 3. Strengths (do not "fix")
- **Engines are robust.** All income-denominated divisions guard `income > 0`
  (`MoneyPlan.share/moneyLeft/essentialsShare`, `Situation`, `CostComparisons`).
  Monte Carlo variance guards `samples.count >= 2`; `gaussian` guards `sd > 0`.
- **Determinism.** Monte Carlo uses a fixed seed and runs off the main thread.
- **Privacy posture is real.** No networking of personal data; comparison data is
  bundled. `@AppStorage` only.
- **Citations present** throughout (Census 2019–2023, EIA, BLS CE 2023).
- **Accessibility groundwork**: Theme tuned for WCAG-AA, Dynamic Type, VoiceOver
  labels, Reduce Motion; a UI-test target already probes contrast/accessibility.

## 4. Gaps / risks (ranked)
| # | Area | Finding | Severity |
|---|------|---------|----------|
| 1 | Tests | No **unit-test target** for engines; only UI tests exist. Monte Carlo/verdict/data logic is unverified by CI. | High |
| 2 | Privacy UX | No **app lock** (Face ID/Touch ID) and no **background-snapshot masking**; financial figures visible in the app switcher. | High |
| 3 | Data trust | CSV provenance/vintage/transform steps not fully documented; no **dataset validation script**. | High |
| 4 | Repo hygiene | Legacy v1 Python/Streamlit files + an **845 KB model `.pkl`** are tracked at repo root (`debtshield_streamlit_app.py`, `phase2_*.pkl/csv`, `week1_*.csv`). Not secrets, but dead weight and confusing. | Medium |
| 5 | Thresholds | Heuristics are named + commented but spread across three files; no single registry. | Medium |
| 6 | Trust surface | No in-app **Trust Center** consolidating privacy/methodology/limitations/delete-data. | Medium |
| 7 | Retention | No explicit **"start a new month / what changed"** retention loop or on-device reminder. | Medium |
| 8 | Logging | No structured logging; verify no financial values reach logs in Release. | Low |
| 9 | Localization | Strings are inline English; not yet `String(localized:)`-ready. | Low |
| 10 | Delete-data | A "Start over" clear exists in the edit sheet, but there is no prominent, always-available **"Delete all financial data"** in a settings/trust surface. | Medium |

## 5. Secrets / Git
No credentials, API keys, or signing certs found tracked. `.gitignore` covers
Xcode/userdata/build artifacts. The tracked legacy binaries (item 4) are a
cleanliness issue, not a security one.

## 6. Recommended order of work
1. **Phase 1 (safe hardening):** app lock + background-snapshot masking;
   prominent delete-all-data; confirm no financial values in Release logs.
2. **Phase 2:** central `THRESHOLD_REGISTRY.md` (done as doc) + an **XCTest unit
   target** with the edge-case matrix (zero/negative income, debt>income, no
   history vs ≥3 months, determinism, sensitivity monotonicity).
3. **Phase 3:** data dictionary + a dataset-validation script.
4. **Phase 4:** screen-by-screen accessibility pass + in-app Trust Center.
5. **Phase 5:** monthly retention loop.
6. Later phases (website, waitlist, portal, impact, App Store, CI, startup docs,
   revenue, scale) per `STARTUP_ROADMAP.md` — several require human/Apple/legal
   actions and are flagged there.

## 7. Repo-hygiene note (needs human OK before acting)
Removing the tracked v1 Python/model files would shrink and clarify the repo, but
it is a destructive history change; do it deliberately (checkpoint exists at tag
`checkpoint/pre-phase-0`). Not done automatically in Phase 0.
