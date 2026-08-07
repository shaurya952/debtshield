# App Review Notes — DebtShield

_Paste into App Store Connect ▸ App Review Information ▸ Notes. Keep it short,
factual, and reviewer-friendly._

## What DebtShield is
A private, on-device personal-finance app. The user types their monthly numbers
(income, rent, food, energy, debt) and the app shows, in plain dollars, how their
month stands and a transparent projection of the months ahead. It is educational
information, not financial advice.

## No account needed
There is **no sign-in and no server**. On first launch, a short on-device setup
asks for a first name (optional email) — nothing is transmitted. You can also tap
"Get started" and enter any name to proceed. No credentials are required to
review any feature.

## How to test quickly
1. Launch → complete the brief setup (any name).
2. Tap "Add your numbers" (or the edit pencil) and enter, e.g., income 5000,
   rent 1400, food 500, energy 250, debt 300.
3. The Home screen shows the Safe Line, a verdict, and tiles: The year ahead,
   Your spending, Save & earn more, Could you move?
4. Compare tab: pick any U.S. county to see local comparisons.
5. Ask tab: try "why is it tight?" — answers come only from the entered numbers.
6. About ▸ Trust Center covers privacy, methodology, data, and a data-delete
   control. About ▸ "Delete my numbers" clears the user's entries.

## Privacy / data
No data is collected or transmitted. No analytics, no ads, no tracking, no
location, no contacts. Comparison datasets (U.S. Census, EIA, BLS) are bundled
and read-only. The privacy manifest declares only `UserDefaults` usage. The app
works fully offline (testable in Airplane Mode).

## Notable behaviors reviewers may ask about
- **Optional Face ID lock** (Settings in About). Off by default; falls back to
  passcode; never locks out a device without biometrics/passcode.
- **Ask is deterministic**, not generative AI — it only restates and computes
  from the user's own figures and bundled data, and redirects loans/bankruptcy/
  benefits questions to reputable free resources (211, HUD).
- **External links** (211, HUD, Benefits.gov, Investor.gov) open in Safari.
- **Local notifications** are opt-in (About ▸ Monthly check-in), used only for a
  private monthly reminder.

## Guideline alignment
- No individualized financial advice; educational only, with cited public data
  and disclosures (Guideline 1.4 / general).
- No account requirement (2.3 metadata accurate; 5.1.1 minimal data — none).
- No purchases, no ads, no third-party analytics SDKs.

## Contact
Reviewer questions: <add support email before submission>.
