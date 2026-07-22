# DebtShield AI — iOS Phase 1 Setup

Native SwiftUI rebuild. The Python/Streamlit app in the parent folder is untouched
and remains the reference implementation.

## Xcode project settings

| Setting | Value |
| --- | --- |
| Template | iOS ▸ App |
| Product Name | `DebtShieldAI` |
| Organization Identifier | your reverse-DNS, e.g. `com.shauryathakor` |
| Bundle Identifier | `com.shauryathakor.DebtShieldAI` |
| Interface | SwiftUI |
| Language | Swift |
| Testing System | Swift Testing (with XCTest UI Tests) |
| Storage | None |
| Host in CloudKit | unchecked |
| Minimum Deployments | **iOS 17.0** |
| Supported Destinations | iPhone, iPad |
| Device Orientation | Portrait + Landscape Left/Right (iPhone) |

iOS 17 is the floor because the app uses `@Observable` and current Swift Charts APIs.

## File layout

```
DebtShieldAI/
  DebtShieldAIApp.swift
  Core/
    Models.swift        — RiskLevel, DriverKind, CountyRecord, ScoredCounty, Dataset
    RiskScoring.swift   — Financial Distress Index (port of engineer_features)
    CSVLoader.swift     — bundle load, RFC-4180 parse, friendly DataError
    DataStore.swift     — @Observable load state machine
    Theme.swift         — light/dark colour system, spacing, tap-target constants
  Views/
    ContentView.swift   — TabView shell + load/error/skeleton routing
    DashboardView.swift — Phase 1 dashboard
    Components.swift    — RiskBadge, StatCard, Card, skeletons, error state
  Resources/
    real_county_data.csv
```

## Adding the CSV to the bundle

1. Drag `Resources/real_county_data.csv` into the Xcode navigator.
2. In the dialog: check **Copy items if needed**, select **Create groups**, and tick
   the **DebtShieldAI** target under "Add to targets".
3. Verify: select the project ▸ **DebtShieldAI** target ▸ **Build Phases** ▸
   **Copy Bundle Resources**. `real_county_data.csv` must be listed. If it is not,
   press `+`, choose the file, and add it.

The filename must stay exactly `real_county_data.csv` — `CSVLoader.resourceName`
looks it up by that name.

## Running

1. Select the **DebtShieldAI** scheme and an **iPhone 17** simulator.
2. `⌘R`.

## Acceptance criteria

These are verified against the Python pipeline and must match exactly:

| Check | Expected |
| --- | --- |
| Counties parsed | 3,144 (all U.S. counties, 50 states + DC) |
| Counties scored | 3,142 |
| Counties without enough Census data | 2 — Esmeralda County NV, Kenedy County TX |
| States | 51 |
| Average index (scored only) | 21.1 |
| Low risk | 2,928 |
| Medium risk | 213 |
| High risk | 1 |
| Highest-risk county | East Carroll Parish, Louisiana (69.2) |
| Autauga County, Alabama | index 15.9, housing 12.6, cost 20.9 |
| Measured drivers | Housing, Cost of Living |
| Effective weights | Housing 0.60, Cost of Living 0.40 |

## Phase 2 additions

Three new files to drag into Xcode (same target, **Create groups**):

```
Core/CountySearch.swift    — normalised search index over all 3,142 counties
Core/SelectionStore.swift  — @Observable selected-county state
Views/CountyPickerView.swift
Views/CountyProfileView.swift
```

Modified: `ContentView.swift` (adds the County tab), `DataStore.swift` (builds the
search index at load), `Models.swift` (adds `rank(of:)` / `percentile(for:)`),
`DashboardView.swift` (top-10 rows now open a profile).

### Phase 2 acceptance criteria

| Query | Expected first result |
| --- | --- |
| `cook illinois` / `illinois cook` | Cook County, Illinois |
| `st. louis` | St. Louis city, Missouri |
| `juneau` | Juneau City and Borough, Alaska |
| `dona ana` *and* `Doña Ana` | Doña Ana County, New Mexico |
| `east carroll` | East Carroll Parish, Louisiana |
| `autau` | Autauga County, Alabama |
| `new york` | New York County, New York — 60 shown of 62 |
| `zzzzz` | friendly empty state, no crash |

Worst-case keystroke latency measured at 3.4 ms against the full dataset.

## Phase 3 additions

New:

```
Core/FavoritesManager.swift    — saved + recently viewed, UserDefaults-backed
Core/ComparisonMetric.swift    — the eight compared indicators
Views/CompareCountiesView.swift
```

Edited: `SelectionStore.swift` (adds `ComparisonStore`), `ContentView.swift`
(Compare tab + store wiring), `CountyProfileView.swift` (star button, visit
recording, saved/recent lists), `CountyPickerView.swift` (saved/recent sections),
`Theme.swift` (comparison palette; `Double.scoreText` moved out),
`Models.swift` (receives `Double.scoreText`).

