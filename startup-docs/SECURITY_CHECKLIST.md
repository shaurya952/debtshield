# Security Checklist

_Practical security practices. Complements `../SECURITY.md` (reporting) and
`../docs/RELEASE_CHECKLIST.md` (per-release)._

## Architecture
- [ ] No networking layer carries personal financial data (there is none).
- [ ] Personal data stays in on-device `UserDefaults`; privacy manifest accurate.
- [ ] Optional Face ID lock + background-snapshot masking present and working.
- [ ] One-tap delete removes only user entries; bundled data untouched.

## Secrets & repo
- [ ] No secrets/keys/certs committed (`scripts/scan_secrets.sh` in CI).
- [ ] `.gitignore` covers build artifacts, `node_modules`, `dist/`.
- [ ] Signing credentials never in the repo or CI logs.

## Dependencies
- [ ] App: no third-party runtime dependencies without documented value.
- [ ] Website: zero dependencies (Node stdlib only).
- [ ] Any new dependency is reviewed for need + supply-chain risk.

## CI / process
- [ ] CI runs engine tests, dataset validation, secret scan, website checks.
- [ ] Core tests gate merges (`ci-ok`).
- [ ] Changes reviewed (self-review checklist at minimum until a team exists).

## Website / forms
- [ ] Forms POST only to the configured `FORM_ENDPOINT` over HTTPS.
- [ ] Honeypot present; provider spam filtering on; minimal fields; no financial
      fields; consent required.

## Data handling
- [ ] Only contact-form data is collected (website), per `../docs/WAITLIST_DATA_POLICY.md`.
- [ ] Deletion path documented and honored.

## Incident readiness
- [ ] `INCIDENT_RESPONSE_PLAN.md` current; Sev-1 = any data-egress path.
- [ ] Regression test added after any security fix.

## Periodic (quarterly-ish)
- [ ] Re-run secret scan across history if concerned.
- [ ] Review `RISK_REGISTER.md`.
- [ ] Consider independent security review before larger scale (Stage C+).
