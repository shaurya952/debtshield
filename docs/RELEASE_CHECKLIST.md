# Release Checklist

_Run before every TestFlight or App Store build. Keep the repo releasable after
every phase._

## Build & tests
- [ ] `xcodebuild … -configuration Debug build` → succeeds
- [ ] `xcodebuild … -configuration Release build` → succeeds
- [ ] `scripts/test-engines.sh` → all engine tests pass
- [ ] `python3 scripts/validate_datasets.py` → OK
- [ ] `bash scripts/scan_secrets.sh` → OK
- [ ] No leftover DEBUG-only hooks (`DS_*` env switches) in shipping code

## Privacy & safety (non-negotiables)
- [ ] No network request carries personal financial data (there is no such path)
- [ ] Background-snapshot masking still covers financial content
- [ ] "Delete my numbers" removes only user entries; bundled data untouched
- [ ] Source citations and methodology disclosures present (Trust Center)
- [ ] No individualized financial/investment/legal/tax advice added
- [ ] Privacy manifest present and accurate

## Accessibility
- [ ] Spot-check largest Dynamic Type (AX5) on changed screens
- [ ] VoiceOver labels sensible on new/changed UI
- [ ] Light + dark, WCAG-AA contrast maintained

## Content & data
- [ ] Benchmark years/sources correct (Census 2019–2023, EIA 2024, BLS 2023)
- [ ] `THRESHOLD_REGISTRY.md` matches the code
- [ ] `CHANGELOG.md` and `IMPLEMENTATION_STATUS.md` updated

## App Store / TestFlight (`[HUMAN]`)
- [ ] Signing Team set; version + build bumped (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`)
- [ ] Privacy labels match reality ("Data Not Collected")
- [ ] Review notes + screenshots ready (see Phase 12 docs)
- [ ] Known limitations noted in release notes
