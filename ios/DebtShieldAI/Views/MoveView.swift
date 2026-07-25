import SwiftUI

/// "Could you afford to move here?" — the housing-decision engine.
///
/// Pick any place; it uses that place's real typical rent (Census) and energy
/// bill (EIA) with your own numbers to show whether living there keeps you safe
/// or tips you into debt — plus the rent you could afford and the income you'd
/// need. Grounded in bundled data, computed on device.
struct MoveView: View {
    let store: MoneyPlanStore
    let dataStore: DataStore
    let benchmarks: Benchmarks

    @State private var selectedFIPS: String?
    @State private var isPicking = false
    @State private var incomeOverride: Double?

    private var place: ScoredCounty? {
        guard let fips = selectedFIPS, let dataset = dataStore.dataset else { return nil }
        return dataset.county(fips: fips)
    }

    private var outlook: MoveOutlook? {
        guard let place else { return nil }
        let energy = benchmarks.energy.typicalBill(inState: place.state)
        return AffordabilityEngine.outlook(
            current: store.plan, place: place, stateEnergy: energy, incomeOverride: incomeOverride
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                intro
                placeCard
                if let place {
                    fullPictureLink(place)
                }
                if let outlook {
                    incomeCard
                    resultCard(outlook)
                    thresholdsCard(outlook)
                } else if place != nil {
                    Text("There's no typical rent on record for that place, so I can't run the numbers. Try a nearby county.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Could you afford a move?")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPicking) {
            if let searchIndex = dataStore.searchIndex {
                AreaPickerView(searchIndex: searchIndex) { county in
                    selectedFIPS = county.record.fips
                }
            }
        }
        .onAppear {
            if incomeOverride == nil { incomeOverride = store.plan.monthlyIncome }
        }
    }

    // MARK: - Intro + place

    private var intro: some View {
        Text("Thinking about moving? Pick a place and I'll use its real typical rent and energy bill, with your own numbers, to show whether you could afford to live there — before you go.")
            .font(Theme.Typography.body)
            .foregroundStyle(Theme.secondaryText)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var placeCard: some View {
        Button {
            isPicking = true
        } label: {
            if let place {
                ActionRowLabel(
                    systemImage: "mappin.and.ellipse",
                    title: "\(place.county), \(place.state)",
                    subtitle: "Typical rent \(money(place.record.medianGrossRent ?? 0)) · Tap to change"
                )
            } else {
                ActionRowLabel(
                    systemImage: "map",
                    title: "Pick a place to check",
                    subtitle: "Any county in the U.S."
                )
            }
        }
        .buttonStyle(PressableCardStyle())
    }

    @ViewBuilder
    private func fullPictureLink(_ place: ScoredCounty) -> some View {
        NavigationLink {
            PlaceDetailView(county: place, benchmarks: benchmarks)
        } label: {
            ActionRowLabel(
                systemImage: "list.bullet.rectangle",
                title: "See the full cost of living here",
                subtitle: "Rent, energy and food — plus what locals earn"
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    private var incomeCard: some View {
        Card {
            SectionHeader(
                title: "Your pay there",
                subtitle: "Keep your current pay, or try a new job's number"
            )
            CurrencyField(title: "Monthly take-home", value: $incomeOverride)
        }
    }

    // MARK: - Result

    private func resultCard(_ outlook: MoveOutlook) -> some View {
        let color = toneColor(outlook.tone)
        return VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            Text(outlook.headline)
                .font(Theme.Typography.title)
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)

            Text(outlook.detail)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            SafeLineBar(plan: outlook.projected)
                .padding(.top, Theme.Spacing.tight)

            if let now = outlook.currentLeft {
                Divider()
                HStack {
                    Text("Where you are now")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                    Spacer()
                    Text("\(signedMoney(now)) → \(signedMoney(outlook.projectedLeft))")
                        .font(Theme.Typography.money())
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Now \(signedMoney(now)) left, there \(signedMoney(outlook.projectedLeft))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.comfortable)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .fill(color.opacity(0.10))
                }
                .shadow(color: Theme.heroShadow, radius: 12, x: 0, y: 6)
        }
    }

    private func thresholdsCard(_ outlook: MoveOutlook) -> some View {
        Card {
            SectionHeader(title: "The numbers behind it")
            row("Typical rent there",
                money(outlook.typicalRent) + " · Census")
            if let energy = outlook.typicalEnergy {
                row("Typical energy there", money(energy) + "/mo · EIA")
            }
            row("Most rent you could afford here",
                outlook.maxAffordableRent > 0
                    ? money(outlook.maxAffordableRent) + " to stay under your safe line"
                    : "Your other costs already use it up")
            row("Income to live here comfortably",
                money(outlook.incomeNeeded) + "/mo")
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.Typography.subheadline)
            Text(value)
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 40)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Helpers

    private func toneColor(_ tone: MoveOutlook.Tone) -> Color {
        switch tone {
        case .good: return Theme.statusColor(.okay)
        case .tight: return Theme.statusColor(.tight)
        case .over: return Theme.statusColor(.over)
        }
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    private func signedMoney(_ value: Double) -> String {
        let magnitude = money(abs(value))
        return value >= 0 ? magnitude : "−\(magnitude)"
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MoveView(store: .preview(.sampleTight), dataStore: DataStore(), benchmarks: .previewSample)
    }
}
#endif
