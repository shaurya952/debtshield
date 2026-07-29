import SwiftUI

/// The odds ahead — the Monte Carlo result, made human.
///
/// Where the situation card gives a verdict and the trend gives a line, this
/// gives a *probability with a range*: run your numbers across hundreds of
/// possible months, how often do you dip into the red, where might you land,
/// and — the useful part — which single change moves the odds most. The engine
/// (`MonteCarloEngine`) does the maths; this view only phrases it.
struct OutlookCard: View {
    let result: MonteCarloResult
    /// The most effective change, from the sensitivity analysis. Optional so the
    /// card stands alone if it hasn't been computed.
    var topLever: SensitivityLever? = nil
    /// Whether *this month* reads as "tight" on the safe line. Lets the card
    /// reconcile the two views — a month can be tight on share of income yet
    /// steady on dollars ahead — so the reader never sees a bare contradiction.
    var tightThisMonth: Bool = false

    @State private var showWork = false

    private var prob6: Double { result.probNegativeWithin6mo }

    var body: some View {
        Card {
            SectionHeader(title: "The year ahead", subtitle: "Next 12 months · \(basis)")

            HStack(alignment: .center, spacing: Theme.Spacing.comfortable) {
                OddsDial(probability: prob6, tint: tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(headline)
                        .font(Theme.Typography.title)
                        .foregroundStyle(tint)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("chance of a shortfall in the next 6 months")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(headline). About \(pct6) percent chance of a shortfall in the next 6 months.")

            Text(.init(detail))
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            RangeBar(low: result.p10_12mo, mid: result.p50_12mo, high: result.p90_12mo)
                .padding(.top, Theme.Spacing.tight)

            Text(rangeCaption)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            leverRow
            workDisclosure
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: - The biggest lever

    @ViewBuilder
    private var leverRow: some View {
        if let lever = topLever, lever.reduction > 0.02, prob6 >= 0.10 {
            Divider()
            HStack(alignment: .top, spacing: Theme.Spacing.regular) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accentWarm)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(.init("Your biggest lever: **\(lever.label)** would take these odds to about **\(pct(lever.newProbability6mo))%**."))
                    .font(Theme.Typography.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - How we worked this out (transparency)

    private var workDisclosure: some View {
        DisclosureGroup(isExpanded: $showWork) {
            VStack(alignment: .leading, spacing: 6) {
                // Plain-language concept first — what a "simulation" even is —
                // then the specific numbers underneath, for whoever wants them.
                Text(.init(plainConcept))
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, Theme.Spacing.tight)

                Text("The numbers behind it")
                    .font(Theme.Typography.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("\(result.assumptions.runs) simulated months, \(basisLong). Starting from \(money(result.assumptions.startingBalance)) saved.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 2)

                ForEach(result.assumptions.categories) { c in
                    HStack {
                        Text(c.name).font(Theme.Typography.caption)
                        Spacer()
                        Text("\(money(c.mean))  ± \(money(c.sd))/mo")
                            .font(Theme.Typography.caption.monospacedDigit())
                            .foregroundStyle(Theme.secondaryText)
                    }
                }

                if result.assumptions.surpriseApplied {
                    Text("Plus occasional surprise costs — about \(pct(result.assumptions.surpriseChancePerMonth))% of months, around \(money(result.assumptions.surpriseMean)).")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .padding(.top, Theme.Spacing.tight)
        } label: {
            Label("How this works", systemImage: "questionmark.circle")
                .font(Theme.Typography.subheadline.weight(.semibold))
                .foregroundStyle(Theme.brand)
        }
        .tint(Theme.brand)
    }

    /// The Monte Carlo idea in everyday words — no "Monte Carlo", no "standard
    /// deviation". Just: we can't know the future, so we play the month out many
    /// times and count how often it goes wrong.
    private var plainConcept: String {
        let n = result.assumptions.runs
        let base = "Nobody can know the future, so instead of one guess we play your month out **\(n) times over**. In some of those months a bill runs high or a surprise cost lands; in others everything stays calm. Then we simply count how many ended in the red — that share is your chance of going into debt."
        switch result.mode {
        case .personalHistory:
            return base + " The ups and downs come from **your own recent months**, so this sharpens the longer you track."
        case .nationalDefault:
            return base + " Since you've tracked fewer than 3 months, the ups and downs are **typical U.S. swings** for now — track a few months and it starts using your own."
        }
    }

    // MARK: - Wording

    private func pct(_ v: Double) -> Int { Int((v * 100).rounded()) }
    private var pct6: Int { pct(prob6) }

    private var headline: String {
        switch prob6 {
        case ..<0.05: return "Steady year ahead"
        case ..<0.25: return "Mostly steady ahead"
        case ..<0.60: return "A real chance of debt ahead"
        default: return "Debt is likely ahead"
        }
    }

    /// The bridge between this card and the verdict above it. When the month is
    /// tight on share of income but the year still looks steady on dollars, spell
    /// that out — otherwise the two cards read as a contradiction. Kept to one
    /// line; the fuller "why" lives in the situation card's own explainer.
    private var reconcile: String {
        guard tightThisMonth, prob6 < 0.25 else { return "" }
        return " Tight now, but steady ahead — enough is left over each month that debt stays unlikely."
    }

    private var tint: Color {
        switch prob6 {
        case ..<0.05: return Theme.statusColor(.okay)
        case ..<0.25: return Theme.brand
        case ..<0.60: return Theme.statusColor(.tight)
        default: return Theme.statusColor(.over)
        }
    }

    private var detail: String {
        switch prob6 {
        case ..<0.05:
            return "Almost none of those months slipped into the red." + reconcile
        case ..<0.25:
            return "A few slipped into the red — worth a light watch." + reconcile
        case ..<0.60:
            return "A real share slipped into the red. Now's the good time to act."
        default:
            return "Most ended in the red. This needs attention — and there's free help: dial **211**."
        }
    }

    private var rangeCaption: String {
        let inRed = result.p10_12mo < 0 ? ", some of it in the red" : ""
        return "A year out: most likely around \(money(result.p50_12mo)) (\(money(result.p10_12mo)) to \(money(result.p90_12mo))\(inRed))."
    }

    private var basis: String {
        switch result.mode {
        case .personalHistory: return "Based on your own recent months"
        case .nationalDefault: return "Based on typical ups and downs — sharpens as you track more months"
        }
    }

    private var basisLong: String {
        switch result.mode {
        case .personalHistory: return "with the spread measured from your own recent months"
        case .nationalDefault: return "with typical month-to-month ups and downs (you have fewer than 3 months tracked)"
        }
    }

    private func money(_ value: Double) -> String {
        let sign = value < 0 ? "−" : ""
        return sign + abs(value).formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

// MARK: - Odds dial

/// The headline odds as a ring — the number the whole card is about, made big
/// and glanceable. The arc fills with the probability; the percentage sits in
/// the middle in the same tint as the verdict. Decorative (the header carries a
/// full spoken label), so it's hidden from VoiceOver.
private struct OddsDial: View {
    let probability: Double
    let tint: Color

    @ScaledMetric(relativeTo: .title2) private var size: CGFloat = 76

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0.008, min(1, probability)))
                .stroke(tint, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((probability * 100).rounded()))%")
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Range bar

/// A little band showing where the year might end up — p10 to p90 — with the
/// $0 "debt line" marked and the typical (p50) point dotted. The stretch below
/// zero is tinted red.
private struct RangeBar: View {
    let low: Double
    let mid: Double
    let high: Double

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                let w = geo.size.width
                let lo = Swift.min(low, 0)
                let hi = Swift.max(high, 0)
                let span = Swift.max(hi - lo, 1)
                let xLow = CGFloat((low - lo) / span) * w
                let xHigh = CGFloat((high - lo) / span) * w
                let xZero = CGFloat((0 - lo) / span) * w
                let xMid = CGFloat((mid - lo) / span) * w

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(uiColor: .tertiarySystemFill))
                        .frame(height: 12)

                    Capsule()
                        .fill(Theme.brand.opacity(0.35))
                        .frame(width: Swift.max(4, xHigh - xLow), height: 12)
                        .offset(x: xLow)

                    if low < 0 {
                        Capsule()
                            .fill(Theme.statusColor(.over).opacity(0.55))
                            .frame(width: Swift.max(0, xZero - xLow), height: 12)
                            .offset(x: xLow)
                    }

                    Rectangle()
                        .fill(Color.primary.opacity(0.8))
                        .frame(width: 2, height: 22)
                        .offset(x: xZero - 1)

                    Circle()
                        .fill(Color.primary)
                        .frame(width: 11, height: 11)
                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 2))
                        .offset(x: xMid - 5.5)
                }
                .frame(height: 22)
            }
            .frame(height: 22)

            HStack {
                Text(money(low)).font(.caption2).foregroundStyle(Theme.secondaryText)
                Spacer()
                Text("$0").font(.caption2.weight(.semibold)).foregroundStyle(Theme.secondaryText)
                Spacer()
                Text(money(high)).font(.caption2).foregroundStyle(Theme.secondaryText)
            }
        }
        .accessibilityHidden(true)
    }

    private func money(_ value: Double) -> String {
        let sign = value < 0 ? "−" : ""
        return sign + "$" + abs(value).formatted(.number.notation(.compactName).precision(.fractionLength(0)))
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            OutlookCard(result: MonteCarloResult(
                mode: .nationalDefault, runs: 500,
                assumptions: .init(mode: .nationalDefault, runs: 500, startingBalance: 0,
                                   categories: [.init(name: "Income", mean: 5000, sd: 350),
                                                .init(name: "Food", mean: 400, sd: 60)],
                                   surpriseApplied: true, surpriseChancePerMonth: 0.15, surpriseMean: 300),
                probNegativeWithin6mo: 0.02, probNegativeWithin12mo: 0.03,
                endingBalances6mo: [15000], endingBalances12mo: [33000, 34000, 35000, 36000, 37000]))
            OutlookCard(
                result: MonteCarloResult(
                    mode: .nationalDefault, runs: 500,
                    assumptions: .init(mode: .nationalDefault, runs: 500, startingBalance: 0,
                                       categories: [.init(name: "Income", mean: 3000, sd: 210),
                                                    .init(name: "Energy", mean: 300, sd: 66)],
                                       surpriseApplied: true, surpriseChancePerMonth: 0.15, surpriseMean: 300),
                    probNegativeWithin6mo: 0.49, probNegativeWithin12mo: 0.51,
                    endingBalances6mo: [0], endingBalances12mo: [-500, 100, 1300, 2000, 2500]),
                topLever: SensitivityLever(input: .essential(.energy), label: "Cut energy $100",
                                           newProbability6mo: 0.28, reduction: 0.21))
        }
        .padding()
    }
}
#endif
