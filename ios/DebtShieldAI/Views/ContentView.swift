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
    @State private var selectedTab: AppTab = .safeLine

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
            // Archive the finished month if the calendar has turned over.
            moneyStore.rollOverIfNeeded()
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
            // The person's own numbers — never waits on the county data.
            SafeLineView(store: moneyStore) {
                selectedTab = .compare
            }
        case .compare:
            // The comparison layer. Uses the county data when it's loaded, and
            // still shows national + food + debt while it isn't.
            CompareView(store: moneyStore, dataStore: store, benchmarks: benchmarks) {
                selectedTab = .safeLine
            }
        case .about:
            // About is static — it doesn't depend on the county data.
            AboutView {
                isShowingOnboarding = true
            }
        }
    }
}

/// The tab set — a focused personal tool.
///
/// - **Home** — the Safe Line: your month in plain dollars
/// - **Compare** — your spending vs. your area and the U.S.
/// - **About** — how it works, privacy, and the disclaimer
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case safeLine
    case compare
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .safeLine: return "Home"
        case .compare: return "Compare"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .safeLine: return "house.fill"
        case .compare: return "chart.bar.xaxis"
        case .about: return "info.circle"
        }
    }
}

#Preview {
    ContentView()
}
