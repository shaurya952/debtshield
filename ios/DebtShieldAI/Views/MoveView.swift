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
    /// Optional place to open on — set when arriving from the Places ranking so
    /// the screen starts on that county instead of the empty picker.
    var initialFIPS: String? = nil
    /// Optional pay to open on — carried from Places so the detail matches the
    /// number the ranking used.
    var initialIncome: Double? = nil
    /// Optional shortlist store — when present, a star saves this place.
    var saved: SavedPlacesStore? = nil

    @State private var selectedFIPS: String?
    @State private var isPicking = false
    @State private var incomeOverride: Double?
    /// A rendered, shareable summary image — the "tell a friend" moment. Rebuilt
    /// whenever the place or pay changes.
    @State private var shareImage: Image?

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
                    if let place { costOfLivingCard(place) }
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
        .toolbar {
            if let shareImage {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareImage,
                              preview: SharePreview("Where my money goes furthest", image: shareImage)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Share this place")
                }
            }
            if let saved, let place {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saved.toggle(place.record.fips)
                    } label: {
                        Image(systemName: saved.isSaved(place.record.fips) ? "star.fill" : "star")
                    }
                    .accessibilityLabel(saved.isSaved(place.record.fips) ? "Remove from saved" : "Save this place")
                }
            }
        }
        .sheet(isPresented: $isPicking) {
            if let searchIndex = dataStore.searchIndex {
                AreaPickerView(searchIndex: searchIndex) { county in
                    selectedFIPS = county.record.fips
                }
            }
        }
        .onAppear {
            if selectedFIPS == nil { selectedFIPS = initialFIPS }
            if incomeOverride == nil { incomeOverride = initialIncome ?? store.plan.monthlyIncome }
        }
        .task(id: "\(selectedFIPS ?? "")#\(Int(incomeOverride ?? 0))") {
            shareImage = renderShareCard()
        }
    }

    /// Render the shareable card to an image on the main actor. `nil` until a place
    /// with a runnable outlook is chosen.
    @MainActor private func renderShareCard() -> Image? {
        guard let place, let outlook else { return nil }
        let renderer = ImageRenderer(content: ShareCard(place: place, outlook: outlook))
        renderer.scale = 3
        guard let ui = renderer.uiImage else { return nil }
        return Image(uiImage: ui)
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
                    title: place.displayName,
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

    /// How rent differs *here* versus the U.S. Census "gross rent" already bundles
    /// the renter's utilities, so this compares one whole housing+utilities figure —
    /// it never adds a separate utility cost on top (that would double-count), and
    /// it's honest that the other costs don't vary by place in the data yet.
    private func costOfLivingCard(_ place: ScoredCounty) -> some View {
        let rentHere = place.record.medianGrossRent ?? 0
        let rentUS = benchmarks.nationalRent
        return Card {
            SectionHeader(title: "Cost of living here",
                          subtitle: "How rent compares to the U.S. average")
            costRow("house.fill", "Rent — utilities included", here: rentHere, us: rentUS,
                    tint: Theme.essentialColor(.housing))
            Text("Census gross rent already includes typical utilities (electricity, gas, water). Other costs — food, getting around, state taxes and insurance — don't vary by place in this data yet, so this keeps them at your current amounts rather than guessing.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func costRow(_ symbol: String, _ label: String, here: Double, us: Double, tint: Color) -> some View {
        let diff = us > 0 ? (here - us) / us : 0
        let pct = Int((abs(diff) * 100).rounded())
        let higher = here >= us
        let comparison = pct == 0 ? "about the U.S. average"
            : "\(pct)% \(higher ? "higher" : "lower") than the U.S."
        let color = pct == 0 ? Theme.secondaryText
            : (higher ? Theme.statusColor(.tight) : Theme.statusColor(.okay))
        return HStack(spacing: Theme.Spacing.regular) {
            AppIconBadge(systemImage: symbol, tint: tint, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(Theme.Typography.body.weight(.semibold))
                Text("U.S. average \(money(us))/mo")
                    .font(Theme.Typography.caption).foregroundStyle(Theme.secondaryText)
            }
            Spacer(minLength: Theme.Spacing.tight)
            VStack(alignment: .trailing, spacing: 2) {
                Text(money(here)).font(Theme.Typography.money()).monospacedDigit()
                Text(comparison).font(.caption2).foregroundStyle(color)
                    .multilineTextAlignment(.trailing)
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) here \(money(here)) a month, \(comparison)")
    }

    private func thresholdsCard(_ outlook: MoveOutlook) -> some View {
        Card {
            SectionHeader(title: "Rough guides")
            row("Most rent that would still fit here",
                outlook.maxAffordableRent > 0
                    ? "about " + money(round50(outlook.maxAffordableRent)) + " (utilities included)"
                    : "Your other costs already use it up")
            row("Income to keep a comfortable cushion",
                "about " + money(round50(outlook.incomeNeeded)) + "/mo")
        }
    }

    /// Round to the nearest $50 — these are typical-data estimates, and dollar-exact
    /// figures imply a precision the model doesn't have.
    private func round50(_ value: Double) -> Double { (value / 50).rounded() * 50 }

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

/// The shareable summary, designed to be rendered to an image and posted. Uses
/// explicit colours (not theme tokens) so it looks the same wherever it lands, and
/// carries an honest "estimate, not a recommendation" footer so a screenshot can
/// never be mistaken for advice.
struct ShareCard: View {
    let place: ScoredCounty
    let outlook: MoveOutlook

    private let ink = Color(red: 0.06, green: 0.08, blue: 0.13)
    private let muted = Color(red: 0.35, green: 0.40, blue: 0.49)
    private let green = Color(red: 0.09, green: 0.52, blue: 0.35)
    private let accent = Color(red: 0.18, green: 0.38, blue: 0.94)

    private func money(_ v: Double) -> String {
        let r = (v / 50).rounded() * 50
        return r.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
    private func signed(_ v: Double) -> String {
        let m = money(abs(v)); return v >= 0 ? "+\(m)" : "−\(m)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WHERE MY MONEY GOES FURTHEST")
                .font(.system(size: 13, weight: .bold)).kerning(1.2).foregroundStyle(accent)
            Text(place.displayName)
                .font(.system(size: 30, weight: .heavy, design: .rounded)).foregroundStyle(ink)
                .padding(.top, 8).fixedSize(horizontal: false, vertical: true)

            Text(signed(outlook.projectedLeft))
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(outlook.projectedLeft >= 0 ? green : Color(red: 0.75, green: 0.22, blue: 0.17))
                .padding(.top, 18)
            Text("left each month here")
                .font(.system(size: 16, weight: .medium)).foregroundStyle(muted)

            if let now = outlook.currentLeft {
                HStack(spacing: 8) {
                    Text("Where you are now").font(.system(size: 15)).foregroundStyle(muted)
                    Spacer()
                    Text("\(signed(now)) → \(signed(outlook.projectedLeft))")
                        .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(ink)
                }
                .padding(.top, 20)
            }
            HStack(spacing: 8) {
                Text("Typical rent (utilities in)").font(.system(size: 15)).foregroundStyle(muted)
                Spacer()
                Text(money(outlook.typicalRent))
                    .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(ink)
            }
            .padding(.top, 10)

            Spacer(minLength: 22)
            HStack(spacing: 7) {
                Image(systemName: "location.north.circle.fill").foregroundStyle(accent)
                Text("Headroom").font(.system(size: 17, weight: .heavy, design: .rounded)).foregroundStyle(ink)
                Spacer()
                Text("Estimate — not a moving recommendation")
                    .font(.system(size: 11)).foregroundStyle(muted)
                    .multilineTextAlignment(.trailing).frame(width: 150)
            }
        }
        .padding(28)
        .frame(width: 360, height: 440, alignment: .topLeading)
        .background(Color.white)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        MoveView(store: .preview(.sampleTight), dataStore: DataStore(), benchmarks: .previewSample)
    }
}
#endif
