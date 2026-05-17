# Engineering Rules (Swift 6 + SwiftUI)

These rules are mandatory for all feature work, bug fixes, and refactors in this repository.

## 1) Platform Identity

1. Stack is Swift 6 + SwiftUI + Swift Package Manager.
2. Targets macOS 14+ and iOS 17+; Android via Swift SDK cross-compilation.
3. UI framework is SwiftUI with declarative views and MVVM architecture.
4. Architecture is layered: Models, Services, ViewModels, Views, and Utils.
5. Navigation uses `NavigationStack` with programmatic and link-based routing.

## 2) Non-Negotiable Architecture Rules

1. Models must remain pure data types (`struct`) with no UI or networking dependencies.
2. Services handle all I/O (networking, file loading) and must not reference SwiftUI.
3. Views compose ViewModel behavior but must not contain business logic or networking calls.
4. Do not bypass the ViewModel by calling services directly from Views.
5. Register shared dependencies through `@StateObject` (owner) and `@ObservedObject` / `@EnvironmentObject` (consumer).
6. **Never create duplicate model types across layers.** All shared types (models, DTOs, value objects) must be defined in `Models/` and referenced directly. Do not create local copies in Views or ViewModels.

## 3) Dependency & State Management Rules

1. Use `@StateObject` for ViewModel ownership (created once, survives re-renders).
2. Use `@ObservedObject` when receiving an existing ViewModel from a parent.
3. Use `@EnvironmentObject` for app-wide shared state (e.g., user session, theme).
4. Use `@State` for view-local UI state only (toggles, text fields, selections).
5. Use `@Binding` to pass mutable state down to child views.
6. Do not use singletons or global mutable state — prefer `ObservableObject` injection.

## 4) SwiftUI View & Routing Rules

1. Keep views as thin declarative templates — move logic to ViewModels or computed properties.
2. Use `NavigationStack` (not deprecated `NavigationView`) for navigation hierarchies.
3. Use `.task { }` for async work on view appearance — not `.onAppear` with `Task { }`.
4. Use `guard let` / `if let` for optional unwrapping — never force-unwrap (`!`) in production code.
5. **Manage async view state with explicit Loading/Data/Empty flows** — when views fetch data on initialization (via `.task {}`), maintain an `isLoading` flag in the ViewModel set to `false` only after data is fetched or an error occurs. Render three distinct states: (1) `ProgressView()` while loading, (2) populated content when data is non-empty, (3) empty-state message with contextual guidance when data is empty.

## 5) Networking & Data Rules

1. All network access must go through service abstractions (e.g., `FeedService`), never from Views.
2. Use `URLSession.shared` for HTTP requests — do not create new `URLSession` instances per request.
3. Use `async throws` functions for network calls — propagate errors to the ViewModel for user-safe handling.
4. Keep error translation centralized in service types using custom `Error` enums with associated values.
5. Avoid scattering endpoint URLs; keep proxy URLs and base URLs as constants in the service layer.

## 6) Security Rules

1. Never hardcode secrets, API keys, or credentials in source code.
2. Use App Transport Security exceptions only when required — prefer HTTPS.
3. Never log sensitive user data or authentication tokens.
4. Validate all external input (URL strings, JSON payloads) before use.
5. Use `URL(string:)` (returns optional) instead of force-constructing URLs.

## 7) UI and Design Rules

1. Use SwiftUI's native theming — respect system light/dark mode automatically.
2. Use semantic colors (`.primary`, `.secondary`, `.accentColor`) over hardcoded color literals.
3. Use system SF Symbols (`Image(systemName:)`) for icons — they adapt to Dynamic Type.
4. Use `.font(.headline)`, `.font(.body)`, etc. — never hardcode font sizes.
5. Maintain responsive layout using `LazyVGrid` with `adaptive(minimum:)` columns.
6. Use `AsyncImage` for remote images with `.placeholder` and `.failure` states.
7. Keep views composable — extract reusable subviews as separate `struct` types.
8. **Separate view and logic** — keep complex logic in the ViewModel (`ObservableObject`), views should only read `@Published` properties and call ViewModel methods.

## 8) Performance Rules

1. Use `LazyVGrid` / `LazyVStack` for large scrollable lists — avoid rendering all items upfront.
2. Use `AsyncImage` for image loading — it handles caching and cancellation automatically.
3. Avoid expensive computed properties in the view `body` — precompute in the ViewModel.
4. Do not call `objectWillChange.send()` manually — `@Published` handles this automatically.
5. Use `Identifiable` conformance and stable `id` values for efficient SwiftUI diffing.

