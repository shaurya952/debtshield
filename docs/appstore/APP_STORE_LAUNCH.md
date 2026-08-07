# App Store Launch — DebtShield

_The listing copy and launch plan. The **technical** submission checklist
(icon, manifest, signing, bundle id) lives in `ios/APPSTORE.md`; this file is the
marketing/metadata side. Nothing here is submitted automatically — the actual
upload and any Apple-account changes are human steps requiring credentials._

## Listing metadata
- **App name:** `DebtShield` (≤ 30 chars)
- **Subtitle options (≤ 30 chars each):**
  - `Your month, in plain dollars` (28)
  - `See where your money stands` (27)
  - `Money clarity, kept private` (27)
  - `Private, on-device budgeting` (28)
- **Promotional text (≤ 170 chars):**
  > See where your money stands this month, and where it's heading — in plain
  > dollars. Private and on-device: your numbers never leave your phone.
- **Keywords (≤ 100 chars, comma-separated, no spaces):**
  `budget,money,finance,debt,spending,expenses,rent,savings,bills,privacy,offline,plan,tracker,cost`
- **Category:** Finance (primary). Secondary: none, or Productivity.
- **Age rating:** 4+ (no objectionable content, no gambling, no unrestricted
  web access — external help links open in Safari). Made-for-Kids: **No**.
- **Support URL:** `https://<domain>/help.html` (deploy the website first).
- **Marketing URL:** `https://<domain>/`
- **Privacy Policy URL:** `https://<domain>/privacy-policy.html`

## Description (draft — honest, no unsupported claims)
> **Know where your money stands — privately.**
>
> DebtShield answers one question in plain dollars: how does my money stand this
> month, and where is it heading? No score, no grade, no judgment.
>
> • Safe Line — see your income, what essentials take, and what's left.
> • The year ahead — a transparent simulation of your odds of dipping into the
>   red, with the one change that would help most. It shows its assumptions.
> • Compare — how your rent, food, and energy line up with your area and the
>   U.S., using public Census, EIA, and BLS data. Context, never a target.
> • Ask — answers from your own numbers. It never invents figures, and points
>   you to free help (like 211 and HUD counselors) when money is tight.
> • Every month — update your numbers and see what changed.
>
> **Private by design.** No account, no bank connection, no ads, no tracking.
> Your income, rent, debt, verdicts, and simulation results are stored only on
> your device and are never uploaded. It works fully offline. Delete everything
> in one tap.
>
> DebtShield is educational information, not financial, legal, tax, or housing
> advice, and it does not guarantee any financial outcome.

## What's in the box (facts, verified)
- Bundle id `com.debtshield.DebtShieldAI` (**placeholder — change to an owned
  domain before submit**), version `1.0 (1)`, iOS 17+, iPhone + iPad.
- Privacy manifest present; export compliance `ITSAppUsesNonExemptEncryption=NO`.
- Optional Face ID lock (usage string set). No data collection.

## Versioning strategy
- `MARKETING_VERSION` (e.g. 1.0, 1.1) = user-facing version; bump for releases.
- `CURRENT_PROJECT_VERSION` (build) = **bump on every upload**, even resubmits.
- Semantic-ish: patch for fixes, minor for features, major for big changes.
- Tag releases in Git (`v1.0.0`).

## Known limitations to disclose in review / notes
- Benchmarks are broad public averages, not the user's exact costs.
- The year-ahead is a projection with a stated range, not a prediction.
- Local notifications and Face ID need a real device to fully exercise.

## Contact process
- A public support/corrections email is **not yet set** — add it to the website
  and the in-app Trust Center before launch (`[HUMAN]`). The App Store support
  URL must resolve to a page with a way to get help.

## Companion docs
- `APP_REVIEW_NOTES.md` — notes for App Review.
- `PRIVACY_DISCLOSURE_WORKSHEET.md` — App Privacy questionnaire answers.
- `SCREENSHOT_PLAN.md` — screenshots + app preview storyboard.
- `RELEASE_NOTES_TEMPLATE.md` — "What's New" template + v1.0 draft.
- `../RELEASE_CHECKLIST.md` — pre-submit checklist.
- `../../ios/APPSTORE.md` — technical submission checklist.
