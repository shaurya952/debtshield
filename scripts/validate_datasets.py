#!/usr/bin/env python3
"""Validate the bundled benchmark datasets DebtShield ships.

Checks structure and sanity of the CSVs the app actually reads. Pure stdlib so
it runs anywhere (locally and in CI). Exits non-zero on any error; warnings do
not fail the build. See DATA_DICTIONARY.md (Phase 3) for the authoritative schema.
"""
import csv
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "ios", "DebtShieldAI", "Resources")

errors: list[str] = []
warnings: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def warn(msg: str) -> None:
    warnings.append(msg)


def read(name: str) -> list[dict]:
    path = os.path.join(RES, name)
    if not os.path.exists(path):
        err(f"{name}: file not found at {path}")
        return []
    with open(path, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))


def is_number(v: str) -> bool:
    try:
        float(v)
        return True
    except (TypeError, ValueError):
        return False


def validate_counties() -> None:
    name = "real_county_data.csv"
    rows = read(name)
    required = {"fips", "state", "county", "acs_median_household_income", "acs_median_gross_rent"}
    if not rows:
        return
    missing = required - set(rows[0].keys())
    if missing:
        err(f"{name}: missing required columns {sorted(missing)}")
        return
    if len(rows) < 3000:
        err(f"{name}: expected ~3,144 counties, found {len(rows)}")
    seen_fips = set()
    bad_num = 0
    negative = 0
    for i, r in enumerate(rows, start=2):
        fips = (r.get("fips") or "").strip()
        if not fips:
            err(f"{name}:{i}: empty fips")
        elif not fips.isdigit() or len(fips) != 5:
            warn(f"{name}:{i}: fips '{fips}' is not a 5-digit code")
        if fips in seen_fips:
            err(f"{name}:{i}: duplicate fips {fips}")
        seen_fips.add(fips)
        if not (r.get("state") or "").strip():
            err(f"{name}:{i}: empty state")
        for col in ("acs_median_household_income", "acs_median_gross_rent"):
            v = (r.get(col) or "").strip()
            if v == "":
                continue  # the app tolerates missing values (guards > 0)
            if not is_number(v):
                bad_num += 1
            elif float(v) < 0:
                negative += 1
    if bad_num:
        err(f"{name}: {bad_num} non-numeric income/rent values")
    if negative:
        err(f"{name}: {negative} negative income/rent values")
    print(f"  counties: {len(rows)} rows, {len(seen_fips)} unique fips")


def validate_energy() -> None:
    name = "energy_by_state.csv"
    rows = read(name)
    if not rows:
        return
    if "state" not in rows[0] or "avg_monthly_electric_bill" not in rows[0]:
        err(f"{name}: missing required columns")
        return
    if not (45 <= len(rows) <= 60):
        warn(f"{name}: expected ~51 states+DC, found {len(rows)}")
    for i, r in enumerate(rows, start=2):
        if not (r.get("state") or "").strip():
            err(f"{name}:{i}: empty state")
        v = (r.get("avg_monthly_electric_bill") or "").strip()
        if not is_number(v) or float(v) <= 0:
            err(f"{name}:{i}: invalid bill '{v}'")
    print(f"  energy: {len(rows)} rows")


def validate_food() -> None:
    name = "food_by_income_band.csv"
    rows = read(name)
    if not rows:
        return
    needed = {"income_low", "income_high", "avg_annual_food"}
    if needed - set(rows[0].keys()):
        err(f"{name}: missing required columns")
        return
    prev_low = -1.0
    for i, r in enumerate(rows, start=2):
        low = (r.get("income_low") or "").strip()
        high = (r.get("income_high") or "").strip()
        annual = (r.get("avg_annual_food") or "").strip()
        if not is_number(low) or float(low) < 0:
            err(f"{name}:{i}: invalid income_low '{low}'")
            continue
        if high != "" and (not is_number(high) or float(high) <= float(low)):
            err(f"{name}:{i}: income_high '{high}' must exceed income_low '{low}'")
        if not is_number(annual) or float(annual) <= 0:
            err(f"{name}:{i}: invalid avg_annual_food '{annual}'")
        if float(low) < prev_low:
            err(f"{name}:{i}: bands are not sorted by income_low")
        prev_low = float(low)
    print(f"  food: {len(rows)} income bands")


def main() -> int:
    print("Validating bundled datasets in ios/DebtShieldAI/Resources …")
    validate_counties()
    validate_energy()
    validate_food()
    for w in warnings:
        print(f"WARN  {w}")
    for e in errors:
        print(f"ERROR {e}")
    if errors:
        print(f"\nFAILED with {len(errors)} error(s), {len(warnings)} warning(s).")
        return 1
    print(f"\nOK — datasets valid ({len(warnings)} warning(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
