# Agent Skills (Swift 6 + SwiftUI)

This document defines what an AI coding agent is expected to do well in this repository.

## Architecture Overview

This project uses a **layered MVVM architecture** with clear separation of concerns:

```
Models (pure data structs) — NO dependencies
    ↑
Services (networking, parsing) — references Models
    ↑
ViewModels (ObservableObject) — references Models + Services
    ↑
Views (SwiftUI) — binds to ViewModels, displays state
    ↑
Tests (XCTest / Swift Testing) — tests Models, Services, ViewModels
```

**Golden rule:** Views never call services directly. ViewModels orchestrate all data flow.

**Model type rule:** Never create model types outside `Models/`. All shared types must be defined there and referenced directly from any layer that needs them.

## Core Delivery Skills

1. Implement full vertical features across Models, Services, ViewModels, Views, and tests.
2. Work with SwiftUI declarative views without breaking navigation, state management, or layout.
3. Use Swift concurrency (`async/await`, `@MainActor`) correctly across all async boundaries.
4. Build reliable network integrations through `URLSession` service abstractions.
5. Keep architecture clean by preserving boundaries between data, logic, and UI.
6. Perform a mandatory compliance pass before completion: confirm changes align with `.github/copilot-instructions.md` and relevant `.github/skills/` guidance.

## SwiftUI View Skills

1. Use `@StateObject` to own ViewModels, `@ObservedObject` to borrow them.
2. Use `.task { }` for async work on view appearance — do not use `.onAppear` with `Task { }`.
3. Implement 3-branch rendering for all async data flows (Loading → Data → Empty).
4. Use `NavigationStack` with `NavigationLink` for drill-down navigation.
5. Keep views thin — move all logic to ViewModels or computed properties.
6. Use `guard let` and `if let` for optional handling — never force-unwrap in views.

## Data and Model Skills

1. Define all models as `struct` with `Codable` and `Identifiable` conformance.
2. Use `let` for immutable properties — `var` only when mutation is required.
3. Keep models pure — no networking, no UI imports, no side effects.
4. Use computed properties for derived values (e.g., `displayImage: URL?`).
5. Use `JSONDecoder` for JSON parsing and `XMLParser` with delegate for RSS XML.

## Networking Skills

1. Use `URLSession.shared` with `async/await` for all HTTP requests.
2. Implement proxy fallback patterns for CORS-restricted feeds.
3. Use custom `Error` enums with associated values for typed error handling.
4. Always validate HTTP status codes before parsing response data.
5. Use `guard let` to safely unwrap URLs and response types.

## Quality and Maintenance Skills

1. Build after meaningful changes (`swift build`) and resolve all compiler errors/warnings.
2. Add or update tests when behavior changes in services, models, or ViewModels.
3. Keep edits minimal, scoped, and style-consistent with surrounding code.
4. Avoid unrelated refactors while implementing requested changes.
5. Treat compiler warnings as errors — resolve all warnings before completion.
6. Use explicit types for public APIs — use type inference for local variables.
7. Prefer `async` functions over callback-based APIs.
8. Use generics and protocol constraints for reusable abstractions.
9. Keep implementations simple — avoid complex patterns when a direct approach works.
10. Use direct, descriptive, and consistent naming throughout the codebase.
11. Apply DRY — extend existing functionality before creating duplicate paths.
12. Ensure failures surface a user-safe message with a clear next step.
13. Prefer small functions, small diffs, and direct control flow.

## XcodeGen & Build Packaging Skills

