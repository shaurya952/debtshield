# DebtShield — Threshold Registry

_Last updated: Phase 0._

Every configurable heuristic in the engines, in one place. These are **educational
heuristics, not universal financial facts** (see `CLAUDE.md`). Each is a named
`static let` with a doc comment at its definition — this file is the index and the
rationale. A future Phase-2 code task may consolidate these into a single
`Thresholds` namespace; until then, edit them at the cited source of truth.

## Safe Line & verdict (`Core/MoneyPlan.swift`)
| Name | Value | Meaning | Source of the number |
|------|-------|---------|-----------------------|
| `MoneyPlan.safeLineShare` | `0.55` | Essentials target as a share of income (dashed line). | Middle of the common 50–60% "essentials" guideline. |
| `MoneyPlan.comfortableCushion` | `1500` | Dollars left after essentials above which an over-the-line month is **not** called "tight". | Product heuristic; the one place ratio isn't the whole story. |

## Situation engine (`Core/Situation.swift`)
| Name | Value | Meaning | Source |
|------|-------|---------|--------|
| `SituationEngine.highDebtShare` | `0.20` | Debt payments worth watching. | Common non-housing-debt rule of thumb. |
| `SituationEngine.heavyDebtShare` | `0.36` | Debt payments read as "heavy". | Classic 36% total-debt ceiling. |

## Cost comparisons (`Core/CostComparisons.swift`)
| Name | Value | Meaning | Source |
|------|-------|---------|--------|
| `CostComparisons.typicalBand` | `0.10` | Within ±10% of typical reads as "about the same". | Product heuristic. |
| `CostComparisons.debtHealthyShare` | `0.20` | "Comfortable" debt line in Compare. | Rule of thumb. |
| `CostComparisons.debtHighShare` | `0.36` | "High" debt line in Compare. | Rule of thumb. |

## Monte Carlo (`Core/MonteCarloEngine.swift`)
| Name | Value | Meaning |
|------|-------|---------|
| `defaultRuns` | `500` | Simulated runs per horizon. |
| horizons | `6` and `12` months | Projection windows. |
| `incomeCV` | `0.07` | Income month-to-month coefficient of variation (national default). |
| `housingCV` | `0.03` | Housing CV (rarely changes). |
| `homeUpkeepCV` | `0.20` | Home-upkeep CV — steady tax/insurance, lumpy repairs. |
| `foodCV` | `0.15` | Food CV. |
| `energyCV` | `0.22` | Energy CV (seasonal). |
| `waterCV` | `0.10` | Water/sewer CV (fairly steady). |
| `transportationCV` | `0.18` | Transportation CV — gas swings, occasional repairs. |
| `personalCV` | `0.25` | Personal/lifestyle CV — the most discretionary, so the most variable. |
| `debtCV` | `0.05` | Debt-payment CV. |
| `surpriseChancePerMonth` | `0.15` | Probability of a surprise cost in a given month. |
| `surpriseMean` | `300` | Mean surprise cost (dollars). |
| `surpriseCV` | `0.5` | Surprise-cost spread. |
| personal-history trigger | ≥ 3 tracked months | Switches spread from national-default to the user's own measured variability. |
| seeds | `simulate` seed `42` (via callers), `sensitivity` seed `0xB1A5` | Deterministic reproducibility; sensitivity uses common random numbers across variants. |

## National reference figures (`Core/Benchmarks.swift`)
| Name | Value | Meaning | Source |
|------|-------|---------|--------|
| `officialNationalRent` | `1348` | U.S. median gross rent, monthly. | Census ACS 5-yr, 2019–2023 (official published figure). |
| `officialNationalFoodMonthly` | `9985 / 12` (~`832`) | Avg food spend, all U.S. households. | BLS Consumer Expenditure Survey 2023 (all consumer units). |
| `officialNationalTransportationMonthly` | `13174 / 12` (~`1098`) | Avg transportation spend, all U.S. households. | BLS CE 2023 (all consumer units). |
| `officialNationalPersonalMonthly` | `(2041+3635+927)/12` (~`550`) | Avg personal spend (apparel + entertainment + personal care). | BLS CE 2023 (all consumer units). |
| `officialNationalNaturalGasMonthly` | `540 / 12` (~`45`) | Avg natural-gas spend, all U.S. households. | BLS CE 2023 (all consumer units). |
| `officialNationalWaterMonthly` | `780 / 12` (~`65`) | Avg water & public-services bill, all U.S. households. | BLS CE 2023 (all consumer units). |
| `officialNationalUtilitiesAddonMonthly` | gas + water (~`110`) | The non-electric part of a home's utilities, added onto EIA electricity so a single "Utilities" entry compares to a whole-bill typical. | BLS CE 2023 (gas + water). |
| `officialNationalHomeUpkeepMonthly` | `(4079+3974)/12` (~`671`) | Avg home upkeep (property tax + maintenance/insurance/other) for a typical U.S. **homeowner**. | BLS CE 2023, home-owner tenure. |
| `nationalEnergy` | mean of state bills | Avg U.S. monthly electricity bill; the electricity part of the Utilities comparison. | Derived from EIA state file. |

