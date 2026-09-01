# Changelog

All notable changes to DebtShield. Dates are intentionally omitted in favor of
phase/commit references; see Git history for exact timing.

## Startup-hardening program

### Visual lift + pop-to-root navigation
- **Every screen sits on a soft, brand-tinted ambient backdrop** now (a faint wash at
  the top), with slightly richer card depth — a subtle, premium lift applied at the
  design-system level so it reaches every page without over-designing the calm look.
- **Re-tapping the active tab pops it back to its root** (per-tab navigation paths) —
  the standard iOS way to never get stuck deep in a section. No separate "home" button
  needed: the Home tab is home, and ‹ back steps up.

### A real product tour + visual polish
- **Rebuilt the onboarding as an animated product tour** with live-looking previews of
  the actual screens — the Home card, the metro ranking, the job-pay re-rank, the move
  plan, the privacy promise — each floating on a soft gradient with the app's own
  colours and shapes. It looks premium (not "half nice") and it teaches navigation, so
  new users don't get lost. Replayable from About; springs in, respects Reduce Motion.

### New icon, 3 tabs, and Headroom Pro
- **New app icon + in-app mark** — a white upward arrow rising into open space on an
  indigo→violet tile. The old blue shield read like antivirus / debt-settlement
  branding; this reads as "room, where your money goes further." Dropped the "AI"
  wordmark too.
- **About left the tab bar.** Three tabs now — Home, Places, Explain — with
  About / privacy / methodology opening from the Headroom logo on Home. The
  differentiator gets the nav real estate; the legal content is one tap away.
- **Headroom Pro** — a single, one-time unlock (StoreKit 2, no subscription) for two
  power features: compare places side by side, and an unlimited shortlist (free holds
  five). The whole core — your month, every ranking, all 116 jobs, the move plan —
  stays free, and nothing that touches distress is ever paywalled. Includes Restore,
  a bundled `.storekit` config for testing, and an honest, non-nagging paywall.

### Move Plan — a reason to come back
- **Goal reminders (opt-in).** Setting a move goal offers a gentle monthly nudge to
  log savings, and when an app update ships fresh cost data a saved goal gets a
  one-off "figures refreshed" alert — a real trigger, never a fabricated "rent rose"
  claim. All local, cancellable by clearing the goal.
- Pinning a place as your **move goal** (from its detail) unlocks a moving-fund
  tracker on Places: a progress bar toward a rough three-months'-rent fund, with
  quick +/− buttons to log what you've set aside. Turns a one-time "where would my
  money go furthest?" lookup into a trajectory — the honest retention hook,
  on-device like everything else.

### Metro areas — the keystone credibility fix
- **Ranking is now by metro area, not county, by default.** Ranking ~3,000 counties
  surfaced depopulating rural counties whose rent is low only because demand is (the
  "Woodruff County" problem), with ACS margins wider than the gaps being ranked. The
  new **Metros** tab ranks ~387 population-weighted Census CBSAs — real places people
  actually move to (the cheapest are now Johnstown PA, Weirton-Steubenville WV-OH, not
  ghost counties). States and Counties remain as tabs for the finer, less-certain view.
- Metro rent/income are **population-weighted rollups** of the member counties' Census
  figures, built from the official OMB county→CBSA delineation + Census population
  estimates. Bundled as `metro_data.csv`; the place lookup and move engine treat a
  metro exactly like a county, so the detail, cost card, and share card all work.

### Credibility + UX pass (more AI-review fixes)
- **BLS job-availability counts.** When you rank by a job, each state now shows about
  how many people hold that job there ("About 1,900 nurse jobs here"), amber-flagged
  when a state's high median rests on very few actual jobs — so a wage never implies
  work that barely exists locally.
- **Rounded money-left to the nearest $50** across the rankings, with a plain note
  that places within ~$50 are effectively tied and tiny counties carry more
  uncertainty — no more "+$3,373 vs +$3,370" false precision.
- **Moving isn't free.** The debt screen now leads with a break-even caveat (a move
  costs a few thousand up front and needs a job waiting), so "clears soonest" never
  reads as "just move."
- **Home decluttered:** cut the redundant verdict card (a quiet "what this means" link
  replaces it), removed the ambiguous "0%" badge, and renamed the affiliate-looking
  "Save & earn more" tile to "Free up more room."
- **Safe Line bar** now carries a full legend, so every segment is named, not just the
  wide ones.
- **"Ask" → "Explain"** (honest about the deterministic engine), grouped the job picker
  by category with a "Popular" shortlist and top search, and softened doom-y prompts.