## 9) Testing and Validation Rules

1. Build the project after code changes: `swift build`.
2. Resolve all compiler errors and warnings introduced by the change.
3. Add or update XCTest/Swift Testing tests for behavior changes in services, models, and ViewModels.
4. Test ViewModels independently by injecting mock services via protocols.
5. Test pure model logic (computed properties, guard clauses) with simple unit tests.

## 10) Logging and Observability Rules

1. Use `print()` or `os.Logger` for meaningful operational events during development.
2. Avoid noisy or duplicate log statements that reduce signal.
3. Never log passwords, tokens, or raw personal information.
4. Always provide users with a descriptive, actionable failure reason when an operation fails.
5. User-facing error messages must be clear and safe — explain what failed and the next step, without exposing internals.

## 11) Change Management Rules

1. Prefer minimal, scoped changes over broad rewrites.
2. Do not refactor unrelated areas while implementing targeted fixes.
3. Keep naming, formatting, and coding style aligned with surrounding code.
4. Use explicit types for function signatures and public APIs — use type inference for local variables where the type is obvious.
5. Prefer Swift-native and SwiftUI-native implementations — avoid UIKit or AppKit unless there is no SwiftUI alternative.
6. No nested syntax: prefer flat, readable structures with `guard` clauses and early returns instead of deeply nested conditionals.
7. AI agent compliance check is mandatory: before finalizing changes, verify the implementation aligns with `.github/copilot-instructions.md` and relevant `.github/skills/` guidance.
8. Prefer `async` functions over callback-based APIs. Use `async throws` for fallible async work.
9. Use generics and protocol constraints for reusable, type-safe abstractions — avoid duplicated type-specific implementations.
10. Keep code simple and straightforward. Avoid complex or clever patterns when a clear, direct implementation can meet the requirement.
11. If code cannot be understood quickly without comments, simplify it first — comments are for context, not to compensate for avoidable complexity.
12. Use direct, descriptive, and consistent naming for types, functions, properties, and files.
13. Apply DRY by reusing existing related functionality where possible — extend or refactor existing components before creating parallel implementations.
14. Prefer low-boilerplate implementations: small functions, small diffs, and direct control flow.
15. **If hardcoded mock/placeholder data is found in views, treat it as temporary scaffolding and replace it before completion** — use parameterized bindings, service calls, or empty-state defaults. If backend wiring is pending, use clearly marked `// TODO:` stubs that return empty arrays.
16. **Avoid unnecessary `if` statements** — prefer ternary expressions, `guard`, `if let`, nil-coalescing (`??`), and early returns over redundant conditional blocks.
17. **Code is liability, not an asset.** Every line added must justify its existence. Prefer deleting code over adding it, and always pursue the smallest diff that solves the problem. If a feature can be achieved by removing or simplifying existing code instead of writing new code, do that.

## 12) Architecture Layers & Responsibilities

```
Views (SwiftUI)  ──binds──►  ViewModels (@Published)  ──calls──►  Services (async)  ──uses──►  Models (struct)
```

| Layer | Responsibility | Key Files |
|-------|---|---|
| **Models** | Pure data types (`struct`), `Codable` conformance, `Identifiable`. **Zero framework dependencies.** | `Models/RssFeedModel.swift`, `Models/FeedItem.swift` |
| **Services** | Network requests (`URLSession`), XML parsing (`XMLParser`), JSON decoding. Pure I/O layer. | `Services/FeedService.swift`, `Services/RSSXMLParser.swift` |
| **ViewModels** | `ObservableObject` with `@Published` state. Orchestrates services, manages loading/error state. **Marked `@MainActor`.** | `ViewModels/FeedViewModel.swift` |
| **Views** | Declarative SwiftUI templates. Reads ViewModel state. No business logic. | `Views/ContentView.swift`, `Views/CardView.swift`, `Views/FeedNavBar.swift` |
| **Utils** | Pure helper functions (date formatting, string manipulation). No dependencies. | `Utils/Helpers.swift` |
| **Resources** | Static config files bundled with the app. | `Resources/feeds.json` |

## 13) Adding a New Feature (Checklist)

1. **Models** — Create `struct` in `Models/` with `Codable` / `Identifiable` conformance
2. **Services** — Add async service function in `Services/` using `URLSession` or `XMLParser`
3. **ViewModel** — Add `@Published` properties and async methods to the ViewModel
4. **Views** — Create SwiftUI views that read ViewModel state with 3-branch rendering
5. **Tests** — Add XCTest cases for model logic, service parsing, and ViewModel state transitions
6. **Package.swift** — Add any new dependencies or resource bundles if needed

