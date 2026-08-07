# Privacy Disclosure Worksheet — App Store "App Privacy"

_Answers for App Store Connect ▸ App Privacy. Verified against the source: the
app makes no network requests with user data, has no analytics/ads SDKs, and
uses no location, contacts, camera, photos, health, or pasteboard collection.
The privacy manifest (`ios/DebtShieldAI/PrivacyInfo.xcprivacy`) declares only
`UserDefaults` (reason CA92.1) and no tracking._

## Headline answer
**Do you or your third-party partners collect data from this app?** → **No.**

Selecting "No" yields the **"Data Not Collected"** privacy label. This is
accurate because nothing the user enters or that the app derives ever leaves the
device, and no usage/diagnostic data is gathered.

## Why "Data Not Collected" is correct
| Category | Collected? | Why |
|---|---|---|
| Financial info (income, etc.) | No | Stored only on-device in `UserDefaults`; never transmitted. |
| Contact info (name, email) | No | Optional, on-device only; no server receives it. |
| Identifiers | No | No account, no device/advertising identifiers used. |
| Usage data / analytics | No | No analytics SDK; no events sent. |
| Diagnostics / crash | No | No crash-reporting SDK. |
| Location | No | Never requested; county is chosen manually from bundled data. |
| Contacts / Photos / Health | No | Not accessed. |

## Tracking
**App Tracking Transparency:** Not applicable — the app does no tracking and
uses no advertising identifier, so no ATT prompt is shown.

## Notes for consistency
- If analytics is **ever** added later, it must be **opt-in**, and this worksheet
  and the label must be updated first (see `STARTUP_ROADMAP.md` Phase 7 —
  currently not implemented).
- The **website** collects contact-form data (waitlist/pilot/reviewer). That is
  separate from the app and does not change the app's "Data Not Collected"
  status. It is disclosed in the website privacy policy and on each form.
- Keep `PrivacyInfo.xcprivacy` in sync: it currently lists only
  `NSPrivacyAccessedAPICategoryUserDefaults` / `CA92.1` and
  `NSPrivacyTracking = false`.