Local storage keys: `debtshield.favorites`, `debtshield.recentlyViewed` — FIPS
strings only, capped at 10 recents. No personal data, nothing leaves the device.

## Phase 4 additions

New:

```
Core/DriverBenchmark.swift     — national percentiles, severity, phrasing
Core/Recommendations.swift     — audience-aware recommendation engine
Views/RiskDriversView.swift
Views/RecommendationsView.swift
```

Edited: `Models.swift` (`benchmarks`, `standings(for:)`), `RiskScoring.swift`
(`DriverComponent`, `components(of:for:)`), `CSVLoader.swift` (builds benchmarks),
`ContentView.swift` (two new tabs).

### Why recommendations are percentile-based

The Streamlit rule fires at a driver score of 50. Measured on this dataset that
reaches 2 counties on housing and leaves 2,659 of 3,142 (85%) with nothing but a
generic monitoring line. Drivers whose sub-components have no data source
contribute zero, compressing the scale — housing's median is 10.5. Ranking each
driver against the national distribution instead: 1,216 counties (38%) have at
least one flagged driver, 785 are flagged on housing, and no county gets an
empty screen.

**Tab budget warning:** the app is now at 5 tabs, which is iOS's maximum before
a system "More" tab appears. Phase 5 must consolidate before adding Scenario
Simulator, Risk Map, Model Performance, Chatbot, and About.

## Phase 5 additions

New:

```
Core/ScenarioModel.swift            — inputs, fields, engine, explanation
Views/ScenarioSimulatorView.swift
```

Edited: `CountyProfileView.swift` — adds a `NavigationLink` to the simulator.

The simulator builds a modified `CountyRecord` and runs it through `RiskScoring`
rather than re-implementing the maths, so a simulated score can never drift from
a real one. An untouched scenario reproduces the county's real index exactly —
asserted in the test suite.

## Navigation restructure (after Phase 5, before Phase 6)

The tab bar is capped at **five for the life of the app** — iOS collapses
anything beyond the fifth into a system "More" list.

Current tabs: **Dashboard · County · Compare**

County is the hub for the selected county. Risk Drivers, Recommendations, and
Scenario Simulator are pushed from an "Explore" card there, since all three
operate on that one county.

Reserved for later phases:

- **Insights** — Risk Map (6), Model Performance (7), Ask DebtShield (8)
- **About** — methodology, glossary, disclaimer, privacy (9)

Neither is present yet; they arrive with their content rather than as empty
placeholders.

`RiskDriversView` and `RecommendationsView` now take a concrete `ScoredCounty`
instead of a `SelectionStore`. County Profile only offers the links for scored
counties, so their empty states were deleted rather than left as dead code.

## Phase 6 additions

New:

```
Core/StateGrid.swift       — tile layout, StateMetric, StateRiskSummary, shading
Views/RiskMapView.swift    — grid, legend, ranked list, state detail sheet
```

Edited: `ContentView.swift` (Map tab), `Theme.swift` (5-step map ramp).

### Why a tile grid and not a geographic map

A county map needs a centroid or boundary per county. `real_county_data.csv`
has FIPS codes but no coordinates, and no boundary file is bundled — plotting
counties geographically would mean inventing positions. The Streamlit version
hardcoded 18 centroids, silently omitting 3,124 counties.

The tile grid needs only a schematic layout, gives small states equal visual
weight, and makes every state a real tap target with a spoken label.

**To add a real map later:** drop a `fips,latitude,longitude` file into
`Resources` (Census TIGER publishes county centroids), extend `CountyRecord`
with the coordinate, and render a MapKit view alongside. Nothing blocks it.

### Shading is relative, not absolute

Every state's average index falls in the Low band (highest is Louisiana at
32.7, below the 35 threshold), so shading by risk level would paint the map one
colour. Bands are quintiles across the 51 states, and the legend says so.

## Phase 7 additions

New:

```
Resources/phase2_model_comparison_results.csv
Resources/phase2_feature_importance.csv
Core/ModelPerformance.swift        — loaders, metrics, interpretation
Views/ModelPerformanceView.swift
Views/InsightsView.swift           — hub for Risk Map + Model Performance
```

Edited: `ContentView.swift` — `.map` tab became `.insights`, routing to the hub.

The two model CSVs are read with the same `CSVLoader.parseTable` as the county
data, and each is loaded independently so a missing file degrades one section
rather than the screen.

### What the recorded results actually show

Reverse-engineering the confusion matrices from the reported precision and
recall gives a test set of ~250 counties with 12 positive cases, for all four
models. Consequences the screen states out loud:

- **Logistic Regression is best on every metric.** Random Forest — the model
  saved as `phase2_best_random_forest_model.pkl` — ranks 4th of 4 by F1.
- The gap between best and worst is **two counties** (12 of 12 found vs 10).
- **75.7% of feature importance** sits in `derived_*` sub-scores, which are what
  the Financial Distress Index is computed from, and the index is what produced
  the training labels. The near-perfect scores measure self-consistency.