## 14) Robust Coding Principles (Adapted for Swift)

1. **Simple Control Flow**: Avoid complex recursion. Use iteration for predictable stack depth.
2. **Fixed Loops**: All loops must have a deterministic upper bound. Avoid unbounded loops.
3. **Small Functions**: No function should exceed 60 lines. If it's longer, extract sub-functions.
4. **Guard Clauses**: Use `guard let` / `guard` at the top of functions. Validate inputs early.
5. **Data Hiding**: Use `private` and `private(set)` to limit scope. Expose only what's needed.
6. **Check Return Values**: Never ignore a `Task` or return value. Always `await` async calls or explicitly assign `_ =` for intentional fire-and-forget.
7. **No Force Unwrapping**: Never use `!` on optionals in production code. Use `guard let`, `if let`, or `??` instead.
8. **Compile-Time Safety**: Treat all compiler warnings as errors. Enable strict concurrency checking.
9. **Value Types First**: Prefer `struct` over `class` unless reference semantics are required.
10. **Sendable Compliance**: In Swift 6, ensure types shared across concurrency boundaries conform to `Sendable`.

## 15) Production Stability Rules

1. **Context-Rich Errors**: Never throw a generic `Error`. Use custom `enum` types with associated values describing the failure context.
   - *Bad:* `throw NSError(domain: "", code: 0)`
   - *Good:* `throw FeedError.feedUnavailable(status: statusCode)`
2. **Fail Fast**: Use `guard` at function entry to validate preconditions. Exit early on invalid state.
3. **No Empty Catch Blocks**: Never use `catch { }` without handling the error. At minimum, log why it's safe to ignore.
4. **Timeouts on Network Calls**: Set `timeoutIntervalForRequest` on `URLRequest` — never let a request hang indefinitely.
5. **Pure Logic Separation**: Keep business logic in pure functions (input in, output out) separate from I/O. Pure functions are trivial to unit test.
6. **Avoid Global Mutable State**: Do not use global `var` or static mutable properties. Use `@StateObject` / `@EnvironmentObject` for shared state.
7. **Structured Concurrency**: Use `async/await` and `TaskGroup` — avoid raw `DispatchQueue` unless required for interop.

## 16) Struct vs Class Rules

1. **Prefer Structs for Data**: Use `struct` for models, DTOs, and value objects. This ensures value semantics and thread safety.
2. **Use Classes for State Managers**: Use `class` for `ObservableObject` ViewModels and services that manage mutable state or I/O.
3. **Immutable by Default**: Use `let` for properties. Use `var` only when mutation is required.
4. **Equatable for Testing**: Conform models to `Equatable` for simple test assertions.

## 17) Gold Standard State Management for SwiftUI Views

**Mandatory pattern** for all views that fetch and display data.

### State Structure (Required Elements)

Every async data-loading view must use a ViewModel with:

1. **Published Properties** (state)
   - `@Published var items: [YourModel] = []` — raw data
   - `@Published var isLoading: Bool = false`
   - `@Published var errorMessage: String?`

2. **Computed Properties** (derived, never cached)
   - `var filteredItems: [YourModel] { items.filter { ... } }`
   - `var hasItems: Bool { !items.isEmpty }`

3. **Async Methods** (data loading)
   - `func loadData() async` — wrapped in do/catch, sets `isLoading` before and after

4. **Error Handling** (three levels)
   - **Network errors** (URLError): "Network error. Please check your connection."
   - **Parsing errors**: "Unable to read feed data."
   - **Unexpected errors** (catch-all): "Something went wrong. Please try again."

### 3-Branch Rendering Pattern (Exact Order)

```swift
if viewModel.isLoading {
    ProgressView()
} else if let error = viewModel.errorMessage {
    // Error state with retry button
    Text(error)
    Button("Try Again") { Task { await viewModel.loadData() } }
} else if viewModel.hasItems {
    // Data state — show content
    ForEach(viewModel.filteredItems) { item in ... }
} else {
    // Empty state — show guidance
    Text("No items found.")
}
```

### Non-Negotiable Rules

1. **Always use do/catch** — set `isLoading = false` in a `defer` block or after catch
2. **Never display raw data** — always use filtered/computed properties
3. **Always provide user-safe error messages** — never expose raw error descriptions
4. **Always initialize collections to `[]`** — never leave them as implicitly unwrapped
5. **Use `@MainActor`** on ViewModels to ensure UI updates happen on the main thread
6. **Use `.task { }` for initial data load** — not `.onAppear` with manual `Task { }`
