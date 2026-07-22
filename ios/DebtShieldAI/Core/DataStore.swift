import Foundation
import Observation

/// Owns dataset loading and exposes an explicit state machine to the UI.
///
/// Having `loading` and `failed` as first-class states — rather than an
/// optional array that is nil for both reasons — is what lets the views show a
/// real skeleton and a real error screen instead of an empty list.
@MainActor
@Observable
final class DataStore {

    enum LoadState {
        case idle
        case loading
        case loaded(Dataset)
        case failed(DataError)
    }

    private(set) var state: LoadState = .idle

    /// Built once at load time. Folding 3,142 county and state names is cheap
    /// but not free, and it must not run on every keystroke.
    private(set) var searchIndex: CountySearchIndex?

    private let loader: CSVLoader

    init(loader: CSVLoader = CSVLoader()) {
        self.loader = loader
    }

    var dataset: Dataset? {
        if case .loaded(let dataset) = state { return dataset }
        return nil
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    /// Parsing 3,142 rows takes a few milliseconds, but it runs off the main
    /// actor so the launch frame is never blocked — and so the skeleton state
    /// is honest rather than theatrical.
    func load() async {
        if case .loading = state { return }
        state = .loading

        let loader = self.loader
        let result: Result<LoadedData, DataError> = await Task.detached(priority: .userInitiated) {
            do {
                let dataset = try loader.loadDataset()
                // Index construction joins the parse on the background task so
                // the first search is instant.
                return .success(LoadedData(
                    dataset: dataset,
                    searchIndex: CountySearchIndex(counties: dataset.counties)
                ))
            } catch let error as DataError {
                return .failure(error)
            } catch {
                return .failure(.unreadable(
                    name: "\(CSVLoader.resourceName).\(CSVLoader.resourceExtension)",
                    underlying: error.localizedDescription
                ))
            }
        }.value

        switch result {
        case .success(let loaded):
            searchIndex = loaded.searchIndex
            state = .loaded(loaded.dataset)
        case .failure(let error):
            searchIndex = nil
            state = .failed(error)
        }
    }

    func retry() async {
        state = .idle
        await load()
    }
}

/// The pair produced by a successful load, carried back across the task
/// boundary in one `Sendable` value.
private struct LoadedData: Sendable {
    let dataset: Dataset
    let searchIndex: CountySearchIndex
}
