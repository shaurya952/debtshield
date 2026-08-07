# Risk Register

_Live list of top risks. Likelihood (L) and Impact (I): Low / Med / High.
Review each release and each phase._

| # | Risk | L | I | Mitigation | Owner |
|---|------|---|---|------------|-------|
| 1 | A future change accidentally transmits personal financial data | Low | High | No networking layer for personal data; secret scan + review; incident plan; keep the "no path off device" architecture | Eng |
| 2 | Misleading verdict / false precision harms a user's decision | Med | High | Documented heuristics; ranges + assumptions shown; adviser review; non-shaming copy; "not advice" disclaimers | Product |
| 3 | Bundled data goes stale or wrong | Med | Med | Validation script; documented vintages; annual update process; corrections via feedback | Data |
| 4 | App Store rejection (privacy, metadata, guidelines) | Med | Med | Accurate privacy label ("Data Not Collected"); review notes; no upsells/ads; export-compliance set | Eng |
| 5 | Legal exposure — perceived as financial advice | Med | High | Educational framing + disclaimers everywhere; attorney review of terms; redirect to professionals/free help | Founder + counsel |
| 6 | Accessibility regression ships | Low | Med | ACCESSIBILITY_CHECKLIST per release; AX Dynamic Type spot-check; UI-test rewrite (pending) | Eng |
| 7 | Key-person dependency (single founder) | High | Med | Documentation (this repo); simple, dependency-light stack; runbooks | Founder |
| 8 | Website form provider mishandles contact data | Low | Med | Choose privacy-conscious provider; data policy; minimal fields; deletion path | Founder |
| 9 | Reminder/notifications feel manipulative | Low | Med | Opt-in, plain copy, no streaks; T&S review | Product |
| 10 | Fabricated/overstated traction damages trust | Low | High | METRICS_DEFINITIONS honesty rules; PUBLIC_CLAIMS_REGISTER; never invent partners/metrics | Founder |
| 11 | Institution demands individual data | Med | High | Hard boundary in BUSINESS_MODEL; walk away rather than compromise | Founder |

## Cadence
- Re-score at each release and phase.
- New risks get a row immediately; closed risks are archived with a note.
