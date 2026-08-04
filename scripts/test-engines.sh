#!/usr/bin/env bash
#
# Run DebtShield's engine unit tests (DebtShieldAITests). Used locally and in CI.
# The tests are pure-logic and fast (<1s); the UI-test target is not run here.
#
# Usage:
#   scripts/test-engines.sh
#   DEST='platform=iOS Simulator,name=iPhone 16' scripts/test-engines.sh
#
set -euo pipefail

DEST="${DEST:-platform=iOS Simulator,name=iPhone 17 Pro}"

xcodebuild test \
  -project ios/DebtShieldAI.xcodeproj \
  -scheme DebtShieldAI \
  -destination "$DEST" \
  -only-testing:DebtShieldAITests
