# Adviser / Reviewer Review Packet

_What to send an expert reviewer (financial educator/counselor, accessibility,
privacy/security, or methodology). Reviewers are named publicly only with
explicit permission; we never fabricate advisers or endorsements._

## What to send
- One-paragraph overview + the honest disclaimer (educational, not advice).
- **Methodology:** `../methodology` on the site + in-repo threshold registry
  (`../THRESHOLD_REGISTRY.md`) and engine docs.
- **Data sources:** `../docs/BETA_FEEDBACK_SCHEMA.md` is not it — send the
  data-sources page + the datasets' vintages (Census 2019–2023, EIA 2024,
  BLS 2023) and the validation script (`../scripts/validate_datasets.py`).
- **Privacy:** `../SECURITY.md`, the privacy manifest, and the on-device model.
- **Accessibility:** `../ACCESSIBILITY.md`.
- **Public claims:** `PUBLIC_CLAIMS_REGISTER.md` (ask them to challenge any).
- TestFlight build (once available) or a screen recording.

## Questions to ask
- Are any thresholds or the verdict wording misleading or over-precise?
- Is the year-ahead presented responsibly (range + assumptions, not a promise)?
- Any claim that outruns its evidence?
- Accessibility gaps at large text / with VoiceOver?
- Privacy: any path by which financial data could leave the device?
- Is the free-help redirection appropriate and safe?

## How feedback is handled
- Log each item; triage into fixes vs discussion.
- Methodology/claim changes update the registry, the site, and
  `PUBLIC_CLAIMS_REGISTER.md`.
- Credit reviewers only as they permit; never imply endorsement they didn't give.
