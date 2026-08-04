# Security Policy

DebtShield is a privacy-first, on-device app. Personal financial data (income,
rent, debt, expenses, verdicts, simulation results) is stored only on the user's
device and is never transmitted. Comparison datasets are bundled and read-only.

## Reporting a vulnerability
Please report suspected security or privacy issues **privately**:

- Preferred: GitHub → **Security** tab → **Report a vulnerability** (private
  advisory), if enabled for this repository.
- Otherwise: email the maintainer at the address on the project's website
  contact page.

Do **not** open a public issue for a security report. Include: affected
version/commit, a clear description, reproduction steps, and impact. We aim to
acknowledge within a few business days.

## Scope of special interest
- Any path by which personal financial data could leave the device.
- Exposure of financial content in OS snapshots, logs, or backups.
- Committed secrets or credentials (CI runs a secret scan; see
  `scripts/scan_secrets.sh`).

## Please do not
- Access, modify, or exfiltrate other people's data.
- Run denial-of-service or destructive tests.
- Publicly disclose before a fix is available.

Thank you for helping keep DebtShield users safe.
