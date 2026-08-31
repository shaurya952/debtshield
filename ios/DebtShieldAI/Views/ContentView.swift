import SwiftUI

/// Root shell.
///
/// v2 is a personal tool: the home screen is the Safe Line, and the county data
/// survives only as a comparison layer behind it. The tab set is deliberately
/// small — Home and About — so the app reads as one focused thing rather than a
/// dashboard.
struct ContentView: View {
    @State private var store = DataStore()
    @State private var moneyStore = MoneyPlanStore()
    @State private var benchmarks = BenchmarksLoader.load()
    @State private var wages = OccupationWagesLoader.load()
    @State private var saved = SavedPlacesStore()
    @State private var selectedTab: AppTab = .safeLine
    /// Land returning users on Places — the differentiator — rather than the monthly
    /// budget. A brand-new user (no income yet) still starts on Home so they enter
    /// their numbers first, which is what unlocks everything else.
    @State private var didPickInitialTab = false

    /// Set once the introduction has been read. Persisted so it appears on
    /// first launch only.
    @AppStorage("debtshield.hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var isShowingOnboarding = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    content(for: tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        .tint(Theme.brand)
        .task {
            // Loads the county data used by the comparison layer. The home
            // screen never waits on this — it renders and works regardless.
            await store.load()
        }
        .onAppear {
            #if DEBUG
            // UI-test seed: with the `uitest-seed` launch argument, start from a
            // populated plan so accessibility audits cover the rich screens.
            // DEBUG-only and never triggered in normal use.
            if ProcessInfo.processInfo.arguments.contains("uitest-seed"), moneyStore.plan == .empty {
                moneyStore.save(MoneyPlan(monthlyIncome: 5000, housing: 1400,
                                          food: 600, energy: 250, debtPayments: 300))
            }
            #endif
            // Archive the finished month if the calendar has turned over.
            moneyStore.rollOverIfNeeded()
            // First appearance: open on Places when there are already numbers to
            // rank, so the hero feature is the front door. Only runs once, so it
            // never fights the person's own tab taps.
            if !didPickInitialTab {
                didPickInitialTab = true
                if (moneyStore.plan.monthlyIncome ?? 0) > 0 { selectedTab = .places }
            }
        }
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                isShowingOnboarding = false
            }
            .interactiveDismissDisabled()
        }
        .onAppear {
            if !hasSeenOnboarding { isShowingOnboarding = true }
        }
    }

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .safeLine:
            // The person's own numbers — never waits on the county data. The
            // county data + benchmarks power the "afford a move?" feature and
            // are optional-by-nature.
            SafeLineView(store: moneyStore, dataStore: store, benchmarks: benchmarks)
        case .places:
            // The relocation hero — ranks where the person's numbers would leave
            // the most breathing room, across every county in the bundled data.
            PlacesView(store: moneyStore, dataStore: store, benchmarks: benchmarks,
                       wages: wages, saved: saved) {
                selectedTab = .safeLine
            }
        case .ask:
            // The AI, in its own section — with the comparison data wired in so
            // it can answer "how does my rent compare".
            PersonalChatView(store: moneyStore, dataStore: store, benchmarks: benchmarks)
        case .about:
            // About is static — it doesn't depend on the county data.
            AboutView(store: moneyStore) {
                isShowingOnboarding = true
            }
        }
    }
}

/// The tab set — a focused personal tool.
///
/// - **Home** — the Safe Line: your month in plain dollars
/// - **Places** — where your money would stretch furthest, across the U.S.
/// - **Ask** — the AI, in plain language, about your own numbers
/// - **About** — how it works, privacy, and the disclaimer
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case safeLine
    case places
    case ask
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .safeLine: return "Home"
        case .places: return "Places"
        case .ask: return "Ask"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .safeLine: return "house.fill"
        case .places: return "map.fill"
        case .ask: return "bubble.left.and.text.bubble.right.fill"
        case .about: return "info.circle"
        }
    }
}

#Preview {
    ContentView()
}