**Utilities is one combined cost.** The app collects a single "Utilities" figure
(electricity + gas + water + sewer + trash). Its comparison = EIA electricity
(state, national fallback) **+** `officialNationalUtilitiesAddonMonthly`. A plan
saved before the merge (separate `water`) folds water into `energy` on decode
(`MoneyPlan.init(from:)`); `water` is retired going forward.

## Place risk — relocation ranking (`Core/PlaceRisk.swift`)
| Name | Value | Meaning | Source |
|------|-------|---------|--------|
| `PlaceRiskEngine.runs` | `300` | Monte Carlo runs per place (many places at once, so fewer than the Home forecast's 500). | Product heuristic; keeps the error band to a few points. |
| `PlaceRiskEngine.seed` | `42` | Fixed seed so a place's risk never flickers between views. | Determinism rule. |
| `PlaceRiskEngine.watchThreshold` | `0.15` | 12-month shortfall odds at/above which a place reads "Some risk". | Educational band, not universal truth. |
| `PlaceRiskEngine.highThreshold` | `0.35` | Shortfall odds at/above which a place reads "Higher risk". | Educational band. |

The risk is the ranking's second axis: `MonteCarloEngine.simulate` run on the
budget you'd have *living there* (`MoveOutlook.projected`), read as
`probNegativeWithin12mo`, then banded low / watch / high.

## Occupation pay — "same job, new place" (`Core/OccupationWages.swift`)
| Name | Value | Meaning | Source |
|------|-------|---------|--------|
| `OccupationWages.takeHomeRatio` | `0.78` | Gross annual OEWS wage → estimated monthly take-home (÷12 × ratio). A national-ish blend of federal + FICA + typical state tax. | Named heuristic; labelled "estimated" in the UI, never an exact paycheck. |

Wages themselves are **not** heuristics: `Resources/occupation_wages.csv` holds
real BLS OEWS May 2023 state **median** wages for a curated set of occupations. A
state where an occupation isn't reported is left out of the ranking, never guessed.

## Debt freedom — "the fastest way out" (`Core/DebtFreedom.swift`)
| Name | Value | Meaning | Source |
|------|-------|---------|--------|
| `DebtFreedomEngine.mcRuns` | `300` | Monte Carlo runs for the payoff-time range. | Product heuristic. |
| `DebtFreedomEngine.seed` | `42` | Fixed seed so a place's payoff estimate never flickers. | Determinism rule. |
| `DebtFreedomEngine.surplusCV` | `0.15` | Month-to-month wobble in what's actually free for debt. | Product heuristic. |
| `DebtFreedomEngine.surpriseChance` / `surpriseMean` | `0.15` / `300` | Odds and mean of a surprise cost eating into a month's payment. | Mirrors the Monte Carlo engine. |

Payoff assumes the person directs their **minimum payment + everything left over**
at the balance (`availableToward`). Interest is counted only when an APR is
entered; with no rate it says so rather than inventing one. A payment that can't
overtake the interest returns "not in reach", never a fake month count.

## Change protocol
1. Edit the `static let` at its source of truth and update this table.
2. Re-run the (Phase-2) engine unit tests — verdict-boundary and Monte Carlo
   tests are expected to move deliberately, never accidentally.
3. Never tune a threshold to make risk look more dramatic (`CLAUDE.md` rule 15,
   and the Monte Carlo "never manipulate assumptions" rule).
