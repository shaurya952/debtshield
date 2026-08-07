# Scale Architecture

_How DebtShield grows without betraying its privacy model or over-building.
Guiding rule: **add infrastructure only when a real need forces it.** Avoid
premature microservices, databases, and AI. Keep Ask deterministic unless a
separately approved, safety-reviewed change says otherwise._

## Invariants at every stage
- **No backend for personal financial data.** Ever. Financial data stays
  on-device; there is no store to scale, breach, or migrate.
- Institutions never see individual data (`startup-docs/CUSTOMER_DATA_BOUNDARIES.md`).
- Accessibility and honesty are not traded for growth.

## Stages
### Stage A — 20–100 beta testers (now)
- **Components now:** the iOS app (on-device); a zero-dependency static website;
  waitlist/pilot/reviewer forms via a privacy-conscious provider; voluntary
  survey via a survey tool; CI (tests, data validation, secret scan, website).
- **Postponed:** any server for app data, partner portal, analytics.
- **Ops:** manual partner coordination; feedback via in-app copy + email.

### Stage B — 100–1,000 users
- **Add:** App Store launch; a few pilot partners; stronger CI; verified
  aggregate impact reporting; a real support address + queue.
- **Maybe:** a *minimal* partner touchpoint (still no individual data).
- **Postponed:** custom backend, databases for app data (none needed).

### Stage C — 1,000–10,000 users
- **Add:** repeatable partner onboarding; a reliable annual data-update pipeline;
  a light **partner portal** *only if* real pilots need it (aggregate-only,
  RBAC); independent **security review** and an **accessibility review**;
  business-continuity docs.
- **Data pipeline:** scripted refresh of bundled Census/EIA/BLS data with
  validation (extends `scripts/validate_datasets.py`), shipped as an app update.

### Stage D — 10,000+ users, multiple orgs/regions
- **Add:** an operational team with real responsibilities; formal SLAs;
  independent security testing; mature incident response; reliable support
  workflows; possibly localization/expansion.
- **Still no** personal-finance backend. If new features tempt one, re-derive
  them on-device first.

## Scaling triggers (build X only when Y)
| Build | Trigger |
|---|---|
| Partner portal | A signed pilot actually needs self-serve setup / aggregate reports |
| Opt-in analytics (Option B) | A documented question surveys+Apple aggregates can't answer (`ANALYTICS_DECISION.md`) |
| Data-refresh automation | Manual updates become error-prone or too frequent |
| Support tooling | Email volume exceeds what one person can handle |
| Backend of any kind | A feature genuinely can't be done on-device **and** doesn't touch personal financial data |

## Risks & mitigations
- **Operational:** single-founder/key-person → documentation (this repo),
  dependency-light stack, runbooks; hire before Stage C.
- **Security:** more surfaces (portal, forms) → keep them aggregate/contact-only;
  secret scanning; independent review by Stage C; incident plan.
- **Cost:** keep hosting static and cheap; no per-user data servers; watch
  survey/form provider costs; annual data-refresh labor is the main cost.
- **Vendor lock-in:** form/survey/analytics providers are behind seams (config
  `FORM_ENDPOINT`; analytics `NoOp` seam) so they can be swapped/removed;
  website is portable static HTML; avoid proprietary frameworks.

## Migration paths
- **Website:** static HTML → move to Astro/Eleventy later with no content
  lock-in, or to any static host.
- **Forms/surveys:** swap providers by changing config; data export honored per
  the data policies.
- **Partner portal (if built):** start minimal (aggregate + RBAC); it holds no
  individual financial data, so migration risk is low.
- **iOS:** engines are pure and headlessly testable, easing refactors and any
  future platform expansion.

## Anti-goals (say no to these unless truly forced)
- Microservices before a monolith/static site strains.
- A database for app data (there is none to store server-side).
- Generative AI in Ask (keep it deterministic; safety-review any change).
- Bank connections, ads, or data monetization — off the table permanently.
