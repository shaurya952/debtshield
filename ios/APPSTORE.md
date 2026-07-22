# DebtShield AI — App Store submission guide

Everything in this file was checked against the built app, not assumed.

---

## 1. What is already done

| Item | Status |
| --- | --- |
| App icon (1024pt, opaque, no alpha) | ✅ `Assets.xcassets/AppIcon.appiconset` |
| Accent colour (light + dark) | ✅ `Assets.xcassets/AccentColor.colorset` |
| Privacy manifest | ✅ `PrivacyInfo.xcprivacy`, declares `UserDefaults` / CA92.1 |
| Export compliance | ✅ `ITSAppUsesNonExemptEncryption = NO` |
| App category | ✅ Finance |
| Display name | ✅ "DebtShield" |
| Deployment target | ✅ iOS 17.0 |
| Devices | ✅ iPhone + iPad |
| Launch screen | ✅ generated |
| Version / build | ✅ 1.0 (1) |
| UI + accessibility tests | ✅ `DebtShieldAIUITests` |

## 2. What you must change before submitting

**Bundle identifier.** Currently `com.debtshield.DebtShieldAI`, a placeholder.
Change it in Xcode ▸ target ▸ Signing & Capabilities to a reverse-DNS identifier
on a domain you control, then register it in App Store Connect.

**Signing team.** The project has no development team set — it builds unsigned
for the simulator. Select your Apple Developer team in Signing & Capabilities.

**Bump the build number** for every upload: `CURRENT_PROJECT_VERSION`.

## 3. Privacy nutrition label answers

App Store Connect will ask what you collect. Based on an audit of the source —
no `URLSession`, no analytics SDK, no location, contacts, camera, photos,
health, or pasteboard access:

> **Data collection: No, we do not collect data from this app.**

Everything stored stays on device and is never transmitted:

| Key | Contents |
| --- | --- |
| `debtshield.favorites` | FIPS codes of saved counties |
| `debtshield.recentlyViewed` | FIPS codes, max 10 |
| `debtshield.selectedCounty` | FIPS code of the last county viewed |
| `debtshield.recommendationAudience` | `policymakers` or `residents` |
| `debtshield.hasSeenOnboarding` | Bool |

If you later add networking or analytics, this answer, `PrivacyInfo.xcprivacy`,
and `PrivacyView.swift` all have to change together.

## 4. Age rating

**4+.** No objectionable content, no user-generated content, no web browsing, no
purchases, no gambling.

## 5. Review notes (paste into App Store Connect)

> DebtShield AI is an educational tool that visualises U.S. Census statistics
> about financial pressure at county level. All data ships inside the app; there
> is no account, no login, no network access, and nothing is collected.
>
> The app displays a "Financial Distress Index" that this project computes from
> published Census figures with a fixed, documented formula. It is not a credit
> score, not a rating of any individual, and not financial advice. An
> educational-use disclaimer appears on first launch before the app can be used,
> and on every data screen.
>
> The "Ask DebtShield" feature is not a language model. It is a deterministic
> responder that computes answers from the bundled dataset; it declines requests
> for personal financial advice and directs the reader to 211 and HUD-approved
> counselling instead.

## 6. Likely review questions

**"Is this financial advice?"** No — and the app says so on first launch, on the
Recommendations screen, on the Disclaimer screen, and in a footer on every data
screen. The chatbot explicitly declines personal-advice questions.

**"Where does the data come from?"** U.S. Census Bureau, American Community
Survey 5-Year estimates. Public domain. Bundled as CSV.

**"What does the AI do?"** Nothing is generative. The name reflects the original
research project, which trained classifiers in Python. Those models do not run
in the app — the Model Performance screen reports their historical metrics and
states plainly that the app's index is a rule-based formula.

Consider whether "AI" in the display name is worth keeping. It is accurate about
the project's origin but invites questions the app then has to answer.

## 7. Screenshot plan

Required: 6.7" iPhone. Recommended: 13" iPad.

Suggested five, all available without any setup:

