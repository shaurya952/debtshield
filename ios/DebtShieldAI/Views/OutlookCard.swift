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

    @State private var showWork = false

    private var prob6: Double { result.probNegativeWithin6mo }

    var body: some View {
        Card {
            SectionHeader(title: "The year ahead", subtitle: basis)

            HStack(alignment: .center, spacing: Theme.Spacing.regular) {
                Image(systemName: symbol)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(tint, in: Circle())
                    .accessibilityHidden(true)
                Text(headline)
                    .font(Theme.Typography.title)
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
            }

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
            Text("How we worked this out")
                .font(Theme.Typography.subheadline.weight(.semibold))
                .foregroundStyle(Theme.brand)
        }
        .tint(Theme.brand)
    }

    // MARK: - Wording

    private func pct(_ v: Double) -> Int { Int((v * 100).rounded()) }
    private var pct6: Int { pct(prob6) }
    private var ciMargin: Int { Int((result.probNegative6moCI.margin * 100).rounded()) }

    private var headline: String {
        switch prob6 {
        case ..<0.05: return "You're on steady ground"
        case ..<0.25: return "Mostly steady ahead"
        case ..<0.60: return "A real chance of debt ahead"
        default: return "Debt is likely ahead"
        }
    }

    private var symbol: String {
        switch prob6 {
        case ..<0.05: return "checkmark.seal.fill"
        case ..<0.25: return "hand.thumbsup.fill"
        case ..<0.60: return "exclamationmark.triangle.fill"
        default: return "exclamationmark.octagon.fill"
        }
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
        let base = "We ran your numbers across \(result.runs) possible versions of the next 6 months. "
        switch prob6 {
        case ..<0.05:
            return base + "Almost none slipped into the red — you've got a solid margin."
        case ..<0.25:
            return base + "About **\(pct6)%** (give or take \(ciMargin)) dipped into the red at some point — worth a light watch."
        case ..<0.60:
            return base + "About **\(pct6)%** (give or take \(ciMargin)) dipped into the red. Now's the time to act."
        default:
            return base + "Most of them — about **\(pct6)%** — ended in the red. This needs attention, and there's free help: dialling **211** reaches local support."
        }
    }

    private var rangeCaption: String {
        let inRed = result.p10_12mo < 0 ? " Part of that range is in the red." : ""
        return "By this time next year you'd most likely be around \(money(result.p50_12mo)), somewhere between \(money(result.p10_12mo)) and \(money(result.p90_12mo)).\(inRed)"
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
