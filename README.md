# Feeds Reader in Swift for Android & iOS - VS Code + Emulators

**1. Project Overview**

- **Purpose**: RSS feed reader that fetches/parses XML feeds, displays articles as image cards in a grid, supports categorized feed navigation
- **Platforms**: iOS 17+ / macOS 14+ (native) and Android (via [Skip](https://skip.dev/) Fuse mode — shared Swift codebase, SwiftUI → Compose bridge)
- **Core features**: SQLite-backed feed subscriptions → XML fetch (with proxy fallback) → parse → card grid UI → sidebar with grouped feed navigation → SQLCipher-encrypted bookmark persistence → on-device AI article summaries (Apple Silicon) → dynamic feed management (add/delete/configure without rebuilds)
- **Cross-platform imports**: On Android/Linux, networking types require `import FoundationNetworking` and XML parsing requires `import FoundationXML` (conditionally imported via `#if canImport(...)`).  
- **Key models**: `RssFeedModel(id, title, url, suppressHeroImage)`, `FeedRecord` (SQLite row), `FeedItem` with title/link/description/pubDate/imageURLs, `SavedArticle` for bookmarks

**2. Prerequisites & Tooling Setup**

**macOS Environment**

- Install **Xcode** (iOS simulator): `xcode-select --install`, then full Xcode from App Store
- Install **Android Studio** (Android emulator): download from developer.android.com, install SDK + emulator images
- Install **VS Code** extensions:
  - `Swift` (Swift Language Support by Swift Server Work Group)
  - `LLDB DAP` (debugging - required by the Swift extension)
  - `Android iOS Emulator` (launch emulators from VS Code command palette)

**Swift Toolchain (Open-Source)**

- Cross-compilation requires the **open-source toolchain**, not the one bundled with Xcode
- Install [swiftly](https://www.swift.org/swiftly/documentation/swiftly/getting-started) (recommended toolchain manager):
  ```bash
  swiftly install latest
  swiftly use latest
  swift --version   # confirm e.g. Swift 6.3.2
  ```

**Android & Swift SDK Setup**

**Step 1: Install the Android SDK**

- **With Android Studio** (recommended): Android Studio installs the SDK, NDK, platform-tools, and emulator automatically
- **Without Android Studio** (manual):
  - Download zips from the [Android SDK command-line tools page](https://developer.android.com/studio#command-line-tools-only):
    - **Command Line Tools**: `commandlinetools-mac-xxxx_latest.zip`
    - **SDK Platform-Tools**: `platform-tools-latest-darwin.zip` (contains `adb`)
  - The SDK tools **will not run** unless nested inside a folder named `latest`
  - **macOS**:
    - Create `/Library/Android/sdk`
    - Extract platform-tools into the root → `/Library/Android/sdk/platform-tools/adb`
    - Create `/Library/Android/sdk/cmdline-tools/latest/` → extract command line tools into it → `.../cmdline-tools/latest/bin/sdkmanager`
  - **Windows**:
    - Create `C:\Program Files (x86)\Android\android-sdk`
    - Extract platform-tools into the root → `...\android-sdk\platform-tools\adb.exe`
    - Create `...\android-sdk\cmdline-tools\latest\` → extract command line tools into it → `...\cmdline-tools\latest\bin\sdkmanager.bat`

**Step 2: Install the Android NDK**

- Required: NDK LTS version **27d or later**
- **With Android Studio**: SDK Manager → SDK Tools → NDK (Side by side)
- **Manual**: download `android-ndk-r27d-darwin.dmg` from the [NDK Downloads page](https://developer.android.com/ndk/downloads/#lts-downloads), then:
  1. Mount the `.dmg` (double-click or `hdiutil attach android-ndk-r27d-darwin.dmg`)
  2. The volume contains `AndroidNDK13750724.app` and `source.properties`
  3. Copy the NDK app contents into the SDK:
     ```bash
     mkdir -p "$ANDROID_HOME/ndk"
     cp -r "/Volumes/Android NDK r27d/AndroidNDK13750724.app/Contents/NDK" "$ANDROID_HOME/ndk/27.2.12479018"
     ```
  4. Eject the volume: `hdiutil detach "/Volumes/Android NDK r27d"`

**Step 3: Set Environment Variables**

- Open `~/.zshrc` (`nano ~/.zshrc`) or any text editor and add:
  ```bash
  # Java Home (Microsoft OpenJDK)
  export JAVA_HOME=/Library/Java/JavaVirtualMachines/microsoft-21.jdk/Contents/Home

  # Android Home
  export ANDROID_HOME=/Library/Android/sdk

  # Android NDK Home
  export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/27.2.12479018

  # Update Path
  export PATH=$PATH:$JAVA_HOME/bin
  export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
  export PATH=$PATH:$ANDROID_HOME/platform-tools
  export PATH=$PATH:$ANDROID_HOME/emulator
  ```
- Save (`Ctrl+O`, `Enter`) and exit (`Ctrl+X`) if using nano, or `Ctrl+S` in other editors
- Apply changes: `source ~/.zshrc`

**Step 4: Install the Swift SDK for Android**

- Install the SDK bundle:
  ```bash
  swift sdk install https://download.swift.org/swift-6.3.2-release/android-sdk/swift-6.3.2-RELEASE/swift-6.3.2-RELEASE_android.artifactbundle.tar.gz --checksum <checksum>
  ```
- Verify: `swift sdk list` → should show `swift-6.3.2-RELEASE_android`

**Step 5: Link the NDK to the Swift SDK**

- Run the setup script (uses `ANDROID_NDK_HOME` from Step 3):
  ```bash
  cd ~/Library/org.swift.swiftpm/swift-sdks/swift-6.3.2-RELEASE_android.artifactbundle/swift-android/
  ./scripts/setup-android-sdk.sh
  ```
- Cross-compilation toolchain is now ready
- Reference: [swift.org - Swift SDK for Android](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html)

**Emulator Setup (No Containers)**

- **iOS Simulator**: managed via Xcode → Window → Devices and Simulators → add iPhone/iPad simulator
  - Launch from terminal: `xcrun simctl boot <device-id>` then `open -a Simulator`
  - Or from VS Code command palette: `Emulator: Launch iOS Emulator`
- **Android Emulator**: managed via Android Studio → AVD Manager → create virtual device (Pixel 7, API 34+)
  - Launch: `emulator -avd <avd_name>`
  - Or from VS Code command palette: `Emulator: Launch Android Emulator`

**3. Project Architecture**

> **C# dev note:** `Package.swift` is the Swift equivalent of a `.csproj` file. It declares the project name, platform targets, dependencies (like NuGet refs but fetched from Git URLs), and build targets. `swift package init` ≈ `dotnet new console`.

**Scaffolding**

- `swift package init --type executable --name Feeds`
- Android via [Skip](https://skip.dev/) (Fuse mode): compiles shared Swift code natively for Android and bridges SwiftUI → Jetpack Compose
- Project structure:

```
feeds-swift-app/
├── Package.swift
├── project.yml
├── Skip.env
├── Darwin/
│   └── Sources/
│       └── Main.swift              # iOS/macOS @main entry point
├── Android/
│   ├── settings.gradle.kts
│   └── app/
│       ├── build.gradle.kts
│       ├── proguard-rules.pro
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── kotlin/Main.kt      # Android entry point (Compose)
├── Sources/
│   └── Feeds/
│       ├── Feeds.swift             # FeedsRootView (shared app root)
│       ├── Skip/
│       │   └── skip.yml            # Skip bridging config
│       ├── Models/
│       │   ├── AIModelInfo.swift
│       │   ├── AppTab.swift
│       │   ├── DiscoverFeed.swift
│       │   ├── FeedItem.swift
│       │   ├── FeedRecord.swift
│       │   ├── RssFeedModel.swift
│       │   └── SavedArticle.swift
│       ├── Views/
│       │   ├── ContentView.swift
│       │   ├── CardView.swift
│       │   ├── DashboardView.swift
│       │   ├── ArticleReadingView.swift
│       │   ├── ExploreView.swift
│       │   ├── HTMLContentView.swift
│       │   ├── ManageFeedsView.swift
│       │   ├── NewArticlesBanner.swift
│       │   ├── SearchView.swift
│       │   ├── SavedArticlesView.swift
│       │   ├── SettingsView.swift
│       │   ├── FeedSidebar.swift
│       │   ├── NavigationDrawer.swift
│       │   ├── MobileTabBar.swift
│       │   ├── ShareSheet.swift
│       │   └── Theme.swift
│       ├── ViewModels/
│       │   ├── FeedViewModel.swift
│       │   ├── ArticleReadingViewModel.swift
│       │   ├── BookmarkViewModel.swift
│       │   ├── ImageResolver.swift
│       │   ├── ModelManagerViewModel.swift
│       │   └── SettingsViewModel.swift
│       ├── Services/
│       │   ├── BookmarkEncryptionService.swift  # Key management for SQLCipher
│       │   ├── BookmarkStore.swift              # Protocol
│       │   ├── DefaultFeeds.swift               # Seed data for first launch
│       │   ├── InMemoryBookmarkStore.swift      # Test/fallback impl
│       │   ├── OpenGraphService.swift           # OG image extraction
│       │   ├── SQLiteBookmarkStore.swift        # SQLCipher-encrypted persistence
│       │   ├── SQLiteFeedStore.swift            # Feed subscription persistence
│       │   ├── FeedService.swift
│       │   ├── ModelRegistryService.swift
│       │   └── RSSXMLParser.swift
│       ├── Utils/
│       │   └── Helpers.swift
│       └── Resources/
│           ├── Assets.xcassets/
│           │   ├── AccentColor.colorset/
│           │   │   └── Contents.json
│           │   └── AppIcon.appiconset/
│           │       ├── Contents.json
│           │       └── logo.png
│           ├── ai_models.json
│           └── logo.svg
├── Tests/
│   └── FeedsTests/
│       └── FeedsTests.swift
```

**4. Model Layer**

> **C# dev note - key Swift syntax:**
> - `struct` = value type (same as C#, but used much more often - even for models)
> - `let` = `readonly` / immutable field; `var` = mutable field
> - `String?` = nullable, same `?` syntax as C# nullable reference types
> - `[T]` = `List<T>` - square brackets are shorthand for `Array<T>`
> - `: Codable` = conforming to a protocol (C#: implementing an interface). `Codable` ≈ `[JsonSerializable]` - gives auto JSON serialization
> - `: Identifiable` = requires an `id` property (C#: `IIdentifiable<T>`)
> - `UUID` = `Guid` in C# - `UUID()` ≈ `Guid.NewGuid()`
> - Computed property `var x: T { ... }` = C# `public T X => ...;`

**`RssFeedModel.swift`**

- `struct RssFeedModel: Identifiable` - runtime model with `id, title, url, suppressHeroImage`
- `enum FeedMenuItem: Identifiable` - menu hierarchy: `.single(RssFeedModel)` for standalone feeds, `.group(id, title, feeds)` for categorized feeds with sub-items

**`FeedRecord.swift`**

- `struct FeedRecord: Identifiable, Equatable` — SQLite persistence row: `id, title, url, groupId, groupTitle, sortOrder, suppressHeroImage`
- Maps to `RssFeedModel` at runtime; the `suppressHeroImage` flag controls hero image rendering per-feed
- Feeds are stored in SQLite (not bundled JSON) — allows dynamic add/remove without app rebuilds

**`FeedItem.swift`**

- `struct FeedItem: Identifiable` - `id: UUID, title: String, link: String, description: String, pubDate: String, imageURLs: [String?]`
- Computed property `displayImage: URL?` - returns first non-nil image URL from the array
- Computed property `plainDescription: String` - strips HTML tags from description for clean card previews (uses `Helpers.stripHTML`)
  <!-- URL in Swift = Uri in C#. compactMap removes nils ≈ .Where(x => x != null) -->

**5. Service Layer**

> **C# dev note - async & errors:**
> - `async throws` on a function = C# `async Task` that can throw. Swift uses `try await` where C# uses just `await`
> - `URLSession` = `HttpClient` - the standard HTTP client
> - `guard let x = ... else { return }` = early exit if nil - C#: `if (x is not Type val) return;`
> - `enum FeedError: Error` = custom exception types. Swift enums can carry associated data (like discriminated unions) - e.g. `.feedUnavailable(status: 404)` ≈ `new HttpRequestException(404)`
> - `try?` = try and return nil on failure (C#: try/catch returning null)

**`FeedService.swift`**

- `struct FeedService: FeedServiceProtocol` — lightweight value type implementing the service protocol for testable dependency injection
- Use `URLSession` for network requests (C#: `HttpClient`) - native on both iOS and Android via Swift Foundation
- 3-tier fetch strategy (direct first, proxy fallback):
  1. Direct URL fetch
  2. `https://rss-proxy-api.netlify.app/.netlify/functions/fetch-xml?url=<encoded>`
  3. `https://api.codetabs.com/v1/proxy/?quest=<encoded>`
- `func fetchFeed(url: String) async throws -> [FeedItem]` — instance method, injected into `FeedViewModel` via protocol
- All requests use a 15-second timeout (`timeoutInterval = 15`)
- Custom `FeedError` enum: `.networkError(Error)`, `.parsingError`, `.feedUnavailable(status: Int)`

**`RSSXMLParser.swift`**

- Use `Foundation.XMLParser` (delegate-based, SAX-style) to parse RSS `<item>` elements - C#: similar to `XmlReader` with event callbacks
- The delegate pattern: a class conforms to `XMLParserDelegate` protocol (C#: implements `IXmlParserHandler`) and receives `didStartElement`/`foundCharacters`/`didEndElement` callbacks
- Extract: `<title>`, `<link>`, `<description>`, `<pubDate>`, `<media:content url>`, `<enclosure url>`, `<media:thumbnail url>`
- Map parsed nodes → `[FeedItem]`

**Bookmark Persistence (SQLCipher-encrypted SQLite)**

- `BookmarkStore` protocol: async CRUD operations (`fetchAll`, `insert`, `delete(byID:)`, `delete(byLink:)`, `contains(link:)`)
- `SQLiteBookmarkStore`: production implementation using [SkipSQLPlus](https://skip.dev/docs/modules/skip-sql/) (cross-platform SQLite with SQLCipher 256-bit AES encryption)
  - Uses `PRAGMA key` for full-database encryption — all data encrypted at rest
  - Works identically on iOS and Android via SkipSQL's native C SQLite layer
  - Schema migration via `userVersion` pragma
- `InMemoryBookmarkStore`: lightweight in-memory implementation for tests and fallback
- `BookmarkKeyManager` (in `BookmarkEncryptionService.swift`): generates/stores the SQLCipher passphrase
  - Apple: stored in Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`)
  - Android/Linux: stored in a protected file (0600 permissions) at `~/.feeds/.bookmark_key`
  - Key is a 64-character hex string (256-bit entropy from `SecRandomCopyBytes` / `/dev/urandom`)

**Feed Subscription Persistence (SQLite)**

- `SQLiteFeedStore`: CRUD operations for feed subscriptions stored in SQLite (via SkipSQLPlus)
  - Table: `feed_subscription(id INTEGER PK AUTOINCREMENT, title TEXT, url TEXT, groupId TEXT?, groupTitle TEXT?, sortOrder INTEGER, suppressHeroImage INTEGER)`
  - Methods: `fetchAll()`, `insert(_:)`, `delete(byID:)`, `updateSuppressHeroImage(feedID:value:)`, `seedDefaults(_:)`, `isEmpty()`, `shouldSuppressHeroImage(feedID:)`, `heroImageSuppressedIDs()`
  - Schema migration via `userVersion` pragma (same pattern as BookmarkStore)
- `DefaultFeeds`: static seed data (`enum DefaultFeeds { static let all: [FeedRecord] }`) containing all 43 default feeds — loaded on first launch when the database is empty
- The `suppressHeroImage` flag allows per-feed hero image suppression (e.g., feeds with unreliable OG images)

**`OpenGraphService.swift`**

- `struct OpenGraphService` — extracts `og:image` meta tags from article HTML
- `func fetchOGImageURL(for articleURL: URL) async throws -> URL?` — fetches HTML, parses `<meta property="og:image" content="...">` via regex
- Handles HTML entity decoding (hex entities `&#x3A;`, decimal entities `&#58;`, named entities `&amp;`) for URLs encoded with entities (e.g., Hypebeast)

**`ImageResolver.swift`** (in ViewModels/)

- `class ImageResolver: ObservableObject` — resolves article hero images with fallback chain
- Resolution priority: (1) feed item's `imageURL`, (2) OpenGraph `og:image` from article HTML
- `@Published private var cache: [String: URL]` — per-session in-memory cache to avoid redundant fetches
- Respects `suppressHeroImage` flag and user `showImages` setting toggle

**6. View Layer (SwiftUI)**

> **C# dev note - SwiftUI vs Blazor/MAUI/WPF:**
> - SwiftUI is declarative like XAML, but written in Swift code (no separate markup file)
> - `struct ContentView: View` = a component. `: View` means it conforms to the `View` protocol (C#: `: IView`)
> - `var body: some View { ... }` = the render method. `some View` ≈ returning an interface; the compiler infers the concrete type
> - `@StateObject` = creates and owns a ViewModel instance - C#: `BindingContext = new ViewModel()` in MAUI, or `@inject` in Blazor
> - `@ObservedObject` = references an existing ViewModel (doesn't own it) - C#: receiving a ViewModel via DI/parameter
> - `VStack` / `HStack` = vertical/horizontal StackLayout - C#: `<StackPanel Orientation="Vertical/Horizontal">`
> - `.modifier()` chaining = fluent API - C#: like extension methods or XAML attached properties
> - `ForEach(items) { item in ... }` = C#: `@foreach` in Blazor or `ItemsSource` + `DataTemplate` in XAML
> - `.task { }` runs async work on appear - C#: `OnInitializedAsync()` in Blazor or `OnAppearing` in MAUI
> - `$0` in closures = shorthand for the first parameter - C#: unnamed lambda param

**`ContentView.swift`**

- `@StateObject var viewModel = FeedViewModel()` - C#: `private FeedViewModel vm = new();`
- Adaptive layout: desktop uses sidebar `NavigationDrawer`, mobile uses `MobileTabBar` with slide-out drawer
- Tab navigation via `AppTab` enum: Home, Unread, Bookmarks, Discover, Search, Settings
- `DashboardView` for feed content with bento grid layout (featured article + grid + compact rows)
- `ArticleReadingView` for full article reading with HTML rendering support via `HTMLContentView` (WKWebView)
- `HTMLContentView` adapts its CSS to match the active theme (light/dark/monochrome)
- Theme colors are injected via `@Environment(\.themeColors)` from `SettingsViewModel.themeColors` — no global mutable state
- Dependencies injected via `@EnvironmentObject`: `BookmarkViewModel`, `SettingsViewModel`, `ModelManagerViewModel`

**`CardView.swift`** _(legacy — replaced by `FeaturedArticleCard`/`ArticleCard`/`CompactArticleRow` in `DashboardView`)_

- `AsyncImage(url:)` for feed item images with placeholder - C#: `Image` with `HttpClient`-backed source
- Desaturated images (`.saturation(0)`) for monochromatic design aesthetic
- Card variants: `FeaturedArticleCard` (hero + overlay), `ArticleCard` (grid), `CompactArticleRow` (list)
- Cards display `plainDescription` (HTML-stripped) with `lineLimit` caps
- Uses design system typography (`.headlineMedium()`, `.bodyMedium()`, `.labelXSmall()`) instead of system fonts
- `.clipShape(RoundedRectangle)` + `.overlay(stroke)` for card styling

**`FeedSidebar.swift`**

- `List` with `ForEach` over `viewModel.menuItems` rendering hierarchical sidebar navigation:
  - `.single` feeds (HBX, WIRED, MyBroadband) render as direct rows
  - `.group` feeds (Sports, News, Tech, Runtastic, Reddit) render as expandable `DisclosureGroup` sections with sub-item rows
- Selected feed shows a checkmark indicator
- On feed selection, collapses sidebar to detail-only on compact (iPhone) devices via `@Binding columnVisibility`

**`ManageFeedsView.swift`**

- Full feed management UI: list all subscriptions, swipe-to-delete, toggle hero image suppression per-feed
- `AddFeedSheet`: form for adding new feeds with title, URL, optional group, and hero image suppression toggle
- URL validation: checks for valid scheme (http/https) and non-empty host before insertion
- Accessible via Settings → Feed Subscriptions → Manage Feeds

**7. ViewModel**

> **C# dev note - MVVM in Swift:**
> - `class FeedViewModel: ObservableObject` = C#: a class implementing `INotifyPropertyChanged` (or using `[ObservableObject]` from CommunityToolkit.Mvvm)
> - `@Published var` = C#: `[ObservableProperty]` - auto-fires change notifications to the UI
> - `@MainActor` on the class = ensures all updates run on the UI thread - C#: like wrapping setters in `Dispatcher.Invoke()` or `MainThread.BeginInvokeOnMainThread()`
> - Swift enforces this at compile time; C# lets you crash at runtime
> - `func selectFeed(_ feed:)` - the underscore `_` drops the external parameter label - C#: callers write `selectFeed(myFeed)` not `selectFeed(feed: myFeed)`

**`FeedViewModel.swift`**

- `@Published var feedItems: [FeedItem] = []` - C#: `ObservableCollection<FeedItem>`
- `@Published var allFeeds: [RssFeedModel] = []`
- `@Published var menuItems: [FeedMenuItem] = []` - hierarchical menu structure for sidebar rendering
- `@Published var selectedFeed: RssFeedModel?`
- `@Published var errorMessage: String?`
- `@Published var isLoading: Bool = false`
- `@Published var unreadItems: [FeedItem]` - filtered unread articles
- `var hasItems: Bool { !feedItems.isEmpty }` - computed property for view rendering
- Uses `os.Logger` (subsystem: `co.za.eoitech.feeds`, category: `FeedViewModel`) for operational logging
- Accepts `FeedServiceProtocol` via `init(feedService:)` for testable dependency injection (defaults to `FeedService()`)
- `func loadConfig()` - load feed subscriptions from SQLite (seeds defaults on first launch), build flat `allFeeds` list and hierarchical `menuItems` for grouped navigation
- `func selectFeed(_ feed: RssFeedModel) async` - set selected, set `isLoading`, call `fetchFeed`, update `feedItems`
- `func refreshFeed() async` — silent refresh (no loading spinner) for pull-to-refresh
- `func addFeed(title:url:groupTitle:suppressHeroImage:)` — insert new subscription into SQLite and reload config
- `func deleteFeed(_:)` — remove subscription from SQLite and reload config
- `func toggleSuppressHeroImage(_:)` — toggle hero image suppression per-feed in SQLite
- `func startAutoRefresh()` / `func stopAutoRefresh()` — 15-minute background refresh with notification posting
- 3-tier error handling: `FeedError` cases → user-safe messages, `URLError` → network message, catch-all → generic message
- `func discoverFeeds(query:)` — search feeds, `func generateOPML()` — export subscriptions as OPML
- Computed: `filteredDiscoverFeeds(query:)`, `groupedDiscoverFeeds(query:)`, `feedCategories`

**`SettingsViewModel.swift`**

- `@Published var themeColors: ThemeColors` — resolved theme colors for the current appearance mode
- `@Published var appearanceMode: String` — persisted in `UserDefaults` (`"auto"`, `"light"`, `"dark"`, `"monochrome"`)
- `init(defaults: UserDefaults = .standard)` — injectable `UserDefaults` for testability
- `func cycleAppearance()` — cycles through Auto → Light → Dark → Monochrome
- `func applyAutoTheme(systemIsDark:)` — resolves Auto mode based on device system appearance

**`Theme.swift`**

- `ThemeColors` struct with 30+ semantic color properties (`.light`, `.dark`, `.monochrome` presets)
- Injected into the view hierarchy via custom `EnvironmentKey` (`ThemeColorsKey`)
- Views access colors via `@Environment(\.themeColors) private var theme`
- `Theme.resolve(_:)` maps appearance mode string → `ThemeColors`

**8. Utilities**

> **C# dev note:** `DateFormatter` ≈ `DateTime.ParseExact()` with `CultureInfo.InvariantCulture`. Swift uses `Locale(identifier: "en_US_POSIX")` where C# uses `CultureInfo.InvariantCulture`.

**`Helpers.swift`**

- `static func formatDate(_ dateString: String) -> String` - parse RSS date format (`EEE, dd MMM yyyy HH:mm:ss Z`) via `DateFormatter`
- `static func stripHTML(_ html: String) -> String` - strips HTML tags and decodes common HTML entities for plain-text preview display
- `static func escapeXML(_ string: String) -> String` - escapes special XML characters for safe OPML export

**On-Device AI Summaries (MLX)**

- Runtime: [mlx-swift-lm](https://github.com/ml-explore/mlx-swift-lm) (Apple MLX framework for on-device LLM inference on Apple Silicon)
- Dependencies: `mlx-swift-lm` 3.31.3+, `swift-huggingface` 0.9.0+, `swift-transformers` 1.3.0+ — all conditionally compiled for macOS/iOS only (`.when(platforms: [.macOS, .iOS])`)
- **Simulator limitation:** All MLX code paths are guarded with `#if canImport(MLXLLM) && !targetEnvironment(simulator)`. The iOS Simulator lacks a real Metal GPU, causing uncatchable `abort()` crashes in MLX's C++ Metal backend. On the simulator, `isMLXAvailable` returns `false` and the UI shows: _"AI models require a physical device. The simulator does not support on-device inference."_
- Model list: dynamic — fetched from the HuggingFace API (`https://huggingface.co/api/models?author=mlx-community`), filtered client-side for small quantized instruction models (< 5B params, 4-bit/QAT). Falls back to bundled `ai_models.json`
- Curated models (bundled fallback): Gemma 3 1B, Qwen 3 0.6B, Qwen 3 1.7B, Llama 3.2 1B/3B, SmolLM3 3B, Gemma 3n E2B, Qwen 2.5 1.5B
- Model lifecycle: download from HuggingFace Hub → cache locally → load into memory → generate summaries → delete cached files when no longer needed
- Inference: `ChatSession` API — prompts the model with article text (truncated to 2000 chars) and returns a 2-3 sentence summary
- **Android AI (planned)**: AI features are guarded with `#if canImport(MLXLLM) && !targetEnvironment(simulator)`. On non-Apple platforms (and the iOS Simulator), the UI shows a platform requirement message instead of the model list. Roadmap for Android local AI:
  1. Add `llama.cpp` as a C dependency in `Package.swift` (conditionally for Android via `.when(platforms:)`)
  2. Create an `LLMProvider` protocol abstracting model load + inference
  3. Implement `MLXProvider` (Apple) and `LlamaCppProvider` (Android) conformances
  4. Swap provider in `ModelManagerViewModel.init` based on platform availability
  5. Host quantized GGUF models on HuggingFace for Android downloads

**`AIModelInfo.swift`**

- `struct AIModelInfo: Identifiable, Equatable, Codable` — model metadata with `id`, `name`, `description`, `sizeLabel`, `huggingFaceID`
- `static let fallback: [AIModelInfo]` — compile-time fallback when both remote fetch and bundled JSON fail

**`ModelRegistryService.swift`**

- `static func fetchModels() async -> [AIModelInfo]` — tries HuggingFace API first, falls back to bundled `ai_models.json`, then compile-time fallback
- Remote fetch filters for small quantized models from `mlx-community` and auto-generates display names and size estimates
- 10-second timeout on API requests to avoid blocking app launch

**`ModelManagerViewModel.swift`**

- `@Published var availableModels: [AIModelInfo]` — dynamic model list loaded on launch
- `@Published var downloadedModelIDs: Set<String>` — persisted in `UserDefaults`
- `@Published var activeModelID: String?` — the currently loaded model
- `isMLXAvailable: Bool` — compile-time check: `true` on physical macOS/iOS devices, `false` on simulator and non-Apple platforms
- `downloadAndActivate(_:)` — downloads model from HuggingFace Hub via `loadModelContainer(from:using:configuration:progressHandler:)` with real-time progress tracking. Uses `LLMRegistry` for curated models, falls back to `ModelConfiguration(id:)` for dynamically discovered models. Categorized error messages: network → connection message, disk → storage message, cancelled → silent, fallback → generic safe message
- `deleteModel(_:)` — deactivates if active, deletes Hub cache files from `{cachesDir}/huggingface/hub/models--{org}--{model}/`, removes from downloaded set
- `generateSummary(for:)` — creates a `ChatSession` with `maxTokens: 256`, sends a summarization prompt, returns the response
- `restoreActiveModel()` — called on app launch to reload the previously active model
- All MLX code paths guarded with `#if canImport(MLXLLM) && !targetEnvironment(simulator)` — prevents simulator crashes from MLX's Metal backend

**Auto-Refresh & Pull-to-Refresh**

- Auto-refresh: `FeedViewModel` runs a background task that refreshes the current feed every 15 minutes (configurable via `settings.autoRefresh` toggle)
- Shows a cross-platform in-app `NewArticlesBanner` when new articles are detected (auto-dismisses after 5 seconds)
- Works identically on iOS, macOS, and Android — no platform-specific notification APIs required
- Pull-to-refresh: `.refreshable` modifier on `DashboardView` triggers a silent refresh without showing the loading spinner
- Both use separate codepaths from `selectFeed` to avoid resetting the loading state and destroying the scroll position

**9. Building & Running**

**iOS (Simulator)**

- **One-time prerequisite** for Xcode builds with MLX (Metal shaders):
  ```bash
  xcodebuild -downloadComponent MetalToolchain
  ```
- **Trusting MLX macros** — `mlx-swift-lm` uses Swift macros (`MLXHuggingFaceMacros`). Xcode requires explicit trust before it will compile them:
  - **Xcode GUI**: On first build, Xcode shows a dialog: _"Package 'mlx-swift-lm' wants to use macro 'MLXHuggingFaceMacros'"_ → click **Trust & Enable**. This is persisted in the Xcode project and only needs to be done once. If using XcodeGen, re-running `xcodegen generate` resets the project and the trust dialog will appear again on next build.
  - **xcodebuild CLI**: Pass `-skipMacroValidation` to bypass macro trust (there is no project-level setting for this):
    ```bash
    xcodebuild -project Feeds.xcodeproj -scheme Feeds \
      -destination 'platform=iOS Simulator,name=iPhone 17' \
      -skipMacroValidation build
    ```
  - **Global disable** (persists across all projects for your machine):
    ```bash
    defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
    ```
- Build natively (macOS CLI only - no `.app` bundle):
  ```bash
  swift build
  ```
- Clean build (use when switching branches, renaming the project folder, or after toolchain updates):
  ```bash
  rm -rf .build && swift build
  ```
- Open in Xcode (official - Xcode natively supports SwiftPM packages):
  ```bash
  open Package.swift
  # Select the Feeds scheme → choose a destination → Product → Run (⌘R)
  ```
- Or generate the Xcode project with [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for iOS app target with `Info.plist` and bundle ID):
  ```bash
  brew install xcodegen   # one-time install
  xcodegen generate       # creates Feeds.xcodeproj from project.yml
  open Feeds.xcodeproj
  # Select iPhone 17 destination → Product → Run (⌘R)
  ```

**iOS Deployment**

**Simulator**

> **Note:** SwiftPM `.executableTarget` produces a bare binary, not a `.app` bundle.
> iOS Simulator requires a `.app` bundle with `Info.plist` and `CFBundleIdentifier`.
> You can open `Package.swift` directly in Xcode (official method - works for macOS), or use `project.yml` + XcodeGen to generate a proper Xcode project with an iOS app target.

1. Open in Xcode - choose one:
   ```bash
   # Official: open the package directly (Xcode auto-creates schemes)
   open Package.swift

   # Or: generate an Xcode project with XcodeGen (for iOS app bundle)
   xcodegen generate   # creates Feeds.xcodeproj from project.yml
   open Feeds.xcodeproj
   ```
2. Select the simulator destination in Xcode's toolbar (e.g. "iPhone 17") or from the CLI:
   ```bash
   # List available simulators
   xcrun simctl list devices available

   # Boot a simulator (if not already running)
   xcrun simctl boot "iPhone 17"
   open -a Simulator
   ```
3. Build and run on the simulator:
   ```bash
   # Via Xcode: open the project → select iPhone 17 → Product → Run (⌘R)
   open Feeds.xcodeproj

   # Via CLI: build and deploy (requires Metal Toolchain + macro flag)
   # One-time prerequisite: xcodebuild -downloadComponent MetalToolchain
   xcodebuild -project Feeds.xcodeproj -scheme Feeds \
     -destination 'platform=iOS Simulator,name=iPhone 17' \
     -skipMacroValidation build

   # Install and launch on the simulator
   xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/Feeds-*/Build/Products/Debug-iphonesimulator/Feeds.app
   xcrun simctl launch booted com.feeds.Feeds
   ```
4. View simulator logs:
   ```bash
   xcrun simctl spawn booted log stream
   ```

**Physical Device**

> Requires an Apple Developer account (free or paid). Code signing cannot be bypassed - it is enforced by iOS at the OS level.

0. **Get a free Apple Developer certificate and configure signing**:
   - Create a free Apple ID at [appleid.apple.com](https://appleid.apple.com) if you don't have one
   - Open Xcode → **Settings** (⌘,) → **Accounts** tab → click **+** → **Apple ID** → sign in with your Apple ID
   - Xcode automatically creates a free **Apple Development** signing certificate and registers your account as a Personal Team
   - No enrollment or payment required - a standard Apple ID is sufficient for on-device development
   - To verify: select your Apple ID in the Accounts list → click **Manage Certificates** → you should see an "Apple Development" certificate
   - If the certificate is missing, click **+** in the Manage Certificates sheet → select **Apple Development** → Xcode generates and installs it into your Keychain
   - **Set up project signing**: generate the Xcode project (`xcodegen generate`) → open `Feeds.xcodeproj` → select the **Feeds** target → **Signing & Capabilities** tab
   - Check **Automatically manage signing** (should already be enabled - `CODE_SIGN_STYLE: Automatic` is set in `project.yml`)
   - Set **Team** to your Personal Team (your Apple ID name with "(Personal Team)" suffix)
   - Set **Bundle Identifier** to a unique reverse-DNS string (e.g. `com.yourname.Feeds`) - free accounts require a globally unique ID
   - Xcode auto-generates a provisioning profile linking your certificate, bundle ID, and device - no manual profile creation needed
   - The signing identity (`CODE_SIGN_IDENTITY: "Apple Development"`) and style are pre-configured in `project.yml`, so re-running `xcodegen generate` preserves these settings
   - **Configure device orientation**: select the **Feeds** target → **General** tab → scroll to **Deployment Info** → under **Device Orientation**, check all four:
     - **Portrait** - standard upright orientation
     - **Upside Down** - iPad only (Xcode grays this out for iPhone)
     - **Landscape Left** - home button / gesture bar on the right
     - **Landscape Right** - home button / gesture bar on the left
   - These correspond to `INFOPLIST_KEY_UISupportedInterfaceOrientations` in `project.yml` - all four orientations are pre-configured
   - **Set app category**: in the same **General** tab → **Identity** section → set **App Category** to **News** (maps to `INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.news` in `project.yml`)
   - **Set version**: in **Identity** section → set **Version** to `0.1.0` and **Build** to `1` (maps to `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`)

1. **Register your device**: Connect via USB → open Xcode → Window → Devices and Simulators → your device appears automatically. Xcode registers the device ID with your Apple Developer account.

2. **Trust the developer certificate on the device** (free accounts only):
   - On the device: Settings → General → VPN & Device Management → tap your developer certificate → Trust

3. **Build and deploy**:
   ```bash
   # Via Xcode: select your device in the destination picker → Product → Run (⌘R)

   # Via CLI:
   xcodebuild -scheme Feeds \
     -destination 'id=<device-udid>' \
     -allowProvisioningUpdates \
     -skipMacroValidation build

   # Find your device UDID:
   xcrun xctrace list devices
   ```

4. **Wireless debugging** (iOS 14+): In Xcode → Window → Devices and Simulators → select your device → check "Connect via network". After initial USB pairing, deploy wirelessly.

5. **Limitations (free Apple Developer account)**:
   - Apps expire after 7 days - reinstall to refresh
   - Limited to 3 apps installed via free provisioning at a time
   - No App Store distribution, push notifications, or some entitlements
   - Paid account ($99/year) removes these limits and enables App Store publishing

**Android (Emulator via Skip)**

- Install Skip CLI (one-time):
  ```bash
  brew tap skiptools/skip && brew install skip
  skip checkup   # verifies Android SDK, NDK, JDK are configured
  ```
- Build the Android app (generates APK via Gradle):
  ```bash
  skip android build
  ```
- Run on a connected emulator or device:
  ```bash
  skip android run
  ```
- The Android project scaffold is in `Android/` — standard Gradle structure with Kotlin entry point (`Main.kt`) that bridges to `FeedsRootView` via Skip Fuse
- Skip config: `Skip.env` (bundle ID, package name), `Sources/Feeds/Skip/skip.yml` (bridge mode)

**Android (CLI-only — no Skip)**

- Cross-compile for the emulator (`x86_64`) or a physical device (`aarch64`):
  ```bash
  # For emulator (x86_64)
  swift build --swift-sdk x86_64-unknown-linux-android36 --static-swift-stdlib

  # For physical device (aarch64)
  swift build --swift-sdk aarch64-unknown-linux-android36 --static-swift-stdlib
  ```
- Push to a running emulator or USB-debugging-enabled device via `adb`:
  ```bash
  adb push .build/x86_64-unknown-linux-android36/debug/Feeds /data/local/tmp
  adb push $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so /data/local/tmp/
  adb shell /data/local/tmp/Feeds
  ```
- Note: CLI-only builds produce a headless binary (no UI). For a full UI app, use Skip (above)

**VS Code Workflow**

- Wire up **Tasks** in `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build iOS",
      "type": "shell",
      "command": "swift build",
      "group": "build"
    },
    {
      "label": "Build Android (x86_64)",
      "type": "shell",
      "command": "swift build --swift-sdk x86_64-unknown-linux-android36 --static-swift-stdlib",
      "group": "build"
    },
    {
      "label": "Test iOS Simulator",
      "type": "shell",
      "command": "swift test",
      "group": "test"
    },
    {
      "label": "Test iOS Simulator (with coverage)",
      "type": "shell",
      "command": "swift test --enable-code-coverage",
      "group": "test"
    },
    {
      "label": "Deploy Android Emulator",
      "type": "shell",
      "command": "adb push .build/x86_64-unknown-linux-android36/debug/Feeds /data/local/tmp && adb push $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so /data/local/tmp/ && adb shell /data/local/tmp/Feeds",
      "group": "test",
      "dependsOn": "Build Android (x86_64)"
    },
    {
      "label": "Launch iOS Simulator",
      "type": "shell",
      "command": "xcrun simctl boot \"iPhone 17\" 2>/dev/null; open -a Simulator"
    },
    {
      "label": "Launch Android Emulator",
      "type": "shell",
      "command": "emulator -avd $(emulator -list-avds | head -1) &"
    }
  ]
}
```

- Use **LLDB DAP** launch config for Swift debugging on iOS
- Use **Android Logcat** in VS Code terminal for Android debugging

**10. Debugging**

**iOS / macOS (VS Code + LLDB DAP)**

- Install the [LLDB DAP extension](https://marketplace.visualstudio.com/items?itemName=llvm-vs-code-extensions.lldb-dap) - required by the Swift extension for debugging
- The Swift extension auto-creates a launch config for each executable target
- Custom `launch.json` example:
  ```json
  {
    "configurations": [
      {
        "type": "swift",
        "name": "Debug Feeds",
        "request": "launch",
        "args": [],
        "cwd": "${workspaceFolder}",
        "program": "${workspaceFolder}/.build/debug/Feeds",
        "preLaunchTask": "swift: Build Debug Feeds"
      }
    ]
  }
  ```
- Set breakpoints in the editor → launch via the Debug view (green play button)
- Hover over variables to inspect values; use the Debug sidebar for call stack, watch expressions, and scope variables

**iOS Simulator (Xcode Instruments)**

- Profile performance, memory, networking, and energy: `Instruments.app` (bundled with Xcode)
- Attach to a running simulator process or launch directly from Instruments
- Key instruments for an RSS reader: **Network** (monitor feed requests), **Time Profiler** (XML parsing perf), **Allocations** (memory during image loading)

**Android (adb + Logcat)**

- View real-time logs from the emulator/device:
  ```bash
  adb logcat
  ```
- Filter by tag or priority:
  ```bash
  adb logcat -s "SwiftRuntime:V" "*:E"
  ```
- For native crash debugging, use `ndk-stack` to symbolicate stack traces:
  ```bash
  adb logcat | $ANDROID_NDK_HOME/ndk-stack -sym .build/x86_64-unknown-linux-android36/debug/
  ```
- For interactive debugging, use `lldb-server` on the device with a remote LLDB session:
  ```bash
  # Push lldb-server to device
  adb push $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/lib/clang/*/lib/linux/x86_64/lldb-server /data/local/tmp/
  # Start lldb-server on device
  adb shell /data/local/tmp/lldb-server platform --listen "*:1234" --server
  # Forward port
  adb forward tcp:1234 tcp:1234
  # Connect from host
  lldb
  (lldb) platform select remote-android
  (lldb) platform connect connect://localhost:1234
  (lldb) target create .build/x86_64-unknown-linux-android36/debug/Feeds
  (lldb) run
  ```

**Testing**

**iOS Simulator Testing**

- Run all tests natively (macOS host / iOS Simulator):
  ```bash
  swift test
  ```
- Run a specific test suite:
  ```bash
  swift test --filter HelpersTests
  ```
- Run with code coverage:
  ```bash
  swift test --enable-code-coverage
  # View coverage report:
  xcrun llvm-cov report .build/debug/FeedsPackageTests.xctest/Contents/MacOS/FeedsPackageTests \
    --instr-profile .build/debug/codecov/default.profdata
  ```
- Build and run on a specific iOS Simulator destination via `xcodebuild`:
  ```bash
  xcodebuild test -scheme Feeds -destination 'platform=iOS Simulator,name=iPhone 17' \
    -skipMacroValidation -resultBundlePath TestResults.xcresult
  ```

**Android Emulator Testing**

- Cross-compile for the Android emulator (`x86_64`):
  ```bash
  swift build --swift-sdk x86_64-unknown-linux-android36 --static-swift-stdlib
  ```
- Start the Android emulator (if not already running):
  ```bash
  emulator -avd $(emulator -list-avds | head -1) &
  adb wait-for-device
  ```
- Deploy and run on the emulator:
  ```bash
  adb push .build/x86_64-unknown-linux-android36/debug/Feeds /data/local/tmp/
  adb push $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/sysroot/usr/lib/x86_64-linux-android/libc++_shared.so /data/local/tmp/
  adb shell /data/local/tmp/Feeds
  ```
- For a physical device (`aarch64`):
  ```bash
  swift build --swift-sdk aarch64-unknown-linux-android36 --static-swift-stdlib
  adb push .build/aarch64-unknown-linux-android36/debug/Feeds /data/local/tmp/
  adb push $ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so /data/local/tmp/
  adb shell /data/local/tmp/Feeds
  ```
- View runtime output:
  ```bash
  adb logcat -s "SwiftRuntime:V" "*:E"
  ```

**VS Code Test Explorer**

- The Swift extension supports [XCTest](https://developer.apple.com/documentation/xctest) and [Swift Testing](https://swiftpackageindex.com/swiftlang/swift-testing/main/documentation/testing)
- Tests auto-appear in the VS Code Test Explorer sidebar
- Run, debug, or run with coverage directly from the Test Explorer
- Debug a test: set a breakpoint → run with the `Debug Test` profile
- Coverage: use the `Run Test with Coverage` profile - covered lines show green, missed lines show red

- **CORS proxies**: still useful on Android (some feeds block non-browser user-agents); on iOS `URLSession` handles redirects natively
- **App Transport Security (iOS)**: add `NSAppTransportSecurity` → `NSAllowsArbitraryLoads: true` in `Info.plist` for HTTP feeds
- **Android Network Security**: add `android:usesCleartextTraffic="true"` in `AndroidManifest.xml` or use a network security config
- **Images**: `AsyncImage` (iOS SwiftUI) / custom image loading on Android side (Coil/Glide in Kotlin shell)
- **Dark mode**: Three theme modes via Settings - **Light** (standard light appearance), **Dark** (standard iOS/macOS dark), and **Monochrome** (Monolithic Clarity custom design: pure black background, white-only accents, fully desaturated). Theme colors are defined in `Theme.swift` with a `ThemeColors` struct and three presets. All views reference `Theme.xxx` computed properties that resolve from the active preset.

**12. Android App Packaging (Skip Fuse)**

- This project uses [Skip](https://skip.dev/) (Fuse mode) for full Android app packaging
- Skip compiles shared Swift code natively for Android and bridges SwiftUI views → Jetpack Compose
- Architecture: `Sources/Feeds/` contains all shared code → Skip plugin compiles it for Android → `Android/` contains the Gradle project shell with Kotlin entry point
- Key files:
  - `Skip.env`: bundle ID, package name, version
  - `Sources/Feeds/Skip/skip.yml`: bridging mode (`native` + `public`)
  - `Android/app/src/main/kotlin/Main.kt`: Android `MainActivity` + `AndroidAppMain` composable
  - `Darwin/Sources/Main.swift`: iOS/macOS `@main` entry point
- Cross-platform dependencies (work on both platforms via Skip):
  - `SkipFuse`: native Swift compilation + bridging runtime for Android
  - `SkipFuseUI`: SwiftUI → Compose bridge
  - `SkipSQLPlus`: SQLite + SQLCipher encryption (cross-platform)
- Apple-only dependencies (conditionally compiled):
  - `MLXLLM`, `MLXLMCommon`, `MLXHuggingFace`: on-device AI inference
  - `HuggingFace`, `Tokenizers`: model downloads and tokenization

**13. Troubleshooting**

| Error | Cause | Fix |
|-------|-------|-----|
| `No such module 'SkipFuse'` (VS Code) | SourceKit-LSP index is stale after package resolution | `Cmd+Shift+P` → **Swift: Restart LSP Server**. If persists: **Swift: Clean Build** then restart LSP |
| `Undefined symbol: _main` | Xcode project missing the `@main` entry point (`Darwin/Sources/Main.swift`) | Ensure `project.yml` includes `- path: Darwin/Sources` in the sources list, then `xcodegen generate` |
| `failed to find blueprint corresponding to PIF GUID: "PACKAGE-RESOURCE:SkipSQLPlus"` | Stale SPM build cache after dependency changes | `rm -rf .build && swift package resolve` |
| `failed to load toolchain: toolchain 'com.apple.dt.toolchain.XcodeDefault' already registered` | A symlink in `~/Library/Developer/Toolchains/` points back to Xcode's toolchain, creating a duplicate | Remove the offending symlink: `rm ~/Library/Developer/Toolchains/swift-<version>.xctoolchain` (only if it symlinks to `XcodeDefault.xctoolchain`) |
| Xcode macro trust dialog reappears after `xcodegen generate` | XcodeGen regenerates the project, resetting macro trust | Either re-trust in the dialog, pass `-skipMacroValidation` to `xcodebuild`, or run `defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES` |
| `SWBBuildService quit unexpectedly` | Corrupted Xcode build service state (derived data or caches) | Quit Xcode, run `rm -rf ~/Library/Developer/Xcode/DerivedData/feeds-* && rm -rf ~/Library/Caches/com.apple.dt.Xcode`, then reopen. If it persists, restart macOS. |
| `dyld: Library not loaded: @rpath/SkipFuse.framework/SkipFuse` (physical device crash at launch) | Dynamic frameworks (SkipFuse, SkipFuseUI, SkipSQLPlus) not embedded in the app bundle — works on simulator but crashes on device | Add `embed: true` to dynamic framework dependencies in `project.yml` (Skip packages only — MLX/HuggingFace/Tokenizers are static and must NOT have `embed: true`), then `xcodegen generate` and clean build |
| `lstat(.../<PackageName>): No such file or directory` during embed phase | `embed: true` set on a static library package dependency — Xcode tries to copy a framework that doesn't exist | Remove `embed: true` from that dependency in `project.yml` (only dynamic frameworks like SkipFuse/SkipFuseUI/SkipSQLPlus need embedding) |

**14. Resources**

- [Skip Documentation](https://skip.dev/docs/)
- [Skip Fuse Mode](https://skip.dev/docs/modes/)
- [SkipSQL (SQLite + SQLCipher)](https://skip.dev/docs/modules/skip-sql/)
- [Swift SDK for Android - Getting Started](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html)
- [Android category on Swift Forums](https://forums.swift.org/c/platform/android/115)

---

**Appendix: Swift ↔ C# Quick Reference**

| Swift | C# | Notes |
|---|---|---|
| `import Foundation` | `using System;` | Import a module (namespace) |
| `let x = 5` | `readonly int x = 5;` | Immutable binding |
| `var x = 5` | `int x = 5;` | Mutable variable |
| `String?` | `string?` | Nullable - same syntax |
| `[T]` | `List<T>` | Array/list of T |
| `[String: Any]` | `Dictionary<string, object>` | Dictionary |
| `struct` | `struct` (value type) | Used far more often in Swift |
| `class` | `class` (reference type) | Same concept |
| `protocol` | `interface` | Defines a contract |
| `: Codable` | `[JsonSerializable]` | Auto JSON encode/decode |
| `: Identifiable` | `: IIdentifiable<T>` | Requires `id` property |
| `UUID()` | `Guid.NewGuid()` | New unique ID |
| `URL(string:)` | `new Uri(string)` | URL/URI - Swift returns nil if invalid |
| `guard let x = y else { return }` | `if (y is not T x) return;` | Unwrap-or-exit |
| `if let x = optional { }` | `if (optional is T x) { }` | Unwrap optional |
| `try await fetch()` | `await FetchAsync()` | Swift requires explicit `try` |
| `async throws` | `async Task` | Async method that can throw |
| `do { try } catch { }` | `try { } catch { }` | Error handling |
| `enum E: Error` | `class E : Exception` | Custom error/exception |
| `$0` in closures | `x =>` lambda param | Shorthand unnamed parameter |
| `.compactMap { $0 }` | `.Where(x => x != null)` | Filter nils |
| `.map { transform($0) }` | `.Select(x => transform(x))` | Transform each element |
| `.filter { condition($0) }` | `.Where(x => condition(x))` | Filter elements |
| `.first` | `.FirstOrDefault()` | First element or nil/default |
| `switch` (no fallthrough) | `switch` (requires `break`) | Swift doesn't fall through |
| `@main` | `static void Main()` | App entry point |
| `@Published var` | `[ObservableProperty]` | Auto-notifies UI on change |
| `@StateObject` | `BindingContext = new VM()` | Owns a ViewModel |
| `@ObservedObject` | injected ViewModel | Observes an existing ViewModel |
| `ObservableObject` | `INotifyPropertyChanged` | Makes class observable |
| `@MainActor` | `Dispatcher.Invoke()` | Ensures UI-thread execution |
| `VStack { }` | `<StackPanel Orientation="V">` | Vertical layout |
| `HStack { }` | `<StackPanel Orientation="H">` | Horizontal layout |
| `.padding()` | `Margin/Padding` | Spacing |
| `ForEach(items) { }` | `@foreach` / `ItemsSource` | Iterate collection in UI |
| `Bundle.main` | `Assembly.GetExecutingAssembly()` | App resource bundle |
| `JSONDecoder().decode()` | `JsonSerializer.Deserialize<T>()` | JSON parsing |
| `DateFormatter` | `DateTime.ParseExact()` | Date formatting |
| `// MARK: - Section` | `#region Section` | Code section header |
