import SwiftUI

/// The home screen — the personal heart of the app.
///
/// It answers one question in dollars — *how does this month stand?* — then lays
/// out the rest of the app as a small grid of clear tiles. The essentials fit on
/// one screen; everything deeper is one tap away. No score, no grade, no jargon,
/// no endless scroll.
///
/// It depends only on `MoneyPlanStore`, never on the county data. A person's
/// budget must never wait on — or fail with — anything else.
struct SafeLineView: View {
    let store: MoneyPlanStore
    /// For the "could you afford a move?" tile. Optional so the screen still
    /// renders (without that tile) if the county data hasn't loaded.
    var dataStore: DataStore? = nil
    var benchmarks: Benchmarks? = nil
    /// Opens the About / privacy / methodology screen (no longer a primary tab).
    var onShowAbout: () -> Void = {}

    @AppStorage("debtshield.userName") private var userName = ""
    @State private var isEditing = false
    /// Cached Monte Carlo result and sensitivity — recomputed only when the
    /// numbers change, off the main thread, so the simulation never touches a
    /// render or blocks a frame.
    @State private var outlook: MonteCarloResult?
    @State private var sensitivity: SensitivityResult?

    private var firstName: String {
        userName.split(separator: " ").first.map(String.init) ?? userName
    }

    /// The big money figure — larger than any Theme style, scales with type.
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 40