### The .pkl file

Not loaded, and not loadable: pickle embeds Python class paths and needs a
Python interpreter plus the matching scikit-learn version. The Core ML
conversion path is documented in `ModelPerformanceLoader`'s doc comment.

## Phase 8 additions

New:

```
Core/Chatbot.swift        — ChatEngine, ChatMessage, ChatAnswer
Views/ChatbotView.swift
```

Edited: `InsightsView.swift` (third row + takes `searchIndex`/`selection`),
`ContentView.swift` (passes them through).

### Why it is not a language model

The requirement is that it must never invent a statistic. A generative model
cannot guarantee that. `ChatEngine` matches a question to an intent and then
**computes** every figure it quotes from `Dataset` and `ScoredCounty` at the
moment it answers — no number is written into a response string by hand. With
no intent, it declines and says what it can answer instead.

Verified by test: across 17 in-scope answers, every decimal appearing in a reply
is checked against the set of values the dataset can actually produce. Declines
are asserted to contain no figures at all.

Answers stay correct if the dataset is regenerated, including the methodology
answer, whose weights are read from `RiskScoring.normalisedWeights`.

## Phase 9 additions

New:

```
Core/Glossary.swift            — 12 terms, searchable
Views/OnboardingView.swift     — first-run introduction
Views/AboutView.swift          — fifth tab, hub for everything below
Views/GlossaryView.swift
Views/MethodologyView.swift
Views/DisclaimerView.swift
Views/PrivacyView.swift
```

Edited: `ContentView.swift` — `.about` tab, `@AppStorage` onboarding flag,
`fullScreenCover`.

**The tab bar is now complete at five.** Anything added later must be pushed
from one of them.

### Onboarding is one scrolling screen, not a carousel

Paged onboarding hides content behind a horizontal swipe: awkward with
VoiceOver, invisible to anyone who does not think to swipe, and it breaks at
large Dynamic Type sizes. Everything here is reachable by scrolling, and the
disclaimer sits above the button so it cannot be passed without being seen.
Shown via `fullScreenCover` with `interactiveDismissDisabled`.

### The privacy screen was written from an audit, not from assumption

Before writing a word, the source was checked for `URLSession`, `URLRequest`,
`CLLocation`, `NWConnection`, `AVCapture`, `UIPasteboard`, `WKWebView`, and any
analytics SDK — **none present**. Persisted keys were enumerated:

```
debtshield.favorites             FIPS codes
debtshield.recentlyViewed        FIPS codes, max 10
debtshield.recommendationAudience  "policymakers" | "residents"
debtshield.hasSeenOnboarding     Bool
```

The screen lists exactly these. If networking or storage is ever added, that
screen has to change with it.

### Methodology reads from the engine

Weights come from `RiskScoring.normalisedWeights` and counts from `Dataset`, so
the page cannot drift out of step with the scoring code.

## Phase 10 additions

New:

```
DebtShieldAIUITests/            — UI test target: interaction + accessibility audits
DebtShieldAI/Assets.xcassets/   — app icon (1024pt, opaque) + accent colour
DebtShieldAI/PrivacyInfo.xcprivacy
APPSTORE.md                     — submission guide, known issues, review notes
```

Edited: `project.pbxproj` (test target, icon, Info.plist keys),
`SelectionStore.swift` (persists the selected county), `PrivacyView.swift`
(lists the new key), plus contrast, clipping, and Dynamic Type fixes across
`Theme`, `Components`, `RiskDriversView`, `RiskMapView`, `ScenarioSimulatorView`,
`CountyProfileView`, `DashboardView`, `ChatbotView`, `CompareCountiesView`,
`OnboardingView`, `AboutView`, `CountyPickerView`.

**Read `APPSTORE.md` before submitting** — it lists what still needs changing
(bundle identifier, signing team).

Accessibility: the audit runs over every screen across all categories and
reports **zero findings**, down from 193. See `APPSTORE.md` section 8.

Tests: 11 UI tests passing with no skips, plus headless suites covering scoring,
search, favourites, recommendations, the scenario engine, the state grid, model
results, the chatbot, and the glossary.

## Project file

`DebtShieldAI.xcodeproj` uses Xcode 16+ file-system-synchronized groups, so any
file added under `DebtShieldAI/` is compiled automatically and any non-source
file is bundled automatically. There is no manual Copy Bundle Resources step.

## Known data limitations (surfaced in-app, not hidden)

`real_county_data.csv` carries 9 columns — income, gross rent, rent burden, poverty,
unemployment. It has no debt, energy, or food-access sources. The Python app's
dynamic weighting therefore drops those three drivers and renormalises to
Housing 0.60 / Cost 0.40. The Swift port reproduces this exactly, but additionally
marks unmeasured drivers as such instead of drawing them as identical bars for
every county.
