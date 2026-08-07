#!/usr/bin/env python3
"""Aggregate summary for the DebtShield voluntary impact survey.

Reads anonymous pre/post responses (CSV; see docs/impact/SURVEY_INSTRUMENT.md),
matches them by the self-generated `code`, and prints an honest aggregate summary
— never individual rows, never causal claims. Pure stdlib.

Usage:
  python3 scripts/impact_summary.py [responses.csv] [--out aggregate.csv]
"""
import csv
import sys
from statistics import mean

LIKERT = [
    ("q_understand_position", "Understand where money stands"),
    ("q_understand_left", "Know money left after essentials"),
    ("q_aware_pressure", "Know biggest financial pressure"),
    ("q_confidence_plan", "Confident planning next month"),
    ("q_aware_help", "Know where to find free help"),
]
ACTIONS = [
    ("a_reviewed_expense", "Reviewed a recurring expense"),
    ("a_reduced_category", "Reduced a spending category"),
    ("a_started_cushion", "Started building a cushion"),
    ("a_reconsidered_payment", "Reconsidered a new payment"),
    ("a_used_resource", "Used a free educational resource"),
    ("a_contacted_counselor", "Contacted a free counselor"),
    ("a_compared_housing", "Compared housing costs / a move"),
    ("a_updated_plan", "Updated a monthly plan"),
]
MIN_N = 20  # below this, report counts only and label preliminary

# Guard: nothing resembling a financial figure should be in the data.
BANNED_COLS = {"income", "rent", "debt", "expenses", "salary", "verdict", "county",
               "email", "name", "ssn"}


def num(v):
    v = (v or "").strip()
    if v == "":
        return None
    try:
        n = int(float(v))
        return n if 1 <= n <= 5 else None
    except ValueError:
        return None


def truthy(v):
    return (v or "").strip().lower() in {"1", "y", "yes", "true"}


def load(path):
    with open(path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    if rows:
        cols = {c.lower() for c in rows[0].keys()}
        leaked = cols & BANNED_COLS
        if leaked:
            print(f"REFUSING TO RUN: survey file contains disallowed column(s): {sorted(leaked)}")
            print("The impact survey must never collect financial or identifying data.")
            sys.exit(2)
    return rows


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    path = args[0] if args else "docs/impact/sample_responses.example.csv"
    out = None
    if "--out" in sys.argv:
        out = sys.argv[sys.argv.index("--out") + 1]

    rows = load(path)
    pre = {r["code"].strip(): r for r in rows if r.get("phase", "").strip() == "pre" and r.get("code", "").strip()}
    post = {r["code"].strip(): r for r in rows if r.get("phase", "").strip() == "post" and r.get("code", "").strip()}
    matched = sorted(set(pre) & set(post))

    print("DebtShield impact survey — aggregate summary")
    print("=" * 48)
    print(f"Source: {path}")
    print(f"Responses: {len(rows)}  (pre {len(pre)}, post {len(post)})")
    print(f"Matched pre/post pairs: {len(matched)}")
    print()

    if not matched:
        print("No matched pairs — nothing to summarize yet.")
        return 0

    preliminary = len(matched) < MIN_N
    if preliminary:
        print(f"NOTE: fewer than {MIN_N} matched pairs — results are PRELIMINARY.")
        print("Report counts, not averages, and do not present these as findings.\n")

    agg_rows = []
    print("Understanding & confidence (Likert 1–5), matched pairs:")
    for key, label in LIKERT:
        pairs = [(num(pre[c].get(key)), num(post[c].get(key))) for c in matched]
        pairs = [(a, b) for a, b in pairs if a is not None and b is not None]
        n = len(pairs)
        if n == 0:
            print(f"  - {label}: no data")
            continue
        mp, mo = mean(a for a, _ in pairs), mean(b for _, b in pairs)
        delta = mo - mp
        improved = sum(1 for a, b in pairs if b > a)
        same = sum(1 for a, b in pairs if b == a)
        worse = sum(1 for a, b in pairs if b < a)
        if preliminary:
            print(f"  - {label}: n={n}  improved {improved} / same {same} / worse {worse}")
        else:
            print(f"  - {label}: n={n}  pre {mp:.2f} → post {mo:.2f}  (Δ {delta:+.2f});  ↑{improved} ={same} ↓{worse}")
        agg_rows.append({"measure": label, "n": n, "mean_pre": round(mp, 3),
                         "mean_post": round(mo, 3), "delta": round(delta, 3),
                         "improved": improved, "same": same, "worse": worse})

    print("\nSelf-reported actions (post, matched):")
    for key, label in ACTIONS:
        yes = sum(1 for c in matched if truthy(post[c].get(key)))
        pct = 100.0 * yes / len(matched)
        line = f"  - {label}: {yes}/{len(matched)}"
        if not preliminary:
            line += f"  ({pct:.0f}%)"
        print(line)
        agg_rows.append({"measure": f"action: {label}", "n": len(matched),
                         "mean_pre": "", "mean_post": "", "delta": "",
                         "improved": yes, "same": "", "worse": ""})

    print("\n" + "-" * 48)
    print("Interpretation: these are SELF-REPORTS from people who chose to use")
    print("the app. A pre→post change is correlation over time, NOT proof the app")
    print("caused it (no control group; self-selection). Do not claim causation.")
    print("Always report n, the time period, and this caveat.")

    if out:
        with open(out, "w", newline="", encoding="utf-8") as f:
            w = csv.DictWriter(f, fieldnames=["measure", "n", "mean_pre", "mean_post",
                                              "delta", "improved", "same", "worse"])
            w.writeheader()
            w.writerows(agg_rows)
        print(f"\nWrote aggregate CSV → {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