    private var plan: MoneyPlan { store.plan }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.comfortable) {
                if !firstName.isEmpty {
                    Text("Hi, \(firstName)")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.secondaryText)
                        .accessibilityAddTraits(.isHeader)
                }

                if plan.isComplete {
                    heroCard
                    situationLink
                    whatChangedCard
                    featureGrid
                    editButton
                } else {
                    emptyState
                }
            }
            .padding(Theme.Spacing.comfortable)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.screenBackground)
        .navigationTitle("Your month")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onShowAbout) {
                    BrandMark(size: 28)
                }
                .accessibilityLabel("About Headroom, privacy and methodology")
            }
            if plan.isComplete {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditing = true
                    } label: {
                        Label("Edit your numbers", systemImage: "square.and.pencil")
                    }
                    .fontWeight(.semibold)
                    .accessibilityLabel("Edit your numbers")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            MyNumbersView(store: store)
        }
        .task(id: store.plan) {
            let plan = store.plan
            let history = store.history
            let computed = await Task.detached(priority: .userInitiated) {
                (MonteCarloEngine.simulate(plan: plan, history: history, seed: 42),
                 MonteCarloEngine.sensitivity(plan: plan, history: history, seed: 42))
            }.value
            outlook = computed.0
            sensitivity = computed.1
        }
    }

    // MARK: - Hero (the money answer)

    private var heroCard: some View {
        let status = plan.status ?? .okay
        return VStack(alignment: .leading, spacing: Theme.Spacing.regular) {
            StatusChip(status: status)

            if let left = plan.moneyLeft {
                VStack(alignment: .leading, spacing: 2) {
                    Text(headlineAmount(left))
                        .font(.system(size: heroSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text(left >= 0 ? "left this month" : "short this month")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spokenMoneyLeft(left))
            }

            SafeLineBar(plan: plan, barHeight: 50, showsCaption: false)
                .padding(.top, 2)

            Text(insight)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.comfortable)
        .background {
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Theme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                        .fill(Theme.statusWash(status))
                }
                .shadow(color: Theme.heroShadow, radius: 14, x: 0, y: 8)
        }
    }

    /// One plain, kind line about the month — concrete, short, no jargon.
    private var insight: String {
        guard let share = plan.essentialsShare, let status = plan.status else { return "" }
        let pct = Int((share * 100).rounded())
        switch status {
        case .okay:
            if share > MoneyPlan.safeLineShare, let left = plan.moneyLeft {
                return "Basics take \(pct)% of income — a bit over the line, but \(money(left)) left over is a comfy cushion."
            }
            return "Basics take \(pct)% of income — under the safe line. You've got room."
        case .tight:
            let over = (plan.safeLineAmount.map { plan.essentialsTotal - $0 }) ?? 0
            return "Basics take \(pct)% of income. About \(money(max(0, over))) less would put you back under the line."
        case .over:
            let short = plan.moneyLeft.map { -$0 } ?? 0
            return "Basics cost about \(money(short)) more than you earn. The tiles below show where to start."
        }
    }

    // MARK: - Situation link (the hero already states the status; this is just the
    // quiet way into the full read, instead of a second card repeating "on track")

    @ViewBuilder
    private var situationLink: some View {
        if situationRead != nil {
            NavigationLink {
                SituationDetailView(store: store)
            } label: {
                HStack(spacing: Theme.Spacing.tight) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.footnote.weight(.semibold))
                    Text("What this means for the months ahead")
                        .font(Theme.Typography.subheadline.weight(.semibold))
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                }
                .foregroundStyle(Theme.brand)
                .padding(.horizontal, Theme.Spacing.comfortable)
                .frame(minHeight: Theme.minimumTapTarget)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the full read of where you stand")
        }
    }

    // MARK: - What changed since last month (actual history, not a projection)

    @ViewBuilder
    private var whatChangedCard: some View {
        if let last = store.lastMonth,
           let change = MonthChangeEngine.compare(current: plan, last: last) {
            let tint = change.isFlat ? Theme.brand
                : (change.isImprovement ? Theme.statusColor(.okay) : Theme.statusColor(.tight))
            let symbol = change.isFlat ? "equal.circle.fill"
                : (change.isImprovement ? "arrow.up.forward" : "arrow.down.forward")
            Card {
                HStack(spacing: Theme.Spacing.regular) {
                    AppIconBadge(systemImage: symbol, tint: tint, size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Since last month")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.secondaryText)
                        Text(change.headline)
                            .font(Theme.Typography.body.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                if let driver = change.driver {
                    Text(driver)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if retention.monthsTracked >= 2 {
                    Text("You've tracked \(retention.monthsTracked) months.")
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var retention: RetentionState {
        let d = UserDefaults.standard
        return RetentionState.from(
            historyKeys: store.history.map(\.monthKey),
            currentMonthKey: store.month,
            currentComplete: plan.isComplete,
            openedYearAhead: d.bool(forKey: "debtshield.opened.yearAhead"),
            openedComparison: d.bool(forKey: "debtshield.opened.comparison"),
            savedAnAction: d.bool(forKey: "debtshield.opened.saveEarn")
        )
    }

    // MARK: - Feature grid (everything, one tap deep)

    private var featureGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: Theme.Spacing.regular),
                      GridItem(.flexible(), spacing: Theme.Spacing.regular)],
            spacing: Theme.Spacing.regular
        ) {
            yearAheadTile
            breakdownTile
            buildRoomTile
        }
    }

    private var yearAheadTile: some View {
        NavigationLink {
            OutlookDetailView(
                result: outlook,
                topLever: sensitivity?.topActionableLever,
                tightThisMonth: plan.status == .tight,
                months: recentMonths
            )
        } label: {
            FeatureTile(
                systemImage: "chart.line.uptrend.xyaxis",
                title: "The year ahead",
                subtitle: riskSubtitle,
                tint: riskTint
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    private var breakdownTile: some View {
        NavigationLink {
            BreakdownDetailView(store: store)
        } label: {
            FeatureTile(
                systemImage: "chart.pie.fill",
                title: "Your spending",
                subtitle: "See what takes the most",
                tint: Theme.essentialColor(.food)
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    private var buildRoomTile: some View {
        NavigationLink {
            BuildRoomView(store: store)
        } label: {
            FeatureTile(
                systemImage: "scissors",
                title: "Free up more room",
                subtitle: "Trim costs, keep more each month",
                tint: Theme.brand
            )
        }
        .buttonStyle(PressableCardStyle())
    }

    private var riskSubtitle: String {
        guard let prob = outlook?.probNegativeWithin6mo else { return "Working it out…" }
        switch prob {
        case ..<0.05: return "On steady ground"
        case ..<0.25: return "Mostly steady"
        case ..<0.60: return "Worth watching"
        default: return "Needs attention"
        }
    }

    private var riskTint: Color {
        guard let prob = outlook?.probNegativeWithin6mo else { return Theme.brand }
        switch prob {
        case ..<0.05: return Theme.statusColor(.okay)
        case ..<0.25: return Theme.brand
        case ..<0.60: return Theme.statusColor(.tight)
        default: return Theme.statusColor(.over)
        }
    }

    // MARK: - Shared reads

    private var allMonths: [MonthRecord] {
        var months = store.history.reversed().map { $0 }
        if plan.isComplete, !store.month.isEmpty {
            months.append(MonthRecord(monthKey: store.month, plan: plan))
        }
        return months
    }

    private var recentMonths: [MonthRecord] { Array(allMonths.suffix(6)) }

    private var situationRead: SituationRead? {
        SituationEngine.assess(plan: plan, months: allMonths)
    }

    // MARK: - Formatting

    private func headlineAmount(_ left: Double) -> String {
        let magnitude = left.magnitude.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return left >= 0 ? magnitude : "−\(magnitude)"
    }

    /// A spoken version of the headline, so VoiceOver says "250 dollars short
    /// this month" rather than reading a minus glyph.
    private func spokenMoneyLeft(_ left: Double) -> String {
        let amount = left.magnitude.formatted(.currency(code: "USD").precision(.fractionLength(0)))
        return left >= 0 ? "\(amount) left this month" : "\(amount) short this month"
    }

    private func money(_ value: Double) -> String {
        value.formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }

    // MARK: - Edit

    private var editButton: some View {
        Button {
            isEditing = true
        } label: {
            Label("Edit your numbers", systemImage: "slider.horizontal.3")
                .font(Theme.Typography.body.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
        }
        .buttonStyle(.bordered)
        .padding(.top, Theme.Spacing.tight)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.comfortable) {
            AppIconBadge(systemImage: "chart.bar.doc.horizontal", size: 84)

            Text("See where your money stands")
                .font(Theme.Typography.title)
                .multilineTextAlignment(.center)

            Text("Add a few numbers and we'll show you, in plain dollars, how much room you have this month. Everything stays on your phone.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                isEditing = true
            } label: {
                Text("Add your numbers")
                    .font(Theme.Typography.body.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: Theme.minimumTapTarget)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, Theme.Spacing.tight)
        }
        .padding(Theme.Spacing.section)
        .frame(maxWidth: .infinity)
        .padding(.top, Theme.Spacing.section)
    }
}

#if DEBUG
#Preview("Filled — tight") {
    NavigationStack { SafeLineView(store: .preview(.sampleTight)) }
}

#Preview("Filled — over") {
    NavigationStack { SafeLineView(store: .preview(.sampleOver)) }
}

#Preview("With history") {
    NavigationStack { SafeLineView(store: .previewWithHistory()) }
}

#Preview("Empty") {
    NavigationStack { SafeLineView(store: .preview(.empty)) }
}
#endif
