# DebtShield — Architecture

_Last updated: Phase 0._

## Layers
```
┌─────────────────────────────────────────────────────────────┐
│ Views/  (SwiftUI)                                            │
│   ContentView (tabs) · SafeLineView (home) · HomeDetailViews │
│   CompareView · PersonalChatView (Ask) · MoveView /          │
│   PlaceDetailView · BuildRoomView · MyNumbersView (edit) ·   │
│   OnboardingView (+ tour) · About/Privacy/HowItWorks · etc.  │
│   Components (Card, AppIconBadge, FeatureTile, …) · Theme     │
├─────────────────────────────────────────────────────────────┤
│ Core/  (pure Swift, NO SwiftUI import → headlessly testable) │
│   MoneyPlan · SituationEngine · TrajectoryEngine ·           │
│   MonteCarloEngine · AffordabilityEngine · CostComparisons · │
│   Benchmarks · PersonalAnswers (PersonalChatEngine) ·        │
│   MoneyPlanStore · DataStore · CSVLoader · CountySearch      │
├─────────────────────────────────────────────────────────────┤
│ Resources/  (bundled, read-only)                            │
│   real_county_data.csv · energy_by_state.csv ·               │
│   food_by_income_band.csv                                    │
└─────────────────────────────────────────────────────────────┘
```

## Data flow (personal — never leaves the device)
```
User taps Edit → MyNumbersView → MoneyPlanStore.save(MoneyPlan)
   → UserDefaults ("debtshield.moneyPlan", "debtshield.history", …)
   → SwiftUI observes store → engines recompute → Views render
```

## Calculation flow
```
MoneyPlan (income, housing, food, energy, debt)
  ├─ status / essentialsShare / moneyLeft        → hero + Safe Line bar
  ├─ SituationEngine.assess(plan, months)        → verdict (good…deep-in-debt)
  ├─ TrajectoryEngine.read(history)              → trend / early warning
  ├─ MonteCarloEngine.simulate(plan, history)    → year-ahead odds + CI
  ├─ MonteCarloEngine.sensitivity(…)             → biggest lever
  ├─ CostComparisons.all(plan, county, bench)    → Compare bars
  ├─ AffordabilityEngine.outlook(…)              → Could You Move?
  └─ PersonalChatEngine.answer(…)                → Ask (deterministic)
```

## Monte Carlo flow
```
simulate(plan, history, seed=42) on a detached task:
  build per-category Dist(mean, sd)
    ├─ usePersonal (≥3 months history): sd from personal samples (guarded ≥2)
    └─ else national-default: sd = mean × category CV
  for 500 runs × {6, 12} months:
    draw income & costs (Box–Muller gaussian, bounded), apply ~15%/mo surprise
    accumulate running balance; record if it ever goes negative
  → probNegative6/12, p10/p50/p90 ending balances, assumptions snapshot
sensitivity(): re-run with one category reduced; rank Δprobability.
```

## Benchmark flow
```
BenchmarksLoader.load() parses bundled CSVs once →
  EnergyBenchmark (by state) · FoodBenchmark (by income band) ·
  nationalRent 1348 · nationalEnergy (mean of states) · nationalFood 9985/12
CostComparisons matches the user's county/state/income to these.
```

## Boundaries
- **Privacy boundary:** every financial value (income, costs, verdict, odds,
  county affordability) stays inside the device sandbox. Nothing in `Core/` or
  `Views/` performs a network request with personal data. There is no networking
  layer for personal data at all.
- **Network boundary:** none in-app for personal data. Any future external
  interaction (website waitlist, opt-in analytics, feedback) must live behind an
  explicit, separately-consented, documented abstraction — never auto-attached to
  financial state. See `STARTUP_ROADMAP.md` Phases 6–9.
- **Testing boundary:** `Core/` imports Foundation only, so engines compile and
  run under a plain `swiftc` harness with no simulator. Views are exercised by the
  UI-test target and (future) snapshot/Dynamic-Type checks.
```
```
