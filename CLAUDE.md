# DebtShield — Engineering Charter (permanent rules)

This file is the standing contract for anyone (human or AI) working in this
repository. Read it before changing code. It encodes the product's privacy-first
mission and the non-negotiable rules of the startup-hardening program.

## What DebtShield is
A personal, private, **on-device** fintech app (SwiftUI, iOS 17+) that answers
one question in plain dollars — *how does my money stand this month, and where is
it heading?* — with no score, no grade, no judgment. County/national comparison
data is **bundled** in the app. There is no backend for personal financial data.

## Non-negotiable principles
1. Do **not** introduce a backend for personal financial information.
2. Do **not** transmit income, rent, debt, expenses, verdicts, simulation
   results, or identifiable financial profiles off the device.
3. No bank-account connections.
4. No advertisements.
5. No payday-loan / credit-card / debt-settlement / referral monetization.
6. Never claim the product guarantees prevention of debt, bankruptcy, eviction,
   or financial harm.
7. No individualized financial, investment, legal, tax, credit, housing, or
   bankruptcy advice. Educational information only, with citations.
8. Do not weaken accessibility (WCAG-AA, Dynamic Type, VoiceOver, Reduce Motion,
   light+dark, no meaning by color alone).
9. Do not remove source citations or methodology disclosures.
10. Never fabricate users, reviews, partners, testimonials, revenue, or metrics.
11. Never commit secrets, API keys, credentials, signing certs, or personal data.
12. No destructive change without a safe Git checkpoint first.
13. Do not rewrite the functioning app unnecessarily.
14. No third-party dependency without clear, documented value.
15. Do not mark a phase complete until builds and relevant tests pass.

## The Ask feature is deterministic
`PersonalChatEngine` answers only from the user's entered figures, the engines,
and bundled benchmarks. It must never fabricate numbers, and it redirects loans /
bankruptcy / benefits / serious distress to reputable free resources (211, HUD).
Keep it deterministic and non-generative unless a separately approved, safety-
reviewed product change says otherwise.

## Thresholds are configurable heuristics, not universal facts
Safe-line %, comfortable cushion, debt warning/heavy levels, surprise
probability, simulation count, horizons, and verdict boundaries are educational
heuristics. Keep them named and documented (see `THRESHOLD_REGISTRY.md`), never
present them as absolute financial truth.

## Working rules
- Work in small, reviewable phases; keep the repo releasable after each.
- Build Debug **and** Release before declaring a phase done.
- Pure calculation logic stays in `Core/` with no SwiftUI import, so engines are
  headlessly testable (`swiftc` harness pattern is already used).
- Update `IMPLEMENTATION_STATUS.md` and `CHANGELOG.md` as work lands.
- Label human-only steps (Apple account, legal review, real partner decisions)
  clearly; never invent credentials or business information.

## Build / run
```bash
xcodebuild -project ios/DebtShieldAI.xcodeproj -scheme DebtShieldAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```
Release: swap `-configuration Release`. Engines can be tested by copying the
relevant `Core/*.swift` files plus a `main.swift` and running `swiftc -D DEBUG`.

## Program docs
- `AUDIT_REPORT.md` — current state, risks, order of work.
- `ARCHITECTURE.md` — layers, data flow, privacy/network boundaries.
- `STARTUP_ROADMAP.md` — phases 0–16, organized by launch stage.
- `IMPLEMENTATION_STATUS.md` — living status of every phase.
- `THRESHOLD_REGISTRY.md` — every configurable heuristic and its source.
