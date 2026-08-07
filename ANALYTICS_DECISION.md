# Analytics Decision

_Per the charter, DebtShield does **not** auto-install analytics. This document
compares the options, records a decision, and — only as a blueprint — specifies
what a privacy-safe Option B would require. No analytics are implemented._

## Principle
DebtShield's core promise is that personal financial data never leaves the
device. Any analytics is a risk to that promise and to user trust, so the bar to
add it is high, it must be **opt-in**, and it must never carry sensitive data.

## The options

### Option A — No analytics SDK (recommended)
Learn without an in-app tracker:
- **App Store Connect** gives aggregate, Apple-provided metrics (downloads,
  active devices, retention cohorts) — not our tracking, no SDK, nothing we
  collect.
- **Voluntary impact surveys** (Phase 11) — anonymous, no financial data.
- **In-app feedback** (Phase 6) — the user chooses exactly what to share,
  including a voluntary "features I've tried" summary.
- **Beta interviews** and website form signals.

**Pros:** keeps "Data Not Collected"; no consent burden; nothing to breach; no
SDK/supply-chain risk; simplest App Store privacy story; fully aligned with the
mission. **Cons:** less granular funnel data; behavior is inferred from
self-report + Apple aggregates, not per-event (acceptable — see
`startup-docs/METRICS_DEFINITIONS.md`, which already treats in-app behavior as
mostly unobservable by design).

### Option B — Strictly opt-in, minimal event analytics
An opt-in toggle enables sending a few **broad, parameterless** events through an
abstraction layer to a privacy-first destination.

**Pros:** clearer activation/retention funnel. **Cons:** changes the privacy
label; adds consent UI, a dependency or first-party endpoint, retention/deletion
obligations, and ongoing audit burden; erodes the simplest version of the
promise. Only worth it if a concrete decision genuinely needs per-event data
that surveys + Apple aggregates can't answer.

## Decision
**Adopt Option A now.** Do not add an analytics SDK. Re-evaluate only if a
specific, important product/business question cannot be answered by App Store
Connect aggregates + voluntary surveys + feedback — and even then, implement
Option B only with everything in the blueprint below in place first.

---

## Option B blueprint (specification only — NOT implemented)

If Option B is ever adopted, it must meet **all** of the following before any
event is sent.

### Allowed events (the only ones; broad, no parameters)
`onboarding_started`, `onboarding_completed`, `first_plan_completed`,
`year_ahead_opened`, `comparison_opened`, `second_month_completed`,
`help_resource_opened`.

Events are **parameterless** — no numbers, no free text, no context payload.

### Never transmit (hard list)
Income, expenses, debt, financial verdict, simulation odds/results, county
combined with any identifier, name, email, free-text Ask questions, full device
fingerprint, advertising identifier (IDFA). No advertising features of any kind.

### Opt-in flow
- Off by default. A clear toggle in About ("Help improve DebtShield — share
  anonymous, non-financial usage events") with plain-language explanation and a
  link to the policy.
- No ATT prompt needed (no tracking, no IDFA) — and none should be added.
- Turning it off stops sending and requests deletion where the provider supports
  it.

### Abstraction layer (so the provider can be removed)
```swift
enum AnalyticsEvent: String {           // broad, parameterless
    case onboardingStarted, onboardingCompleted, firstPlanCompleted,
         yearAheadOpened, comparisonOpened, secondMonthCompleted, helpResourceOpened
}
protocol AnalyticsSink { func log(_ event: AnalyticsEvent) }        // no payload param
struct NoOpSink: AnalyticsSink { func log(_ event: AnalyticsEvent) {} }  // default
// A single facade reads the opt-in flag; if off OR sink is NoOp, nothing leaves.
```
The app calls `Analytics.log(.yearAheadOpened)` at the same points that today set
the on-device engagement flags. With `NoOpSink` (the default), nothing is
transmitted. Swapping the provider back to `NoOpSink` fully removes analytics.

### Destination requirements
A privacy-first, first-party endpoint or a privacy-focused provider with: no
advertising, no IDFA, EU-friendly processing, a signed data-processing
agreement, documented retention, and a deletion path. Prefer a minimal
first-party endpoint over a third-party SDK.

### Documentation & disclosure to update first
- `PrivacyInfo.xcprivacy`: add "Product Interaction," **not linked to identity**,
  **not used for tracking** (currently declares no collected types).
- App Store **App Privacy** label: update `PRIVACY_DISCLOSURE_WORKSHEET.md`; it
  would move from "Data Not Collected" to collecting Product Interaction (not
  linked, no tracking).
- Website **privacy policy** and in-app **Trust Center**: describe the opt-in
  events and the never-list.
- `PUBLIC_CLAIMS_REGISTER.md`: revise the "no analytics" claim.

### Tests required
- Allowed-events set is exactly the seven above; `AnalyticsEvent` has **no
  associated values** (parameterless) — a test/lint enforces this.
- Default sink is `NoOpSink`; with analytics disabled, no event reaches a sink.
- A guard test that the event type carries no payload (nothing to leak).

## Revisit trigger & owner
Owner: Founder. Revisit only when a documented, important question can't be
answered by Option A sources. Any move to Option B updates this file with the
rationale and the completed blueprint checklist.
