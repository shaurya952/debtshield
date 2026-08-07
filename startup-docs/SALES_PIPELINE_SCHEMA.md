# Sales Pipeline Schema

_A tool-agnostic schema for tracking institutional conversations. Use any CRM or
a simple spreadsheet. Never store participants' financial data here — only
organization-contact info._

## Stages (definitions)
1. **Lead** — identified org that fits; not yet contacted.
2. **Contacted** — outreach sent.
3. **Discovery** — a call/meeting held; pain + owner + budget explored.
4. **Pilot proposed** — a tailored proposal sent (`PILOT_PROPOSAL.md`).
5. **Pilot signed** — agreement in place (paid or feedback-for-first-partner).
6. **Active pilot** — running.
7. **Renewal / license** — converted to an ongoing paid agreement.
8. **Closed-lost** — with a reason.

## Record fields
| Field | Notes |
|---|---|
| org_name | |
| org_type | college / nonprofit / workforce / employer / housing |
| contact_name, role, work_email | consented contact only |
| stage | one of the above |
| approx_participants | rough size band |
| owner_identified | yes/no (decision-maker) |
| budget_signal | none / exploring / has budget |
| next_step, next_step_date | always set one |
| pricing_option_discussed | from PRICING_EXPERIMENTS |
| privacy_questions_raised | track objections about data |
| source | referral / inbound / event |
| closed_reason | if lost |

## Hygiene
- Every open record has a **next step + date**.
- Log objections verbatim (privacy, budget, timing) to inform product/pricing.
- Report pipeline honestly (a "lead" is not a "customer"); see
  `METRICS_DEFINITIONS.md`.
