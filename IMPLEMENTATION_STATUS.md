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
| 5 | Monthly retention | ⬜ | Start-new-month/carry-forward/what-changed/reminders. (A month rollover exists in `MoneyPlanStore.rollOverIfNeeded`; needs the full loop + UI.) |
| 6 | Privacy-preserving beta feedback | ⬜ | In-app feedback, never auto-includes financial data. |
| 7 | Opt-in analytics architecture | ⬜ | Decision doc first; not enabled by default. |
| 8 | Public website (`/website`) | ⬜ | Marketing/methodology/data/a11y/orgs/help/legal. |
| 9 | Waitlist & pilot interest | ⬜ | `[HUMAN]` provider choice. |
| 10 | Institutional pilot portal | ⬜ | Build only when a real pilot needs it; aggregate-only. |
| 11 | Impact study | ⬜ | `[HUMAN]` oversight; voluntary, anonymous. |
| 12 | App Store launch system | ⬜ | Partly seeded: `ios/APPSTORE.md` exists. `[HUMAN]` submission. |
| 13 | Automated testing & CI | 🟡 | Engine unit-test target + `scripts/test-engines.sh`. **GitHub Actions CI added** (`.github/workflows/ci.yml`): engine tests (macOS), dataset validation, secret scan, all gated by `ci-ok`. PR + issue templates, `SECURITY.md` added. Scripts verified locally. **Still needed:** `[HUMAN]` push to a GitHub remote so Actions run; optional deeper secret scanner. |
| 14 | Startup operations docs (`/startup-docs`) | ⬜ | PRD, business model, metrics, risk register, etc. |
| 15 | Ethical revenue infrastructure | ⬜ | Docs only until a real customer; `[HUMAN]` legal review. |
| 16 | Scale architecture | ⬜ | Staged A→D plan. |

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

## Next recommended phase
**Phase 1 — Production hardening**, starting with the two highest-value privacy
items: background-snapshot masking and an optional Face ID/Touch ID app lock,
plus a prominent, always-available "Delete all financial data" control. Then
**Phase 2**'s XCTest unit target for the engines.
