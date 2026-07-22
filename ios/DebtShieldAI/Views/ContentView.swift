import SwiftUI

/// Root shell.
///
/// Phases 2–9 add a tab by adding a case to `AppTab` and one branch to
/// `content(for:)` — the navigation shape never has to be rewritten.
struct ContentView: View {
    @State private var store = DataStore()
    @State private var moneyStore = MoneyPlanStore()
    @State private var selection = SelectionStore()
    @State private var favorites = FavoritesManager()
    @State private var comparison = ComparisonStore()
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
            await store.load()
        }
        // Covers the screen so the disclaimer is read before anything else.
        // Not dismissible by swipe — the reader has to acknowledge it.
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
            // Deliberately NOT routed through `loaded(...)`: the person's own
            // numbers must never wait on, or fail with, the county dataset.
            SafeLineView(store: moneyStore, dataStore: store)
                .navigationTitle("Your month")
        case .dashboard:
            loaded(title: "Dashboard") { dataset, _ in
                DashboardView(dataset: dataset) { county in
                    // Tapping a county in a dashboard list opens its profile,
                    // so the top-10 lists are a way in rather than a dead end.
                    selection.select(county)
                    selectedTab = .profile
                }
            }
        case .profile:
            loaded(title: "County Profile") { dataset, searchIndex in
                CountyProfileView(
                    dataset: dataset,
                    searchIndex: searchIndex,
                    selection: selection,
                    favorites: favorites
                )
            }
        case .compare:
            loaded(title: "Compare") { dataset, searchIndex in
                CompareCountiesView(
                    dataset: dataset,
                    searchIndex: searchIndex,
                    comparison: comparison,
                    favorites: favorites
                )
            }
        case .insights:
            loaded(title: "Insights") { dataset, searchIndex in
                InsightsView(
                    dataset: dataset,
                    searchIndex: searchIndex,
                    selection: selection
                ) { county in
                    // Same behaviour as the dashboard lists: picking a county
                    // anywhere in the app opens it on the County tab.
                    selection.select(county)
                    selectedTab = .profile
                }
            }
        case .about:
            loaded(title: "About") { dataset, _ in
                AboutView(dataset: dataset) {
                    isShowingOnboarding = true
                }
            }
        }
    }

    /// Shared routing for the load state machine, so every tab gets the same
    /// skeleton and the same friendly error screen for free.
    @ViewBuilder
    private func loaded<Content: View>(
        title: String,
        @ViewBuilder content: (Dataset, CountySearchIndex) -> Content
    ) -> some View {
        switch store.state {
        case .idle, .loading:
            DashboardSkeleton()
                .background(Theme.screenBackground)
                .navigationTitle(title)
        case .loaded(let dataset):
            if let searchIndex = store.searchIndex {
                content(dataset, searchIndex)
            } else {
                // Unreachable in practice: the index is built alongside the
                // dataset. Handled rather than force-unwrapped.
                ErrorStateView(error: .noUsableRows) { await store.retry() }
                    .navigationTitle(title)
            }
        case .failed(let error):
            ErrorStateView(error: error) { await store.retry() }
                .navigationTitle(title)
        }
    }
}

/// The tab set.
///
/// Capped at five for the life of the app. iOS collapses any tab beyond the
/// fifth into a system "More" list, which hides features behind an unlabelled
/// row and reads as an unfinished app in review.
///
/// The shape everything else slots into:
///
/// - **Dashboard** — national picture
/// - **County** — the selected county, and the hub for everything about it:
///   Risk Drivers, Recommendations, and Scenario Simulator are pushed from here
/// - **Compare** — several counties side by side
/// - **Insights** — national-level screens: Risk Map and Model Performance,
///   with Ask DebtShield joining in Phase 8
/// - **About** — methodology, glossary, disclaimer, and privacy
///
/// This is the complete set. Anything added later must be pushed from one of
/// these five, never appended as a sixth tab.
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    // Home is the new heart of the app. The four county tabs that follow are
    // being retired into a comparison layer in a later step; while both sets
    // coexist iOS will collapse the overflow into a "More" list, which is
    // expected and temporary.
    case safeLine
    case dashboard
    case profile
    case compare
    case insights
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .safeLine: return "Home"
        case .dashboard: return "Dashboard"
        case .profile: return "County"
        case .compare: return "Compare"
        case .insights: return "Insights"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .safeLine: return "house.fill"
        case .dashboard: return "square.grid.2x2"
        case .profile: return "person.text.rectangle"
        case .compare: return "chart.bar.xaxis"
        case .insights: return "chart.dots.scatter"
        case .about: return "info.circle"
        }
    }
}

#Preview {
    ContentView()
}
