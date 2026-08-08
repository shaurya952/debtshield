# DebtShield

[![CI](https://github.com/shaurya952/debtshield/actions/workflows/ci.yml/badge.svg)](https://github.com/shaurya952/debtshield/actions/workflows/ci.yml)

A personal, private, **on-device** iOS app (SwiftUI, iOS 17+) that answers one
question in plain dollars — *how does my money stand this month, and where is it
heading?* — with **no score, no grade, no judgment**.

County and national comparison data is **bundled** in the app. There is **no
backend for personal financial data**, and nothing you enter ever leaves your
device.

> **Not financial advice.** DebtShield provides educational information only,
> with citations. It does not give individualized financial, investment, legal,
> tax, credit, housing, or bankruptcy advice, and it does not guarantee
> prevention of any financial outcome.

## Privacy principles (non-negotiable)
- No backend and no network calls for personal financial data — it lives only in
  `UserDefaults` on the device.
- No bank-account connections. No advertisements. No analytics SDK.
- No payday-loan / credit-card / debt-settlement / referral monetization.
- Comparison datasets (U.S. Census, EIA, BLS) are bundled and read-only, with
  citations kept in the app and on the website.

See [`CLAUDE.md`](CLAUDE.md) for the full engineering charter and
[`IMPLEMENTATION_STATUS.md`](IMPLEMENTATION_STATUS.md) for current status.

## What's in this repo
| Path | What it is |
|------|------------|
| `ios/DebtShieldAI/` | The iOS app. `Core/` = pure Swift engines (no SwiftUI, headlessly testable); `Views/` = SwiftUI UI; `Resources/` = bundled CSVs. |
| `ios/DebtShieldAITests/` | Engine unit tests (run in CI). |
| `website/` | Zero-dependency static marketing + trust website (Node ≥18, no npm deps). |
| `scripts/` | Dataset validation, secret scan, impact summary, test runner. |
| `docs/`, `startup-docs/` | Product, launch, privacy, accessibility, and operations docs. |
| `.github/workflows/ci.yml` | CI: engine tests, dataset validation, secret scan, website checks. |

## Build the app
```bash
# Debug (swap -configuration Release for the Release build)
xcodebuild -project ios/DebtShieldAI.xcodeproj -scheme DebtShieldAI \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build
```
Scheme `DebtShieldAI`; bundle id `com.debtshield.DebtShieldAI`; iOS 17 target.
Signing (`DEVELOPMENT_TEAM`) is intentionally left unset — it's a human step.

## Run the tests
```bash
# Engine unit tests (override the simulator with DEST=… if needed)
scripts/test-engines.sh
```
```bash
# Dataset + secret checks (also run in CI)
python3 scripts/validate_datasets.py
bash scripts/scan_secrets.sh
```

## Run / build the website
```bash
cd website && node build.mjs && node test.mjs
```

## Author
Shaurya Thakor
