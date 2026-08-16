# App Store — Copy/Paste Submission Pack

_Everything you paste into App Store Connect + the written policies, in one place.
All copy is honest and charter-compliant (no guarantees, educational only, no
fabricated claims). Have an attorney review the legal text before relying on it.
Companion detail: `APP_STORE_LAUNCH.md`, `PRIVACY_DISCLOSURE_WORKSHEET.md`,
`APP_REVIEW_NOTES.md`._

---

## 1. App information
- **App name:** DebtShield
- **Subtitle (≤30 chars):** Your month, in plain dollars
- **Primary category:** Finance
- **Secondary category:** (optional) Productivity
- **Age rating:** 4+
- **Bundle ID:** com.debtshield.DebtShieldAI
- **Version / Build:** 1.0 (1)
- **Copyright:** © 2026 Shaurya Thakor
- **Support URL:** https://debtshield-web.pages.dev/help.html
- **Marketing URL:** https://debtshield-web.pages.dev/
- **Privacy Policy URL:** https://debtshield-web.pages.dev/privacy-policy.html

## 2. Promotional text (≤170 chars)
See where your money stands this month, and where it's heading — in plain dollars. Private and on-device: your numbers never leave your phone.

## 3. Keywords (≤100 chars, comma-separated, no spaces)
budget,money,finance,debt,spending,expenses,rent,savings,bills,privacy,offline,plan,tracker,cost

## 4. Description
Know where your money stands — privately.

DebtShield answers one question in plain dollars: how does my money stand this month, and where is it heading? No score, no grade, no judgment.

• Safe Line — see your income, what essentials take, and what's left.
• The year ahead — a transparent simulation of your odds of dipping into the red, with the one change that would help most. It shows its assumptions.
• Compare — how your rent, food, and energy line up with your area and the U.S., using public Census, EIA, and BLS data. Context, never a target.
• Ask — answers from your own numbers. It never invents figures, and points you to free help (like 211 and HUD counselors) when money is tight.
• Every month — update your numbers and see what changed.

Private by design. No account, no bank connection, no ads, no tracking. Your income, rent, debt, verdicts, and simulation results are stored only on your device and are never uploaded. It works fully offline. Delete everything in one tap.

DebtShield is educational information, not financial, legal, tax, or housing advice, and it does not guarantee any financial outcome.

## 5. What's New (v1.0 release notes)
First release of DebtShield — a calm, private, on-device way to see where your money stands this month and where it's heading, in plain dollars. Includes the Safe Line, a transparent year-ahead simulation, area/national comparisons from public data, a deterministic Ask assistant, monthly check-ins, an optional Face ID lock, and one-tap delete of your data. Nothing leaves your device.

## 6. App Privacy questionnaire (App Store Connect ▸ App Privacy)
**Do you or your third-party partners collect data from this app?** → **No** → yields the **"Data Not Collected"** label.

This is accurate: nothing the user enters or the app derives ever leaves the device; no analytics, ads, or crash SDKs; no location/contacts/camera/photos/health/pasteboard.

| Category | Collected? |
|---|---|
| Financial info | No — on-device `UserDefaults` only |
| Contact info (name, email) | No — optional, on-device only |
| Identifiers | No — no account, no ad ID |
| Usage / diagnostics | No — no analytics/crash SDK |
| Location / Contacts / Photos / Health | No — not accessed |

**App Tracking Transparency:** not applicable (no tracking, no ad identifier).

## 7. Export compliance
**Uses non-exempt encryption:** No (`ITSAppUsesNonExemptEncryption = NO`).

## 8. Notes for App Review (paste into "App Review Information ▸ Notes")
No account or sign-in is required — tap through the brief onboarding and start entering numbers. All figures are user-entered and stored only on the device (UserDefaults); the app makes no network requests with personal data and has no backend, analytics, or ads. Comparison data (U.S. Census, EIA, BLS) is bundled and read-only.

The "Ask" feature is a deterministic assistant that answers only from the user's entered figures and bundled benchmarks — it is not a generative chatbot and makes no network calls.

DebtShield is educational information only; it does not provide individualized financial, legal, tax, or housing advice and makes no guarantees. External help links (e.g. 211, HUD) open in Safari.

Notes: the optional Face ID lock and monthly local notification are best exercised on a physical device. The year-ahead figure is a projection shown with a range, not a prediction.

Support contact: debtshieldsupport@gmail.com.

---

## 9. Privacy Policy (full text — also live at /privacy-policy.html)
> This is the plain-language policy for the DebtShield iOS app. Have it reviewed
> by an attorney before you rely on it.

**DebtShield Privacy Policy**

DebtShield is a private, on-device app. We designed it so your financial information never leaves your phone.

What the app stores on your device: the numbers you enter (income, rent/mortgage, food, energy, debt), your optional name and email, your chosen home county, your saved months, and app settings. This is stored only in the app's local storage on your device.

What we collect: nothing. The app has no account system and no server for your personal data. Your income, expenses, verdicts, simulation results, and chosen location are never transmitted off your device. There is no analytics, advertising, or tracking, and no bank connection.

Comparison data: county and national cost figures shown for context are bundled inside the app from public sources (U.S. Census Bureau, U.S. Energy Information Administration, U.S. Bureau of Labor Statistics). Using them requires no network request.

Your control: you can delete everything you've entered at any time with the in-app "Delete my numbers" control. Deleting the app also removes its on-device data.

The website: our website (separate from the app) offers optional forms (beta waitlist, organization pilot, reviewer interest). If you choose to submit one, the information you type is sent to our form provider so we can contact you. The website never receives any of your in-app financial data. See the form and this policy on the site for details.

Children: the app is rated 4+ and is not directed at children, collects no data, and requires no account.

Changes: if this policy changes, we will update it here with a new date.

Contact: debtshieldsupport@gmail.com.

---

## 10. Terms of Use / Educational Disclaimer (summary — full text live at /terms.html)
DebtShield provides educational and informational content only. It is not financial, investment, legal, tax, credit, housing, or bankruptcy advice, and it is not a substitute for a qualified professional. Thresholds and projections are configurable educational heuristics, not guarantees or predictions. DebtShield does not guarantee the prevention of debt, bankruptcy, eviction, or any financial outcome. Comparison figures are broad public averages, not your exact costs. Use the app at your own discretion.

---

## 11. Human to-dos before you hit Submit
- [ ] Enrol in the Apple Developer Program ($99/yr); set the signing **Team** in Xcode.
- [x] Support/privacy email set to **debtshieldsupport@gmail.com** (in this copy, the website, and the in-app Trust Center).
- [ ] Confirm you own/are comfortable with the bundle id `com.debtshield.DebtShieldAI`.
- [ ] Capture the **screenshot set** (see `SCREENSHOT_PLAN.md`) at required device sizes.
- [ ] Archive in Xcode → upload to App Store Connect → attach metadata above → submit.
- [ ] Attorney review of the privacy policy and terms.
