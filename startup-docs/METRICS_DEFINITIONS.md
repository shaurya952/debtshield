# Metrics Definitions

_The single source of truth for what each metric means. No vague or inflated
metrics. Every value reported anywhere must trace to a definition here and carry
its **time period, data source, verification status, and last-updated date**.
No numbers are recorded in this file — only definitions._

## Honesty rules
- **Never conflate** a website visitor, a download, and an activated user.
- **Self-report ≠ behavior ≠ causation.** Label which one a number is.
- A metric with no reliable source is **"not measurable yet"**, not zero-that-
  looks-like-success and not an estimate presented as fact.
- Because the app is private and on-device, most in-app behavior is **not
  observable** unless the user volunteers it (survey) or opt-in analytics is
  later added (Phase 7, not implemented). Say so rather than guessing.

## The funnel
| Metric | Definition | Source | Observable today? |
|---|---|---|---|
| Website visitor | A unique visit to the marketing site in a period | Privacy-respecting host/server logs, if any | Only if the host provides it; no in-page tracker |
| Waitlist registration | A completed beta-waitlist form submission | Form endpoint store | Yes, once `FORM_ENDPOINT` is set |
| Pilot inquiry | A completed institutional pilot form submission | Form endpoint store | Yes, once configured |
| Reviewer inquiry | A completed reviewer form submission | Form endpoint store | Yes, once configured |
| Download | An App Store download (first-time) | App Store Connect | Yes, at launch |
| Activated user | Downloaded **and** completed onboarding (created a local profile) | Not observable on-device; **self-report or opt-in analytics only** | No (by design) |
| Completed first financial plan | Entered enough numbers for a verdict at least once | Self-report / opt-in only | No (by design) |
| Viewed simulation | Opened "The year ahead" at least once | Self-report / opt-in only (a local flag exists on-device, not transmitted) | No (by design) |
| Viewed comparison | Opened Compare at least once | Same as above | No (by design) |
| Returned user | Opened the app in a later session | App Store Connect gives aggregate active devices; per-user not observable | Partial (aggregate only) |
| Second-month user | Completed a plan in two distinct calendar months | Self-report / opt-in only (on-device retention state) | No (by design) |
| Self-reported useful action | Reported taking a concrete step (see Impact study) | Voluntary survey | Only via survey |
| Pilot participant | An individual enrolled through a partner campaign | Aggregate partner enrollment count only; never individual financial data | Aggregate only |
| Paying organization | An org with a signed, paid agreement | Contracts / invoices | Yes |
| Retained organization | A paying org that renews for another term | Contracts | Yes |

## Reporting format (required for any figure)
```
<metric>: <value>
  period: <e.g. 2026-Q3>
  source: <where it came from>
  type: observed | self-reported | aggregate | contractual
  verification: verified | provisional | estimate
  last-updated: <YYYY-MM-DD>
```

## What we will NOT claim
- Activation/retention percentages derived from downloads alone.
- "Users saved $X" or "prevented debt" — not measurable and not promised.
- Any partner, adviser, or revenue that is not contractually real.
