# Accessibility Checklist

_Per-release accessibility sign-off. The full statement + audit method live in
`../ACCESSIBILITY.md`; this is the actionable checklist._

## Every release (changed screens at minimum)
- [ ] **Dynamic Type** to the largest accessibility size — no clipping/overlap;
      content wraps and scrolls.
- [ ] **VoiceOver**: labels present and meaningful; sensible reading order;
      decorative elements hidden; charts have spoken summaries.
- [ ] **Contrast** meets WCAG-AA in light **and** dark.
- [ ] **No color-only meaning** — status also has words + an icon.
- [ ] **Reduce Motion** respected (animations disable/soften).
- [ ] **Tap targets** ≥ 44×44 pt.
- [ ] Nav titles don't truncate at AX sizes (use inline for long titles).

## Website
- [ ] Semantic HTML; one `<h1>` per page; skip-to-content link.
- [ ] Visible keyboard focus; forms have labels + errors reachable.
- [ ] Contrast AA in light/dark; motion respects `prefers-reduced-motion`.
- [ ] `test.mjs` checks pass (structure/links/meta).

## Tools
- Simulator Dynamic Type: `xcrun simctl ui <dev> content_size accessibility-extra-extra-extra-large`.
- Xcode Accessibility Inspector / audit; VoiceOver on device for the real walk.

## Follow-ups (tracked)
- [ ] Rewrite the stale v1 accessibility UI-tests to the current UI and run
      `performAccessibilityAudit` per screen (see `../ACCESSIBILITY.md`).
- [ ] Physical-device VoiceOver + Switch Control pass before public launch.

## Sign-off
Release: ______  Reviewer: ______  Date: ______  Notes: ______