1. When adding dependencies to `project.yml`, determine if the package product is a **dynamic framework** or a **static library**.
2. Add `embed: true` only to dynamic framework dependencies (e.g., SkipFuse, SkipFuseUI, SkipSQLPlus) — these must be copied into `Feeds.app/Frameworks/` for physical device deployment.
3. Never add `embed: true` to static library dependencies (e.g., MLXLLM, MLXLMCommon, MLXHuggingFace, HuggingFace, Tokenizers) — they link directly into the binary and have no `.framework` bundle to embed.
4. After changing `project.yml`, always regenerate: `xcodegen generate`.
5. If the app crashes on device launch with `dyld: Library not loaded: @rpath/<Name>.framework/<Name>`, the fix is `embed: true` on that dependency.
6. If the build fails with `lstat(.../<Name>): No such file or directory`, the fix is removing `embed: true` from that dependency (it's static, not dynamic).

## Typical Skill Applications

1. Add new RSS feed sources by extending `feeds.json` and updating the feed picker.
2. Add new view components (cards, lists, detail pages) using existing ViewModel patterns.
3. Introduce new model types and wire them through services and ViewModels.
4. Implement search/filter functionality on feed items.
5. Add cross-platform support (Android via Swift SDK cross-compilation).

## Reliability and Testability Skills

1. Follow robust coding principles: simple control flow, bounded loops, small functions, guard clauses.
2. Use context-rich errors, defensive logging, and fail-fast patterns.
3. Never use empty `catch { }` blocks — always handle or log errors.
4. Prefer composition over inheritance — use protocols for abstraction.
5. Use value types (`struct`) for data, reference types (`class`) for state managers.
6. Keep structs immutable — use new instances rather than mutation when practical.
7. Test ViewModels by injecting mock services via protocol-based dependency injection.

## Practical Development Patterns

### Model Pattern

```swift
// Models/FeedItem.swift — pure data, no dependencies
struct FeedItem: Identifiable {
    let id = UUID()                    // auto-generated unique ID
    let title: String
    let link: String
    let description: String
    let pubDate: String
    let imageURLs: [String?]

    // Computed property — derived, not stored
    var displayImage: URL? {
        imageURLs.compactMap { $0 }.compactMap { URL(string: $0) }.first
    }
}
```

### Service Pattern

```swift
// Services/FeedService.swift — async networking, returns model types
enum FeedError: Error {
    case networkError(Error)
    case parsingError
    case feedUnavailable(status: Int)
}

enum FeedService {
    static func fetchFeed(url: String) async throws -> [FeedItem] {
        guard let feedURL = URL(string: url) else {
            throw FeedError.parsingError
        }

        // Proxy fallback pattern
        let proxyURLs = [
            "https://rss-proxy-api.netlify.app/.netlify/functions/fetch-xml?url=\(feedURL.absoluteString)",
            "https://api.codetabs.com/v1/proxy/?quest=\(feedURL.absoluteString)",
        ]

        for proxyString in proxyURLs {
            if let proxyURL = URL(string: proxyString),
               let (data, response) = try? await URLSession.shared.data(from: proxyURL),
               let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                return RSSXMLParser.parse(data: data)
            }
        }

        // Direct fetch as final fallback
        let (data, response) = try await URLSession.shared.data(from: feedURL)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedError.networkError(FeedError.parsingError)
        }
        guard httpResponse.statusCode == 200 else {
            throw FeedError.feedUnavailable(status: httpResponse.statusCode)
        }
        return RSSXMLParser.parse(data: data)
    }
}
```

### ViewModel Pattern

```swift
// ViewModels/FeedViewModel.swift — @MainActor, ObservableObject
@MainActor
class FeedViewModel: ObservableObject {
    @Published var feedItems: [FeedItem] = []
    @Published var allFeeds: [RssFeedModel] = []
    @Published var selectedFeed: RssFeedModel?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // Computed — never cached
    var hasItems: Bool { !feedItems.isEmpty }

    func loadConfig() {
        guard let url = Bundle.main.url(forResource: "feeds", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            errorMessage = "Could not load feeds.json"
            return
        }
        do {
            let configs = try JSONDecoder().decode([FeedConfig].self, from: data)
            // flatten categories into allFeeds...
        } catch {
            errorMessage = "Failed to parse feeds.json: \(error.localizedDescription)"
        }
    }

    func selectFeed(_ feed: RssFeedModel) async {
        selectedFeed = feed
        isLoading = true
        errorMessage = nil

        do {
            feedItems = try await FeedService.fetchFeed(url: feed.url)
        } catch {
            errorMessage = "Failed to load feed: \(error.localizedDescription)"
            feedItems = []
        }
        isLoading = false
    }
}
```

### SwiftUI View Pattern with 3-Branch State Management

The **3-branch rendering pattern** is mandatory for all async data loading: Loading → Data → Empty.

```swift
// Views/ContentView.swift — thin declarative template
struct ContentView: View {
    @StateObject var viewModel = FeedViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    // Branch 1: Loading State
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    // Branch 2: Error State
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text(error)
                            .font(.body)
                            .multilineTextAlignment(.center)
                        Button("Try Again") {
                            Task {
                                if let feed = viewModel.selectedFeed {
                                    await viewModel.selectFeed(feed)
                                }
                            }
                        }
                    }
                    .padding()
                } else if viewModel.hasItems {
                    // Branch 3: Data State
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                            ForEach(viewModel.feedItems) { item in
                                CardView(item: item)
                            }
                        }
                        .padding()
                    }
                } else {
                    // Branch 4: Empty State
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No articles found.")
                            .font(.headline)
                        Text("Select a feed from the toolbar to get started.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Feeds")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    FeedNavBar(viewModel: viewModel)
                }
            }
        }
        .task {
            viewModel.loadConfig()
            if let first = viewModel.allFeeds.first {
                await viewModel.selectFeed(first)
            }
        }
    }
}
```

### Card View Pattern

```swift
// Views/CardView.swift — reusable subview, receives data via parameter
struct CardView: View {
    let item: FeedItem     // immutable, set at init — no @State needed

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let url = item.displayImage {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                            .frame(height: 200).clipped()
                    case .failure:
                        Image(systemName: "photo").frame(height: 200)
                    case .empty:
                        ProgressView().frame(height: 200)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            Text(item.title).font(.headline).lineLimit(2)
            Text(item.description).font(.body).lineLimit(3).foregroundColor(.secondary)
            HStack {
                if let url = URL(string: item.link) {
                    Link("View", destination: url).font(.caption)
                }
                Spacer()
                Text(Helpers.formatDate(item.pubDate)).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.windowBackgroundColor))
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}
```

## Gold Standard State Management for SwiftUI Views

**Gold Standard** state management establishes a consistent, production-grade pattern for all SwiftUI views that fetch and display data.

### State Structure (Complete Checklist)

Every ViewModel following the 3-branch pattern must include:

```swift
@MainActor
class YourViewModel: ObservableObject {
    // ============ PUBLISHED STATE ============
    @Published var items: [YourModel] = []        // raw data from service
    @Published var isLoading: Bool = false         // loading state
    @Published var errorMessage: String?           // user-safe error

    // ============ USER INPUT (for filtering) ============
    @Published var searchText: String = ""
    @Published var selectedCategory: String?

    // ============ COMPUTED PROPERTIES (derived, never cached) ============
    var filteredItems: [YourModel] {
        items
            .filter { searchText.isEmpty || $0.title.localizedCaseInsensitiveContains(searchText) }
            .filter { selectedCategory == nil || $0.category == selectedCategory }
    }
    var resultCount: Int { filteredItems.count }
    var hasItems: Bool { !items.isEmpty }
    var hasError: Bool { errorMessage != nil }

    // ============ ASYNC DATA LOADING ============
    func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }    // always runs — equivalent to C# finally

        do {
            items = try await YourService.fetch()
        } catch is URLError {
            errorMessage = "Network error. Please check your connection."
            items = []
        } catch {
            errorMessage = "Failed to load data. Please try again."
            items = []
        }
    }

    // ============ USER ACTIONS ============
    func refresh() async { await loadData() }

    func resetFilters() {
        searchText = ""
        selectedCategory = nil
        errorMessage = nil
    }

    func clearSearch() { searchText = "" }
}
```

### View Template (4-Branch Rendering)

```swift
// Always check in this exact order: Loading → Error → Data → Empty

if viewModel.isLoading {
    // BRANCH 1: LOADING STATE
    ProgressView()
} else if viewModel.hasError {
    // BRANCH 2: ERROR STATE
    VStack(spacing: 12) {
        Image(systemName: "exclamationmark.triangle")
        Text(viewModel.errorMessage ?? "Unknown error")
        Button("Try Again") { Task { await viewModel.refresh() } }
    }
} else if viewModel.hasItems {
    // BRANCH 3: DATA STATE — show content + filters
    VStack {
        TextField("Search...", text: $viewModel.searchText)
        Text("Showing \(viewModel.resultCount) results")
        ForEach(viewModel.filteredItems) { item in
            // render item
        }
    }
} else {
    // BRANCH 4: EMPTY STATE
    VStack(spacing: 12) {
        Image(systemName: "tray")
        Text("No items yet.")
        Text("Add your first item to get started.")
    }
}
```

### Gold Standard Rules Checklist

1. **Initialization**
   - Set `isLoading = true` at the start of `loadData()`
   - Set `isLoading = false` in a `defer` block — ensures it's always set
   - Initialize all collections to `[]` — never leave them uninitialized

2. **Error Handling**
   - Use typed catches: `URLError` for network, specific errors for parsing, catch-all for unexpected
   - Always set a user-safe `errorMessage` — never expose raw error descriptions
   - Provide a "Try Again" button in error state

3. **Computed Properties**
   - All filter/search results must be computed (`var filteredItems: [T] { ... }`) — never cached
   - Use `hasItems` computed property, not inline `!items.isEmpty` checks
   - Never store computed results in `@Published` properties

4. **State Branches (Exact Order)**
   1. `if isLoading` → Show `ProgressView()`
   2. `else if hasError` → Show error + retry
   3. `else if hasItems` → Show content + filters
   4. `else` → Show empty state + guidance

5. **Filtering & Search**
   - Store user input in `@Published` properties (`searchText`, `selectedCategory`)
   - Implement filter logic in computed properties using `.filter { }` chains
   - Show result count when data is displayed
   - Show contextual guidance in empty state when filters are active

6. **Threading**
   - Mark ViewModels with `@MainActor` — all `@Published` updates must be on main thread
   - Use `.task { }` in views for initial data load
   - Use `Task { }` in Button actions for user-triggered async work

### Anti-Patterns (Explicitly Forbidden)

- DO NOT: Display `items` directly — use `filteredItems` computed property
- DO NOT: Set `isLoading = false` in multiple places — use `defer`
- DO NOT: Catch errors silently — always set `errorMessage` or log
- DO NOT: Show raw error descriptions to users — translate to safe messages
- DO NOT: Render without checking `isLoading` — always use 4 branches
- DO NOT: Mix filter logic in the view body — keep it in ViewModel computed properties
- DO NOT: Force-unwrap (`!`) optionals — use `guard let`, `if let`, or `??`
- DO NOT: Use `.onAppear` with `Task { }` — use `.task { }` instead
- DO NOT: Call `objectWillChange.send()` manually — `@Published` handles it
- DO NOT: Store computed results in `@Published` fields

### Testing Pattern

```swift
// Tests/FeedViewModelTests.swift — XCTest
import XCTest
@testable import Feeds

@MainActor
final class FeedViewModelTests: XCTestCase {

    func testSelectFeed_withValidFeed_populatesItems() async {
        // Arrange
        let viewModel = FeedViewModel()
        let feed = RssFeedModel(id: "1", title: "Test", url: "https://example.com/rss")

        // Act
        await viewModel.selectFeed(feed)

        // Assert
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        // feedItems may be empty if URL is unreachable — test with mock service for determinism
    }

    func testLoadConfig_withBundledJSON_populatesAllFeeds() {
        // Arrange
        let viewModel = FeedViewModel()

        // Act
        viewModel.loadConfig()

        // Assert
        XCTAssertFalse(viewModel.allFeeds.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testFilteredItems_withSearchText_returnsOnlyMatches() {
        // Arrange
        let viewModel = FeedViewModel()
        viewModel.feedItems = [
            FeedItem(title: "Alpha", link: "", description: "", pubDate: "", imageURLs: []),
            FeedItem(title: "Beta", link: "", description: "", pubDate: "", imageURLs: []),
        ]
        // Apply search (if ViewModel has searchText filtering for feedItems)

        // Assert
        XCTAssertEqual(viewModel.feedItems.count, 2)
    }
}
```

**Testing Rules:**
- Use `@MainActor` on test classes that test ViewModels (required for `@Published` access)
- Test initial load with success and error paths
- Verify `isLoading` is `false` after completion
- Verify `errorMessage` is set on failure, `nil` on success
- For deterministic tests, inject mock services via protocols
- Test computed properties (filtered results) by setting raw data directly
- Name tests `test[Method]_[scenario]_[expectedResult]` for readability

## Reference Documentation

| Document | Purpose |
|----------|---------|
| **copilot-instructions.md** | Core engineering rules, architecture layers, feature checklist |
| **skills/SKILLS.md** (this file) | Agent capabilities, practical code patterns, testing strategies |
| **README.md** | Project overview, setup guide, Swift ↔ C# quick reference |
