# Screenshot & App Preview Plan — DebtShield

_The App Store shows the first 3 screenshots prominently, so order matters. Lead
with the promise (money clarity) and privacy._

## Required sizes (App Store Connect)
- **iPhone 6.9"** (e.g. iPhone 16 Pro Max / iPhone 17 Pro Max) — required.
- **iPhone 6.5"** — accepted (or scaled).
- **iPad 13"** — required if the iPad build is submitted (it targets iPhone+iPad).
Provide 3–10 screenshots per size. Keep captions short; don't cover key UI.

## The set (in order)
| # | Screen | Caption |
|---|--------|---------|
| 1 | Home — "On track", money left, Safe Line bar | "See where your money stands — in plain dollars." |
| 2 | The year ahead (odds dial + range) | "Your odds for the year ahead — with its assumptions shown." |
| 3 | Privacy / Trust Center (does & never-does) | "Private by design. Your numbers never leave your phone." |
| 4 | Compare (you vs area vs U.S.) | "Compare to your area and the U.S. — real public data." |
| 5 | Verdict / "Where you stand" detail | "A plain read of your month — no score, no judgment." |
| 6 | Save & earn more | "Free help and honest ideas when money is tight." |

## How to capture (repeatable, deterministic)
Use the simulator with seeded state (no real data needed):
```bash
DEV="iPhone 17 Pro Max"; BUNDLE="com.debtshield.DebtShieldAI"
xcrun simctl boot "$DEV"; open -a Simulator
# seed a plan so Home renders fully:
PLAN='{"monthlyIncome":5000,"housing":1400,"food":600,"energy":250,"debtPayments":300}'
xcrun simctl spawn "$DEV" defaults write "$BUNDLE" debtshield.moneyPlan -data "$(printf '%s' "$PLAN" | xxd -p | tr -d '\n')"
xcrun simctl spawn "$DEV" defaults write "$BUNDLE" debtshield.hasSeenOnboarding -bool YES
xcrun simctl spawn "$DEV" defaults write "$BUNDLE" debtshield.userName -string "Sam"
# build + install your Release/Debug .app, launch, navigate, then:
xcrun simctl io "$DEV" screenshot home.png
```
Capture in **both light and dark** and pick the stronger set. Use realistic but
non-identifying numbers. Do not show anyone's real finances.

## App preview video (optional, 15–30s, portrait)
Storyboard:
1. (0–4s) Home appears — money left + Safe Line bar animates in. Caption card:
   "Know where your money stands."
2. (4–10s) Tap "The year ahead" — dial + range. Caption: "See the year ahead."
3. (10–16s) Tap Compare — bars fill vs area/U.S. Caption: "Compare with real data."
4. (16–22s) Trust Center — "never does" list. Caption: "Private. On your device."
5. (22–28s) Delete my numbers → confirm. Caption: "Delete everything in one tap."
End on the app icon + "DebtShield". No voiceover required; keep motion gentle
(respect Reduce Motion when recording on-device).

## Don'ts
- No fabricated testimonials, ratings, or "as seen in" badges.
- No claims the app prevents debt/eviction/bankruptcy.
- No real personal financial data.
