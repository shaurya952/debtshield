# App Store Optimization — v1.1 metadata changes

_Written 2026-10-25, two days after v1.0 (build 14) went live. Apply these when
cutting v1.1: **subtitle and keywords can only be changed with a new version
submission**, so they cannot be fixed on the live listing._

## The problem

The App Store indexes exactly three fields for search: the **app name** (30
chars), the **subtitle** (30), and the **keywords** field (100). The description
is **not** indexed at all. That is the entire searchable surface — 160
characters — and v1.0 wastes part of it.

Measured 2026-10-25 via the App Store Connect API:

```
Name:     Headroom: Cost of Living                               24/30
Subtitle: See where you'd thrive                                 22/30
Keywords: cost of living,relocation,moving,budget,rent,salary,
          affordability,move,city,paycheck,save,private          97/100
```

Two things are costing us:

1. **`cost of living` is duplicated.** It is already in the app name, which
   Apple indexes, so repeating it in keywords spends ~15 characters on nothing.
   `move` / `moving` / `relocation` overlap similarly.
2. **The subtitle is a slogan, not a search surface.** Nobody searches
   "thrive". That is 22 indexed characters returning no reach.

## The change

```
Subtitle: Compare rent & pay by state                            27/30

Keywords: relocate,moving,salary,wages,budget,affordable,expenses,
          cheapest,paycheck,housing,money,cities,city            99/100
```

No word repeats across name, subtitle and keywords, so every character buys new
coverage. Apple also combines terms *across* the three fields into phrases — so
"Cost of Living" in the name plus `cheapest` and `cities` in keywords can match
a search for "cheapest cities cost of living" without spending characters on
the phrase itself.

### Rules followed

- No word appears in more than one indexed field.
- No spaces after commas in the keywords field (a space costs a character).
- Singular and plural both included only where Apple's stemming is unreliable
  and the term is high value (`city` / `cities`).
- No competitor names and no trademarked terms — that is a rejection risk.

## What this does and does not do

Keywords make the app **eligible** to rank. **Downloads, rating count and
average rating decide where it actually places.** As of 2026-10-25 the app has
**0 ratings** and two days of history, so no amount of text optimisation will
put it above established apps for a competitive term like "cost of living".

Verified on 2026-10-25 via the iTunes Search API:

| Query | Result |
| --- | --- |
| `Headroom Cost of Living` | **#1** |
| `Headroom` | not in top 11 |
| `cost of living by state` | not in top 8 |
| `where to move cost of living` | not in top 11 |

So the app **is** indexed. It simply has no popularity signal yet. The text
changes above and genuine ratings have to happen together; neither works alone.

## Also shipping in v1.1

- The onboarding tint fix (merged in #40) — v1.0 renders the first-run buttons
  in iOS default blue instead of the Headroom teal.

## Checklist when cutting v1.1

- [ ] Update **Subtitle** in App Store Connect → App Information
- [ ] Update **Keywords** in the v1.1 version page
- [ ] Leave the **app name** alone — "Headroom: Cost of Living" already carries
      the highest-value phrase, and renaming resets name recognition
- [ ] Re-measure ranking with the iTunes Search API a week after release and
      record the numbers here, so the next change is based on evidence
