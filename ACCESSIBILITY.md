# DebtShield — Accessibility

_Last updated: Phase 4. Audience: engineering + anyone evaluating the app's
accessibility. This is also the public accessibility statement surfaced in the
in-app Trust Center._

## Commitments
DebtShield is built to be usable by everyone, and accessibility is a
non-negotiable (see `CLAUDE.md`, rule 8):
- **Dynamic Type** — every text style maps to a system text style and scales,
  including the largest accessibility sizes. No fixed point sizes for body text.
- **VoiceOver** — meaningful labels, combined elements where that reads better,
  decorative elements hidden, and spoken summaries for custom visuals (e.g. the
  Safe Line bar announces the full breakdown).
- **Contrast** — colors are tuned to clear WCAG-AA (4.5:1) in both light and
  dark; `Theme.secondaryText` was darkened/lightened specifically to pass.
- **Color is never the only signal** — every status also ships a word and an
  SF Symbol (status chip, verdict, compare standings).
- **Reduce Motion** — press animations, shimmer, and the tour transitions all
  check `accessibilityReduceMotion`.
- **Tap targets** — nothing tappable goes below 44×44 pt (`Theme.minimumTapTarget`).

## Audit method (Phase 4)
1. **Dynamic Type stress** — set the simulator to the largest accessibility size
   (`xcrun simctl ui <device> content_size accessibility-extra-extra-extra-large`)
   and reviewed the main screens for truncation, overlap, and clipping.
2. **Automated audit hook** — the UI-test target contains
   `performAccessibilityAudit` scaffolding (contrast/label/size issue
   enumeration). See "Known gaps" below.

## Findings & fixes
| Finding | Severity | Resolution |
|---|---|---|
| Long **large** nav titles truncate at AX sizes ("How you compare" → "How you co…") | Low | Switched Compare and How-it-works to **inline** titles (Home and the detail screens were already inline). Short titles (About, Privacy) keep the large style. |
| Safe Line bar's **inline segment label** truncates ("Re…") at very large type | Low (cosmetic) | Left as-is by design: the label inside the bar is decorative; the bar ships a full VoiceOver summary and the hero insight line restates the numbers. |
| Body copy, cards, verdict, Trust Center rows, tiles | — | Scale and wrap correctly at AX5; content scrolls, nothing clips. Feature tiles use `fixedSize` and grow (never truncate). |

## Per-screen status
| Screen | Dynamic Type (AX5) | VoiceOver | Notes |
|---|---|---|---|
| Home (dashboard) | ✅ scales/scrolls | ✅ labeled; spoken money + bar summary | inline title |
| The year ahead / Spending / Where you stand | ✅ | ✅ | inline titles |
| Compare | ✅ (title now inline) | ✅ per-bar labels | — |
| Ask | ✅ | ✅ | chat bubbles labeled |
| About / Trust Center | ✅ | ✅ | inline / row labels |
| Move / Place detail | ✅ | ✅ | — |
| Onboarding + tour | ✅ | ✅ headers + step count | button-driven, no forced swipe |

## Automated UI-test audit (current)
`ios/DebtShieldAIUITests/` now drives the **current** app (Home / Compare / Ask /
About + the pushed detail screens), launched with onboarding skipped and a
DEBUG-only seeded plan (`uitest-seed`) so the populated screens are audited:
- `DebtShieldAIUITests` — **enforces** reachability and that each screen and its
  key controls open (fails the build if navigation breaks), and **records** a
  `performAccessibilityAudit` per screen as an attachment (non-failing).
- `AccessibilityDiagnostics` — enumerates all audit findings app-wide into an
  attachment for review.

The automated audit is recorded, not gating, because Xcode's audit has known
false positives here: **Dynamic Type** flags the hero's `ScaledMetric`-driven
`.system(size:)` font (which does scale), **contrast** is reported for content
scrolled under the translucent bars (filtered by viewport), and the Safe Line
bar's inline segment label is intentionally truncated but ships a full VoiceOver
summary. Dynamic Type and contrast are therefore verified **manually** at the
largest size (above). The stale v1 tests were removed.

## Known gaps / follow-ups
- **Full VoiceOver walk-through** on a physical device (rotor, focus order under
  real gestures) is still recommended before public launch.
- **Switch Control / keyboard** navigation is expected to work via standard
  controls but hasn't been formally verified.

## Reporting
Accessibility problems are bugs. Until the public contact address is live (see
the Trust Center), file them via the repository's issue templates.
