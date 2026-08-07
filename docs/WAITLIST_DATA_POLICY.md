# Waitlist & Pilot-Interest Data Policy

_Governs the three website forms: **beta waitlist**, **institutional pilot**, and
**professional reviewer**. This is website contact data — kept strictly separate
from the app, which stores financial numbers only on the user's device and
transmits nothing._

## The three intakes (kept separate)
| Form | Purpose | Fields collected |
|---|---|---|
| Beta waitlist | Notify individuals when the TestFlight beta opens | Email (required), first name (optional), category, consent |
| Institutional pilot | Follow up with organizations | Organization, contact name, work email (required), org type, approx. participant count, pilot interest, message, consent |
| Reviewer interest | Recruit expert reviewers | Name, email (required), role, organization, expertise, interest type, consent |

**No form asks for financial details** (income, rent, debt, verdicts, county, or
simulation results), and there is no way to attach them.

## Purpose limitation
Data is used only to respond to the request it was submitted for (beta invite,
pilot follow-up, review coordination). It is **not** sold, shared with
advertisers, or used to profile anyone.

## Retention
- Waitlist: kept until the beta invite is sent or the person unsubscribes,
  whichever comes first; then removed.
- Pilot / reviewer: kept for the duration of the conversation and any resulting
  engagement; removed on request or when no longer needed.
- Set concrete dates once a provider is chosen (below).

## Access
Limited to the DebtShield operator(s) handling intake. No third-party access
beyond the form provider that stores the submission on our behalf.

## Deletion
Anyone can request deletion by replying to any message from us or contacting the
address listed on the site (added at launch). We honor deletion promptly.

## Consent
Every form requires an explicit consent checkbox before submission and links to
the privacy policy. No pre-checked boxes; no bundled consent.

## Spam protection
- A hidden honeypot field (`company_website`); submissions with it filled are
  rejected server-side.
- The chosen provider's built-in spam filtering.
- No CAPTCHAs that harm accessibility unless strictly necessary.

## Security
- Forms post over HTTPS to the configured endpoint only.
- No secrets are stored in the site; the endpoint URL is injected at build time
  via the `FORM_ENDPOINT` environment variable.
- Server logs are minimized and used only for reliability/security.

## Implementation path (`[HUMAN]`)
Pick **one** at deploy time and set `FORM_ENDPOINT`:
1. **Privacy-conscious form provider** (e.g., Formspree, Basin, or Netlify
   Forms). Simplest; set the form action to the provider endpoint.
2. **Serverless endpoint** (Cloudflare Pages Function / Netlify / Vercel
   function) that validates the honeypot and forwards to email or a small store.
3. **Lightweight database** only if volume warrants it.

Until `FORM_ENDPOINT` is set, the forms render in a clearly-labeled
"not connected" state and submit nowhere.

## Honesty rule
We never claim the app collects nothing while quietly collecting form data. The
privacy page and every form state plainly that these website forms collect what
you type, separate from the app.
