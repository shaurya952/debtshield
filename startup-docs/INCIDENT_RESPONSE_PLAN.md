# Incident Response Plan

_What to do when something goes wrong. The worst-case for a privacy-first app is
any path by which personal data could leave the device — treat that as Sev-1._

## What counts as an incident
- **Sev-1:** Any actual or suspected transmission/exposure of personal financial
  data; a security vulnerability that could do so; a leaked secret/credential.
- **Sev-2:** A shipped bug that produces a materially wrong verdict/odds; a wrong
  bundled benchmark; a broken delete-data or app-lock control.
- **Sev-3:** A misleading claim published; an accessibility regression; a website
  form mishandling contact data.

## Steps
1. **Detect & record.** Note time, what, how found. Start a timeline.
2. **Contain.** For Sev-1: identify and cut the path (revoke keys, pull the build
   from sale via App Store Connect if needed, disable the website form/endpoint).
3. **Assess scope.** What data, how many, what period. For the app, remember most
   data is on-device and never collected — scope is usually the *code path*, not
   a server store.
4. **Fix.** Patch, add a test that would have caught it, run the full checklist.
5. **Notify.** If real user data was exposed, notify affected users and comply
   with applicable law (attorney input). Update `SECURITY.md`/website as needed.
6. **Postmortem.** Blameless writeup: cause, fix, prevention. Add a
   `RISK_REGISTER.md` row if new.

## Contacts / roles
- Incident lead: Founder (until a team exists).
- Security reports: per `../SECURITY.md`.
- Legal: [attorney — engage for any Sev-1 with real exposure].

## Comms principles
- Tell the truth, promptly, without minimizing.
- Never claim "no data was affected" unless verified.
- Keep users' trust ahead of PR.

## Drills
- After each Sev-1/2, verify the added regression test is in CI.
- Periodically rehearse "a secret was committed" and "a wrong benchmark shipped".
