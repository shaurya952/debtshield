# Public Claims Register

_Every public claim (app, website, App Store, decks) with the evidence that
backs it. If a claim isn't here with a basis, don't make it. Challenge these
regularly (and hand them to reviewers)._

| Claim | Where | Basis / evidence | Status |
|---|---|---|---|
| "Your numbers never leave your phone" / on-device | App, site, store | No networking layer for personal data; privacy manifest (`NSPrivacyTracking=false`, no collected types); works in Airplane Mode | Verified |
| "No account, no bank connection, no ads, no tracking" | App, site, store | Source has no auth/URLSession/analytics/ads SDKs | Verified |
| "Data Not Collected" (App Store label) | Store | `PRIVACY_DISCLOSURE_WORKSHEET.md` + manifest | Verified |
| National rent ≈ $1,348/mo | App, site | U.S. Census ACS 5-yr (2019–2023) official figure | Verified (cite) |
| U.S. food avg ≈ $9,985/yr | App, site | BLS Consumer Expenditure Survey 2023 (all consumer units) | Verified (cite) |
| County rent/income from Census; energy from EIA (2024); food from BLS (2023) | App, site | Bundled datasets + `scripts/validate_datasets.py` | Verified (cite) |
| "Deterministic Ask — never invents numbers" | App, site | `PersonalChatEngine` is non-generative; unit tests | Verified |
| "The year ahead is a projection, shown with its assumptions" | App, site | Monte Carlo card shows assumptions; ranges (p10–p90) | Verified |
| "Delete everything in one tap" | App, site, store | `MoneyPlanStore.clear()`; scoped to user entries | Verified |
| "Educational, not financial/legal/tax/housing advice; no guaranteed outcomes" | Everywhere | Disclaimer in app + terms | Verified (must persist) |
| "Accessible: Dynamic Type, VoiceOver, WCAG-AA, Reduce Motion" | App, site | `ACCESSIBILITY.md` audit; ongoing checklist | Verified (maintain) |
| "Institutions never see individual financial data" | Site, partner docs | Architecture + business-model boundary | Verified (design) |

## Claims we must NOT make (until/unless true and evidenced)
- Any user count, activation %, retention %, or "users saved $X".
- "Prevents debt / eviction / bankruptcy."
- Named partners, advisers, testimonials, press, or awards.
- "Bank-level security" or absolute security guarantees.

## Process
- New public copy → add/verify its claims here first.
- Data/method change → update the basis here, the site, and the registry.
- Reviewers are invited to challenge any row (`ADVISER_REVIEW_PACKET.md`).
