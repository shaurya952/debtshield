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
            SafeLineView(store: moneyStore, dataStore: store, benchmarks: benchmarks)
                .navigationTitle("Your month")
        case .about:
            loaded(title: "About") { dataset, _ in
                AboutView(dataset: dataset) {
                    isShowingOnboarding = true
                }
            }
        }
    }

    /// Shared routing for the county-data load state, used by the About tab.
    /// The home tab does not use this.
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
                ErrorStateView(error: .noUsableRows) { await store.retry() }
                    .navigationTitle(title)
            }
        case .failed(let error):
            ErrorStateView(error: error) { await store.retry() }
                .navigationTitle(title)
        }
    }
}

/// The tab set — just two, for a focused personal tool.
///
/// - **Home** — the Safe Line: your month in plain dollars, plus comparisons
/// - **About** — how it works, privacy, and the disclaimer
enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case safeLine
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .safeLine: return "Home"
        case .about: return "About"
        }
    }

    var systemImage: String {
        switch self {
        case .safeLine: return "house.fill"
        case .about: return "info.circle"
        }
    }
}

#Preview {
    ContentView()
}
