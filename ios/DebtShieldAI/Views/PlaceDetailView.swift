import SwiftUI

/// The full cost-of-living picture for one place — rent, energy and food
/// together, plus what a typical local household earns and how their own month
/// looks. Every figure is real bundled data (Census / EIA / BLS), so it gives a
/// complete read of a place, not just a rent number.
struct PlaceDetailView: View {
    let county: ScoredCounty
    let benchmarks: Benchmarks

    private var rent: Double? { county.record.medianGrossRent }
    private var energy: Double? { benchmarks.energy.typicalBill(inState: county.state) }
    private var localIncomeMonthly: Double? { county.record.medianHouseholdIncome.map { $0 / 12 } }
    private var localFood: Double? {
        localIncomeMonthly.flatMap { benchmarks.food.typicalMonthly(forMonthlyIncome: $0) }
    }

    /// A typical local household's month, for the Safe Line bar. Debt isn't in
    /// the county data, so it's left out of the local picture.
    private var localPlan: MoneyPlan {
        MoneyPlan(monthlyIncome: localIncomeMonthly, housing: rent, food: localFood, energy: energy)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                intro
                basicsCard
                if localIncomeMonthly != nil {
                    localCard
                }
                sources
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle(county.county)
        .navigationBarTitleDisplayMode(.large)
    }

    private var intro: some View {
        Text("The full monthly cost of living in \(county.county), \(county.state) — the real typical numbers, so you get the whole picture, not just rent.")
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - The basics

    private var basicsCard: some View {
        Card {
            SectionHeader(title: "The basics here", subtitle: "Typical amounts, per month")
            basicRow(.housing, "Rent", rent, "Census")
            basicRow(.energy, "Energy", energy, "EIA 2024")
            basicRow(.food, "Food", localFood, "BLS 2024")
            if let total = basicsTotal {
                Divider()
                HStack {
                    Text("Basics together")
                        .font(Theme.Typography.body.weight(.semibold))
                    Spacer()
                    Text(money(total))
                        .font(Theme.Typography.money())
                }
                .frame(minHeight: 32)
            }
        }
    }

    private var basicsTotal: Double? {
        let parts = [rent, energy, localFood].compactMap { $0 }
        return parts.isEmpty ? nil : parts.reduce(0, +)
    }

    private func basicRow(_ kind: EssentialKind, _ label: String, _ value: Double?, _ source: String) -> some View {
        HStack(spacing: Theme.Spacing.regular) {
            Circle()
                .fill(Theme.essentialColor(kind))
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(Theme.Typography.body)
                Text(kind == .food ? "typical for a local income · \(source)" : source)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Text(value.map(money) ?? "—")
                .font(Theme.Typography.money())
        }
        .frame(minHeight: Theme.minimumTapTarget)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Typical local household

    private var localCard: some View {
        Card {
            SectionHeader(
                title: "A typical household here",
                subtitle: "What locals earn, and how their month looks"
            )
            if let income = localIncomeMonthly {
                HStack {
                    Text("Typical income")
                        .font(Theme.Typography.body)
                    Spacer()
                    Text(money(income) + "/mo")
                        .font(Theme.Typography.money())
                }
                .frame(minHeight: 32)

                SafeLineBar(plan: localPlan)
                    .padding(.top, Theme.Spacing.tight)

                Text(localSummary)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var localSummary: String {
        guard let income = localIncomeMonthly, let total = basicsTotal else { return "" }
        let left = income - total
        if left >= 0 {
            return "A typical household earns about \(money(income)) a month and spends roughly \(money(total)) on rent, energy and food — leaving about \(money(left)) for everything else."
        }
        return "Even a typical local income of \(money(income)) barely covers the basics here — a sign this is an expensive place to live."
    }

    private var sources: some View {
        Text("Rent and local income: U.S. Census (2019–2023). Energy: EIA (2024). Food: BLS Consumer Expenditure Survey (2024), by income. Debt isn't part of a place's cost of living, so it's not shown here.")
            .font(Theme.Typography.caption)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

#if DEBUG
#Preview {
    // A stand-in county for the preview.
    let record = CountyRecord(
        fips: "06081", state: "California", county: "San Mateo County", year: 2023,
        medianHouseholdIncome: 156000, medianGrossRent: 2893, rentBurdenPct: 30,
        povertyRate: 7, unemploymentRate: 4
    )
    let county = ScoredCounty(record: record, drivers: [], index: nil, riskLevel: nil, missingIndicators: [])
    return NavigationStack { PlaceDetailView(county: county, benchmarks: .previewSample) }
}
#endif
