#!/usr/bin/env bash
#
# Dependency-free secret scan over git-tracked files. High-signal patterns only,
# to avoid false positives that would break CI. For deeper scanning, add a
# dedicated tool (e.g. gitleaks) as a separate CI step later.
#
# Exits non-zero if any likely secret is found.
#
set -uo pipefail

cd "$(dirname "$0")/.."

# High-signal patterns: private keys, cloud/provider tokens.
PATTERNS=(
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'AKIA[0-9A-Z]{16}'                 # AWS access key id
  'AIza[0-9A-Za-z_\-]{35}'           # Google API key
  'xox[baprs]-[0-9A-Za-z-]{10,}'     # Slack token
  'ghp_[0-9A-Za-z]{36}'              # GitHub personal access token
  'sk_live_[0-9A-Za-z]{16,}'         # Stripe live secret key
)

found=0
# Scan tracked files only; skip this script and lockfiles/binaries.
FILES=$(git ls-files | grep -vE '(^scripts/scan_secrets\.sh$|\.pkl$|\.png$|\.jpg$|\.pdf$)')

for pat in "${PATTERNS[@]}"; do
  while IFS= read -r file; do
    [ -z "$file" ] && continue
    if LC_ALL=C grep -nEI "$pat" "$file" >/dev/null 2>&1; then
      echo "POTENTIAL SECRET ($pat) in:"
      LC_ALL=C grep -nEI "$pat" "$file" | sed 's/^/   /'
      found=1
    fi
  done <<< "$FILES"
done

if [ "$found" -ne 0 ]; then
  echo ""
  echo "FAILED: potential secret(s) found. Remove them and rotate the credential."
  exit 1
fi

echo "OK — no high-signal secrets found in tracked files."
