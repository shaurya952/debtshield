# Impact Survey — Data Retention Policy

_Governs the voluntary, anonymous impact-survey responses. This is separate from
the app (which collects nothing) and from the website contact forms._

## What's stored
Only survey answers: the anonymous matching `code`, the Likert responses, the
action flags, and optional free text. **No** name, email, income, rent, debt,
verdict, county, simulation results, IP-based identity, or device fingerprint.

## Purpose limitation
Used only to compute **aggregate** impact summaries. Individual responses are
never published or shared.

## Retention
- Keep raw responses only for the duration of the study plus a short window to
  finalize analysis, then delete the raw responses.
- Keep only the **aggregate** summary afterward (which contains no individual
  data).
- Set concrete dates when the study starts and record them here.

## Access
Limited to the person(s) running the study. No third-party access beyond the
survey tool storing responses on our behalf.

## Deletion
Because responses are anonymous, a participant can request removal by giving
their matching `code`; we delete the matching row. Deletion requests are honored
promptly.

## Security
- Collected over HTTPS via a privacy-conscious survey tool or anonymous form.
- No secrets stored in the repo; any tool credentials live outside it.
- Exports are stored securely and deleted per the retention window above.

## Honesty
We never present survey data as more than it is (self-report), never fabricate
responses, and never publish a figure without n, period, and the causation
caveat (`IMPACT_STUDY_PROTOCOL.md`).
