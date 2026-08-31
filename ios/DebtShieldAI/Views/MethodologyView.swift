import SwiftUI

/// Methods & sources for the Places (relocation) ranking — the credibility layer.
///
/// Everything the ranking uses, where it comes from, and — just as important —
/// what it can't tell you. Naming the limits out loud is the honest posture the
/// whole app keeps.
struct MethodologyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {

                intro

                card("What Places does",
                     paras: [
                        "It takes your real numbers and ranks where in the U.S. they'd leave you the most room each month — first by state (the typical county), then county by county.",
                        "Two things are shown for each place: breathing room (money left over) and risk (how safe that is once normal ups and downs are simulated). They're separate on purpose — a cheap place can still be fragile."
                     ])

                card("Where the numbers come from",
                     rows: [
                        ("Rent", "Each county's typical (median) gross rent — U.S. Census Bureau, ACS 2019–2023."),
                        ("Energy", "Each state's average monthly electricity bill — U.S. EIA."),
                        ("Everyday costs", "Typical U.S. spending for food and the other categories — U.S. Bureau of Labor Statistics, Consumer Expenditure Survey 2023."),
                        ("Job pay", "For \u{201C}same job, new place\u{201D}: each state's median wage for the job — BLS OEWS, May 2023."),
                        ("Your budget", "The income and costs you entered — which never leave this phone.")
                     ])

                card("How the ranking works",
                     paras: [
                        "For every county, it computes what your month would look like living there — your income (or a job's local pay) against that place's typical rent, plus your own food and debt — and sorts by money left over. The rent is Census gross rent, which already includes utilities, so it isn't double-counted. A state's rank is its median county, so one unusually cheap county can't flatter it.",
                        "Risk is a Monte Carlo simulation: 300 runs of the year ahead on the budget you'd have there, reading the odds of running short at some point — banded low, some, or higher. It's seeded, so a place's risk never changes between looks."
                     ])

                card("What it can't tell you",
                     paras: [
                        "These are typical figures, not a quote. A county's median rent isn't your exact apartment, and typical costs aren't a guarantee.",
                        "For a job's pay, the figure is that state's median wage shown as an estimated take-home (about 78% of gross, a rough blend of federal, FICA and typical state tax) — a ballpark to compare places, not your real paycheck.",
                        "It doesn't yet include state income taxes, insurance, transport, childcare or healthcare, and it never includes the upfront cost of moving — a place that looks cheaper each month can still cost thousands to move to, and a job may or may not exist there. Weigh those separately.",
                        "A state where a job isn't reported is simply left out, never guessed. And none of this is advice to move — it's perspective on where your money stretches."
                     ])
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Methods & sources")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var intro: some View {
        Text("Places is meant to be checkable. Here's exactly what goes into it, where every figure comes from, and what it honestly can't tell you.")
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func card(_ title: String, paras: [String]) -> some View {
        Card {
            SectionHeader(title: title)
            ForEach(paras, id: \.self) { p in
                Text(p)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func card(_ title: String, rows: [(String, String)]) -> some View {
        Card {
            SectionHeader(title: title)
            ForEach(rows, id: \.0) { label, value in
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(Theme.Typography.body.weight(.semibold))
                    Text(value)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#if DEBUG
#Preview { NavigationStack { MethodologyView() } }
#endif