- **Shareable card:** any place's detail can now export a designed summary image
  ("+$X left each month here", current-vs-there, honest "estimate, not a recommendation"
  footer) — the tell-a-friend moment.

### The hook is the front door
- **Places is now the landing tab** for anyone who's already entered their numbers,
  so the differentiator — where your money (or your job's local pay) goes furthest —
  is the first thing you see, not a generic budget dashboard. A brand-new user with
  no numbers still starts on Home, so the "how close am I?" first step is untouched.
- **The job-pay ranking is no longer buried behind "Change."** When you're ranking by
  your own pay, a prominent accented card — "See where your job pays furthest · rank
  by your career's local pay, 116 jobs" — invites the one thing no other
  cost-of-living tool does.

### Renamed the product: DebtShield → Headroom
- All four external reviews said the name works against the app — "DebtShield" + a
  blue shield read like debt-settlement / credit-repair marketing, the exact industry
  the app's ethics avoid, and it under-sells the cost-of-living pivot. Renamed the
  user-facing product to **Headroom** (already the app's own word — "you've got room").
- Changed the display name and every in-app string/label. **Bundle id, target, scheme
  and all `debtshield.*` persistence keys are unchanged**, so existing installs keep
  their data and the TestFlight/App Store Connect record stays intact.
- Still to do (human/design): a new app icon (retire the shield) and the App Store
  listing name. Website rename follows once the name is confirmed.

### Data-honesty pass (from external review feedback)
- **Fixed a utilities double-count.** The place projection used Census *gross* rent
  (which already includes utilities) as housing **and** added a separate EIA energy
  cost on top — inflating every "money left" figure and ranking. Utilities now live
  inside the gross-rent figure and are never added again. "Max rent" / "income needed"
  now account for all other essentials (transport, personal, upkeep), not just food+debt.
- **Softened over-confident verdicts.** "You could afford to live here" → "Your basics
  would fit here," with a standing note that transport, state taxes, insurance and the
  cost of moving aren't included yet — perspective, not a full affordability check.
- **Rounded estimates to the nearest $50** ("about $1,700") to stop implying dollar-exact
  precision the typical-data model doesn't have.
- **Renamed "The fastest way out" → "Where debt clears soonest"** (calmer, less like
  debt-settlement marketing), and dropped the unprompted "What are my odds of going into
  debt?" suggestion chip (the year-ahead odds are still there if asked).
- **Cost cards** now show one "Rent — utilities included" row instead of rent + a
  separate additive-looking utilities row, and say plainly which costs don't vary by place.
- Methodology + sources copy updated to disclose the gross-rent/utilities relationship
  and the excluded costs. Engine suite still 99 passing.

### State-level costs + faster "fastest way out" (polish round 3)
- **State cost card.** Drilling into a state now opens with "Typical costs in
  [State]" — the state's median county rent and its utilities, each vs the U.S.
  average — before the county list, which is now clearly headed "Specific costs by
  county." Costs live at both levels now, not only in the county detail.
- **"The fastest way out" no longer freezes on open.** Ranking the whole country
  and running the baseline payoff Monte Carlo now happen off the main thread with a
  brief "working it out…" state, so the screen pushes instantly instead of hitching.
- Shared `CostVsUSRow` so the state summary and county detail render identically.

### 116 jobs + calmer Places header (polish round 2)
- **116 occupations** (up from 64) in "same job, new place" — from CEOs to home
  health aides, diesel mechanics, sonographers, bookkeepers, painters, and more,
  all real BLS OEWS 2023 state medians (only jobs reported in ≥40 states are kept).
- **Decluttered the "Rank by" control.** It's now one compact card — an icon with
  "Ranking by / My pay" and a clear **Change** affordance, with the income field (or
  the job note) tucked under a divider — instead of a stacked header + button + field.
- Tightened the Places intro line.

### More jobs, per-place cost breakdown, searchable picker (polish)
- **64 occupations** (up from 24) in "same job, new place" — a much broader, more
  relatable set (nurse practitioner, firefighter, welder, architect, EMT, chef,
  real-estate agent, …), still real BLS OEWS 2023 state medians.
- **Searchable job picker.** With 60+ jobs, the menu became a sheet with search —
  "My pay" on top, jobs below, type to filter. Cleaner than a long scroll.
- **"Cost of living here" card** in each place's detail: how the basics compare to
  the U.S. average — Housing (this county's rent) and Utilities (this state's) with
  a plain "X% higher/lower than the U.S." read, plus an honest note that food /
  getting-around / personal costs don't vary by place in the data. Brings the old
  Compare view's spirit *into* Places, localized. The affordability card was slimmed
  to "What you could afford" (max rent + income needed).

### Declutter — fewer tabs, calmer Places (post-pivot cleanup)
- **Four tabs, not five.** Dropped the **Compare** tab (the generic "your categories
  vs the U.S." view) — it clashed with **Places** and made the bar crowded. Tabs are
  now Home · Places · Ask · About. (`CompareView` kept in the codebase, just untabbed.)
- **Home is lighter.** Removed the "Could you move?" tile — it only duplicated the
  Places tab.
- **Places reads calmer.** One-line intro and a compact "Rank by" control instead of
  the long paragraph + subtitle. UI tests updated for the new tab set.

### "The fastest way out" — debt-free-by-place (Phase 10, the capstone)
- **The feature that fuses everything and brings it home to debt.** Enter a debt
  balance + rate and a new screen ranks where your debt would clear **soonest** —
  because a cheaper place (or a better-paying local job) frees up money, and every
  spare dollar clears debt faster. Each place shows months-to-debt-free, a **Monte
  Carlo range** on the payoff time, and how much sooner than staying put.
- `DebtFreedomEngine` (`Core/DebtFreedom.swift`): deterministic payoff + seeded MC
  range; interest counted only when a rate is given (else it says so); a payment
  that can't overtake interest reads "not in reach", never a fake number. It ties
  together the affordability engine, the mobility/occupation pay, the Monte Carlo
  engine, and the app's original debt mission — deterministic on real data, so it's
  something no budgeting app or chatbot can produce.
- `MoneyPlan` gains optional `debtBalance` / `debtAPR` (graceful migration, new
  inputs in the Debt section). Entry from a Places card shown once a balance exists.
- `DebtFreedomEngineTests`; bands in `THRESHOLD_REGISTRY.md`. Suite 99 passing;
  verified on-device.

### Compare two places + saved shortlist (Phases 8–9 of the relocation pivot)
- **Side-by-side "here vs. there" (Phase 8).** `ComparePlacesView` (opened from a
  toolbar button on Places) puts two places head-to-head — money left over,
  year-ahead risk, rent, energy, and most-affordable-rent — with a plain verdict
  ("in X you'd keep about $Y more a month"). Reuses `AffordabilityEngine` and the
  occupation context, so it respects "same job, new place". Verified on-device
  (LA County vs Knox County, TN → +$731/mo).
- **Saved shortlist (Phase 9).** A ★ on any place detail saves it to a shortlist
  (`Core/SavedPlaces.swift`, on-device in `debtshield.savedPlaces`); a new **Saved**
  tab on Places re-scores and ranks your candidates with the current pay. Verified
  on-device.

### "Same job, new place" + methods page (Phases 4–5 of the relocation pivot)
- **Occupation-aware pay (Phase 4).** Pick your job and the ranking uses that
  occupation's *local* median wage in each state (`Core/OccupationWages.swift`,
  bundled `Resources/occupation_wages.csv` — real **BLS OEWS May 2023** state
  medians, 24 curated occupations × 51 states) instead of one flat income —
  answering "where would my career go furthest?" A state where the job isn't
  reported is left out, never guessed. Gross wage → estimated take-home via a
  single documented ratio (`takeHomeRatio` 0.78), clearly labelled an estimate.
  The ranking engines gained an `incomeByState` option threaded through Places.
  `OccupationWagesTests`; verified on-device (Family Physician → Nebraska #1).
- **Methods & sources page (Phase 5).** `MethodologyView`, linked from About —
  what Places does, where every figure comes from (Census / EIA / BLS OEWS), how
  the ranking and Monte Carlo risk work, and, plainly, what it can't tell you.
  The credibility layer for the pivot.
- Full suite 92 passing.

### Place risk — the second axis (Phase 3 of the relocation pivot)
- **Monte Carlo risk per place.** `PlaceRiskEngine` (`Core/PlaceRisk.swift`) runs
  the existing simulation on the budget you'd have *living there*
  (`MoveOutlook.projected`) and reads `probNegativeWithin12mo` — the odds of
  running short over the year — banded low / watch / high. A cheap-but-fragile
  county is now flagged, not hidden.
- Each ranked county shows a calm risk chip alongside its money-left; computed off
  the main thread per visible row (seeded 42, 300 runs, so it never flickers).
- Bands documented in `THRESHOLD_REGISTRY.md`. `PlaceRiskEngineTests` (5); full
  suite 87 passing; verified on-device.

### Places screen — states + counties (Phase 2 of the relocation pivot)
- **New `Places` tab**, the relocation hero: ranks where the person's real numbers
  would leave the most breathing room. Two levels — **States** (the big picture,
  "which states stretch my money") drilling into **Counties** (the specific spot),
  each county opening the existing full affordability picture (`MoveView`).
- States rank on `StateRankingEngine` (`Core/StateRanking.swift`) — a rollup that
  groups the county results by state and ranks by the **median** county's
  money-left (robust to one unusually cheap/pricey county), carrying each state's
  best county and affordable-county count. Deterministic; `StateRankingEngineTests`.
- Pay control lets the person model a different salary and re-rank the whole map.
- `MoveView` gains `initialFIPS`/`initialIncome` so a ranked place opens straight
  into its detail. Full suite 82 passing; verified on-device (Arkansas #1 rollup,
  drill-in to Woodruff County).

### Relocation ranking engine (Phase 1 of the relocation pivot)
- **`PlaceRankingEngine` (`Core/PlaceRanking.swift`).** Promotes the single-place
  `AffordabilityEngine` into a whole-country ranking: given a plan, it runs the
  same deterministic affordability math across every county in the `Dataset` and
  ranks them by projected money-left-over ("breathing room"). Pure, synchronous,
  no SwiftUI — headlessly testable like the other engines.
- Options: `incomeOverride` (model a new salary), `minMonthlyLeft` (affordability
  floor), `stateFilter` (region), `limit`. Counties with no rent data are skipped,
  never guessed; order is deterministic with a FIPS tie-break.
- Tests: `PlaceRankingEngineTests` (8) — ranking order, filters, skips, income
  override, determinism/tie-break. Full suite 78 passing.
- Groundwork for the "become a cost-of-living relocation tool, not a budgeting
  app" restructure; UI (the Places screen) is a later phase.

### Beta feedback — spending categories, Utilities & clearer entry
- **New everyday costs, from tester feedback.** Added home upkeep, transportation
  ("Getting around"), and personal/lifestyle spending, each with an ⓘ button that
  lists exactly what to include — so a grouped cost is never a guessing game.
- **Water folded into one "Utilities" cost.** Rather than a separate water line,
  the app now collects a single Utilities figure (electricity, gas, water, sewer,
  trash). Housing stays on its own — lumping it into "rent" would hide where the
  money goes and break every comparison. A plan saved before the merge folds its
  separate water bill into utilities on load (`MoneyPlan.init(from:)`); nothing
  is lost.
- **Real, cited U.S. comparisons for every new category.** Transportation, personal,
  and home upkeep compare to BLS Consumer Expenditure Survey 2023 figures; the
  Utilities comparison is EIA electricity (state, national fallback) **plus** the
  BLS gas + water average, so a whole bill is measured against a whole-bill typical.
  All figures documented in `THRESHOLD_REGISTRY.md`.
- **Friendlier entry screen.** Sectioned into "Your home" / "Everyday costs" / "Debt"
  with a small tinted hint pointing at the ⓘ buttons. Friendlier labels
  ("Food & groceries", "Getting around", "Utilities").
- **Ask fix.** Utility questions (water, gas, trash, "utilities") now route to the
  combined Utilities cost; unmatched questions decline honestly instead of
  returning a stray status summary.

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

### Visual polish — Compare (deeper pass)
- Each comparison card now leads with a colored amount + "You pay" label, a bold
  glowing **"You" bar** that stands out from the muted reference bars, and a
  glanceable **status pill** (icon + word — Higher / Typical / Lower /
  Comfortable / High / Watch) next to the plain-language verdict.
- The "big picture" summary gets an app-icon badge (green seal when nothing's
  high, chart when something is). No behavior change.

### Ask engine — new deterministic intents
- Expanded `PersonalChatEngine` (still deterministic, on-device, no network/AI)
  with four computed-from-your-numbers question types:
  - **Cushion / emergency fund** — the 3–6-month-of-essentials guideline and how
    long the current surplus would take to build it;
  - **Savings rate** — what you keep each month, as dollars, a share of income,
    and an annual pace;
  - **Debt burden** — debt payments as a share of income, with the 20% / 36%
    rules of thumb (and 211 when heavy);
  - **Annual projection** — this month's surplus/deficit across 12 months.
- All framed as heuristics, not advice; advice questions still redirect to 211/HUD.
- Surfaced "How's my cushion?" / "How much goes to debt?" as quick prompts.
- Added `PersonalChatEngineTests` (10 tests: intents, determinism, decline
  boundary, needs-numbers) — engine suite now 61 tests, all passing.

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
