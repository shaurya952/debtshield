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
| `nationalEnergy` | mean of state bills | Avg U.S. monthly electricity bill. | Derived from EIA state file. |

## Change protocol
1. Edit the `static let` at its source of truth and update this table.
2. Re-run the (Phase-2) engine unit tests — verdict-boundary and Monte Carlo
   tests are expected to move deliberately, never accidentally.
3. Never tune a threshold to make risk look more dramatic (`CLAUDE.md` rule 15,
   and the Monte Carlo "never manipulate assumptions" rule).
