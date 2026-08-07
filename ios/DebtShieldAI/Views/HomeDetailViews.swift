import SwiftUI

// The home screen is a compact dashboard of tiles; these are the screens each
// tile opens. Keeping them here — one tap deep — is what lets the home itself
// stay short and glanceable instead of one long scroll.

// MARK: - Verdict detail

/// The full read behind the home's slim verdict banner: the plain-language
/// verdict, where it sits on the road from clear to debt, the arithmetic that
/// produced it, and — when money is tight or short — the first place to start.
struct SituationDetailView: View {
    let store: MoneyPlanStore

    private var plan: MoneyPlan { store.plan }

    private var allMonths: [MonthRecord] {
        var months = store.history.reversed().map { $0 }
        if plan.isComplete, !store.month.isEmpty {
            months.append(MonthRecord(monthKey: store.month, plan: plan))
        }
        return months
    }

    private var read: SituationRead? {
        SituationEngine.assess(plan: plan, months: allMonths)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if let read {
                    let color = HomeDetailStyle.color(read.situation)
                    Card {
                        HStack(alignment: .center, spacing: Theme.Spacing.regular) {
                            Image(systemName: read.situation.symbol)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(color, in: Circle())
                                .accessibilityHidden(true)
                            Text(read.headline)
                                .font(Theme.Typography.title)
                                .foregroundStyle(color)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text(.init(read.detail))
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        SituationScale(situation: read.situation, color: color)
                            .padding(.top, Theme.Spacing.tight)
                    }

                    if let why = situationWhy {
                        Card {
                            SectionHeader(title: "How we got there")
                            Text(.init(why))
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if let status = plan.status, status != .okay, let biggest = plan.biggestEssential {
                        Card {
                            Label("Where to start", systemImage: "arrow.up.forward.circle.fill")
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.brand)
                            Text(nextStepText(biggest: biggest))
                                .font(Theme.Typography.subheadline)
                                .foregroundStyle(Theme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Where you stand")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// The same numbers the reader entered, put back in a sentence so the verdict
    /// never feels like a black box.
    private var situationWhy: String? {
        guard let income = plan.monthlyIncome, income > 0,
              let share = plan.essentialsShare,
              let safeLine = plan.safeLineAmount,
              let left = plan.moneyLeft,
              let status = plan.status else { return nil }
        let essentials = plan.essentialsTotal
        let pct = Int((share * 100).rounded())

        var debtNote = ""
        if let debt = plan.debtPayments, debt > 0 {
            let debtPct = Int(((debt / income) * 100).rounded())
            if debtPct >= 20 {
                debtNote = " Of that, debt payments alone take about **\(debtPct)%** of your income — the usual comfortable ceiling is 20%."
            }
        }

        switch status {
        case .over:
            return "Your basics come to **\(money(essentials))** a month, but you bring in **\(money(income))** — that's **\(money(-left))** more going out than coming in.\(debtNote)"
        case .tight:
            let over = max(0, essentials - safeLine)
            return "Your basics come to **\(money(essentials))** — about **\(pct)%** of the **\(money(income))** you earn. The comfortable line is 55% (**\(money(safeLine))**), so you're about **\(money(over))** over it, with only **\(money(left))** left to absorb a surprise.\(debtNote)"
        case .okay:
            if share > MoneyPlan.safeLineShare {
                return "Your basics are **\(money(essentials))** — about **\(pct)%** of your **\(money(income))**, a little past the 55% line. But **\(money(left))** is left over each month, a comfortable cushion.\(debtNote)"
            }
            return "Your basics come to **\(money(essentials))** — about **\(pct)%** of the **\(money(income))** you earn, under the 55% line (**\(money(safeLine))**). That's the room you're seeing.\(debtNote)"
        }
    }

    private func nextStepText(biggest: EssentialSegment) -> String {
        var text = "Your biggest cost is \(biggest.label.lowercased()) at \(money(biggest.amount)). Trimming even a little there frees up the most — every $50 less is $50 back this month."
        if biggest.kind == .housing, let movable = plan.biggestMovableEssential {
            text += " Rent's the hardest to change fast, so \(movable.label.lowercased()) (\(money(movable.amount))) is often an easier place to start."
        }
        return text
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

// MARK: - Year-ahead detail

/// The odds screen the "Year ahead" tile opens — the Monte Carlo result in full,
/// plus your month-to-month history for context.
struct OutlookDetailView: View {
    let result: MonteCarloResult?
    var topLever: SensitivityLever? = nil
    var tightThisMonth: Bool = false
    var months: [MonthRecord] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if let result {
                    OutlookCard(result: result, topLever: topLever, tightThisMonth: tightThisMonth)

                    if months.count >= 2 {
                        Card {
                            SectionHeader(title: "Your months",
                                          subtitle: "How much you had left, month to month")
                            MonthlyTrendView(months: months)
                                .padding(.top, Theme.Spacing.tight)
                        }
                    }
                } else {
                    Card {
                        Text("Working out your odds…")
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("The year ahead")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { UserDefaults.standard.set(true, forKey: "debtshield.opened.yearAhead") }
    }
}

// MARK: - Breakdown detail

/// The "Where it goes" screen — every essential as a share of income, the money
/// left, and the month-to-month trend.
struct BreakdownDetailView: View {
    let store: MoneyPlanStore

    private var plan: MoneyPlan { store.plan }

    private var allMonths: [MonthRecord] {
        var months = store.history.reversed().map { $0 }
        if plan.isComplete, !store.month.isEmpty {
            months.append(MonthRecord(monthKey: store.month, plan: plan))
        }
        return months
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                Card {
                    SectionHeader(title: "Where it goes")
                    ForEach(plan.segments) { segment in
                        HStack(spacing: Theme.Spacing.regular) {
                            Circle()
                                .fill(Theme.essentialColor(segment.kind))
                                .frame(width: 12, height: 12)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(segment.label)
                                    .font(Theme.Typography.body)
                                if let share = plan.share(of: segment) {
                                    Text("\(Int((share * 100).rounded()))% of income")
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }
                            Spacer()
                            Text(money(segment.amount))
                                .font(Theme.Typography.money())
                                .foregroundStyle(.primary)
                        }
                        .frame(minHeight: Theme.minimumTapTarget)
                        .accessibilityElement(children: .combine)
                    }

                    Divider()

                    HStack {
                        Text(leftoverLabel)
                            .font(Theme.Typography.body.weight(.semibold))
                        Spacer()
                        if let left = plan.moneyLeft {
                            Text(headlineAmount(left))
                                .font(Theme.Typography.money())
                                .foregroundStyle(Theme.statusColor(plan.status ?? .okay))
                        }
                    }
                    .frame(minHeight: 32)
                }

                if allMonths.count >= 2 {
                    Card {
                        SectionHeader(title: "Your months",
                                      subtitle: "How much you had left, month to month")
                        MonthlyTrendView(months: Array(allMonths.suffix(6)))
                            .padding(.top, Theme.Spacing.tight)
                    }
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Your spending")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var leftoverLabel: String {
        guard let left = plan.moneyLeft else { return "Left over" }
        return left >= 0 ? "Left over" : "Over by"
    }

    private func headlineAmount(_ left: Double) -> String {
        let magnitude = left.magnitude.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return left >= 0 ? magnitude : "−\(magnitude)"
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

// MARK: - Shared style

enum HomeDetailStyle {
    static func color(_ situation: Situation) -> Color {
        switch situation {
        case .good: return Theme.statusColor(.okay)
        case .watch: return Theme.brand
        case .tight, .headingToDebt: return Theme.statusColor(.tight)
        case .goingIntoDebt, .deepInDebt: return Theme.statusColor(.over)
        }
    }
}

/// A small "where you stand" track — a calm gradient from clear (green) through
/// tight (amber) to debt (red), with a marker at the current situation. Pure
/// orientation; hidden from VoiceOver since the verdict text carries the meaning.
struct SituationScale: View {
    let situation: Situation
    let color: Color

    private var fraction: CGFloat {
        let steps = max(1, Situation.allCases.count - 1)
        return CGFloat(situation.severity) / CGFloat(steps)
    }

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let dot: CGFloat = 16
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(
                            colors: [
                                Theme.statusColor(.okay).opacity(0.30),
                                Theme.statusColor(.tight).opacity(0.30),
                                Theme.statusColor(.over).opacity(0.30)
                            ],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(height: 8)

                    Circle()
                        .fill(color)
                        .frame(width: dot, height: dot)
                        .overlay(Circle().strokeBorder(Color(uiColor: .systemBackground), lineWidth: 2))
                        .offset(x: min(max(0, fraction * w - dot / 2), w - dot))
                }
                .frame(height: dot)
            }
            .frame(height: 16)

            HStack {
                Text("Clear").font(.caption2).foregroundStyle(Theme.secondaryText)
                Spacer()
                Text("Tight").font(.caption2).foregroundStyle(Theme.secondaryText)
                Spacer()
                Text("In debt").font(.caption2).foregroundStyle(Theme.secondaryText)
            }
        }
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview("Verdict detail") {
    NavigationStack { SituationDetailView(store: .preview(.sampleTight)) }
}

#Preview("Breakdown detail") {
    NavigationStack { BreakdownDetailView(store: .preview(.sampleTight)) }
}
#endif