1. **Dashboard** — 3,144 counties, distribution chart
2. **County Profile** — East Carroll Parish, index and drivers
3. **Risk Drivers** — ranked drivers with national medians
4. **Risk Map** — the state grid
5. **Ask DebtShield** — a question and its sourced answer

Capture with:

```
xcrun simctl io "iPhone 17 Pro Max" screenshot shot.png
```

## 8. Accessibility status

Xcode's automated accessibility audit runs against **every screen** in the UI
test suite (`DebtShieldAIUITests`), covering all categories — contrast, Dynamic
Type, clipped text, hit-region size, and element description.

**Current result: zero findings.** Down from 193 when the audit was first
introduced.

What was fixed along the way:

| Issue | Fix |
| --- | --- |
| `.secondary` text measured ~4.4:1, just under AA | `Theme.secondaryText`, 130 call sites |
| Badge text on tinted fills | Darkened text, lightened fill to 12% — the earlier move to 20% had pushed it the wrong way |
| Fixed `.system(size:)` fonts in six views | Text styles and `@ScaledMetric` |
| `minimumScaleFactor` defeating Dynamic Type | Removed; text wraps instead of shrinking |
| Map tiles: fixed 44pt frames text can never grow inside | Grid presented as one labelled element, like the charts; the ranked list below is the accessible equivalent |
| Stat cards and nav rows clipping at large text | Stack vertically at accessibility sizes |
| `LazyVStack` not re-measuring on text-size change | Plain `VStack` in the chat transcript |
| Glossary `List` internals unattributable to any element | Rebuilt on the app's standard card pattern |

**One caveat worth understanding.** The audit reports contrast failures for
elements that are off-screen or behind the translucent bars, because it walks
the whole element tree while only being able to sample visible pixels. That was
measured, not assumed: auditing one screen at the top and again scrolled to the
bottom produced two "failure" sets with **zero** elements in common. The test
suite therefore judges only elements wholly inside the unobstructed viewport —
see `unobstructedViewport(of:)`. Every category stays enforced.

`AccessibilityDiagnostics.swift` enumerates findings with their elements; it is
expected to fail while any finding exists, and is the tool to reach for when the
enforcing tests report a category without naming the element.

## 8a. Test suite

`DebtShieldAIUITests` — **11 tests, all passing, none skipped.** Onboarding,
all five tabs, search → select → drill into every detail screen, saving a county
across a relaunch, the chatbot answering and declining, the scenario reset
behaviour, and an accessibility audit of every screen.

`AccessibilityDiagnostics` — enumerates any audit finding together with the
element that caused it. Currently reports none. Reach for this when an enforcing
test names a category without naming the element.

The scenario slider test previously popped the screen mid-run: XCUITest
synthesises its drag from the thumb, and the median-income slider's thumb sits
near the leading edge for most counties, inside iOS's interactive-pop zone. The
slider track starts 32pt from the edge — outside the ~20pt zone — so this was a
quirk of the synthesised gesture, not something a person would hit. The test now
drives a mid-track slider and asserts explicitly that adjusting it does not
navigate away.

## 9. Build and upload

```bash
# Archive
xcodebuild archive \
  -project DebtShieldAI.xcodeproj \
  -scheme DebtShieldAI \
  -destination 'generic/platform=iOS' \
  -archivePath build/DebtShieldAI.xcarchive

# Then: Xcode ▸ Window ▸ Organizer ▸ Distribute App ▸ TestFlight & App Store
```

Run the tests first:

```bash
xcodebuild test -project DebtShieldAI.xcodeproj -scheme DebtShieldAI \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

## 10. The Python project is untouched

The Streamlit app, its CSVs, and the `.pkl` model are unchanged in the
repository root. The iOS app has its own copies of the three CSVs under
`ios/DebtShieldAI/Resources/`. The two counties missing from the original
dataset were added to the iOS copy only, so Streamlit's median-fill behaviour
is not disturbed — see the Phase 3 notes in `PHASE1-SETUP.md`.
