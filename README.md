# Feeds Reader in Swift for Android & iOS - VS Code + Emulators

**1. Project Overview**

- **Purpose**: RSS feed reader that fetches/parses XML feeds, displays articles as image cards in a grid, supports categorized feed navigation
- **Core features**: JSON-based feed config → XML fetch (with proxy fallback) → parse → card grid UI → sidebar with grouped feed navigation
- **Key models**: `RssFeedModel(id, title, url)`, `FeedItem` with title/link/description/pubDate/imageURLs

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
- For Android app packaging, use [swift-java](https://github.com/swiftlang/swift-java) to bridge Swift modules into a Kotlin/Java Android app shell
- See [swift-android-examples](https://github.com/swiftlang/swift-android-examples) for full app project templates
- Project structure:

```
feeds-swift-app/
├── Package.swift
├── project.yml
├── Sources/
│   └── Feeds/
│       ├── Feeds.swift
│       ├── Models/
│       │   ├── AppTab.swift
│       │   ├── DiscoverFeed.swift
│       │   ├── FeedItem.swift
│       │   ├── RssFeedModel.swift
│       │   └── SavedArticle.swift
│       ├── Views/
│       │   ├── ContentView.swift
│       │   ├── CardView.swift
│       │   ├── DashboardView.swift
│       │   ├── ArticleReadingView.swift
│       │   ├── ExploreView.swift
│       │   ├── HTMLContentView.swift
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
│       │   └── SettingsViewModel.swift
│       ├── Services/
│       │   ├── FeedService.swift
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
│           ├── feeds.json
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

- `struct FeedConfig: Codable, Identifiable` - `id: Double, title: String, url: String?, categories: [FeedCategory]?`
  <!-- C#: public record FeedConfig(double Id, string Title, string? Url, List<FeedCategory>? Categories); -->
- `struct FeedCategory: Codable, Identifiable` - `id: Double, title: String, url: String`
- `struct RssFeedModel: Identifiable` - flattened runtime model with `id, title, url`
- `enum FeedMenuItem: Identifiable` - menu hierarchy: `.single(RssFeedModel)` for standalone feeds, `.group(id, title, feeds)` for categorized feeds with sub-items
- Bundle `feeds.json` in `Resources/` and decode with `JSONDecoder` (C#: `JsonSerializer.Deserialize<T>()`)

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
- Dependencies injected via `@EnvironmentObject`: `BookmarkViewModel`, `SettingsViewModel`

**`CardView.swift`**

- `AsyncImage(url:)` for feed item images with placeholder - C#: `Image` with `HttpClient`-backed source
- Desaturated images (`.saturation(0)`) for monochromatic design aesthetic
- Card variants: `FeaturedArticleCard` (hero + overlay), `ArticleCard` (grid), `CompactArticleRow` (list)
- Cards display `plainDescription` (HTML-stripped) with `lineLimit` caps
- `.clipShape(RoundedRectangle)` + `.overlay(stroke)` for card styling

**`FeedSidebar.swift`**

- `List` with `ForEach` over `viewModel.menuItems` rendering hierarchical sidebar navigation:
  - `.single` feeds (HBX, WIRED, MyBroadband) render as direct rows
  - `.group` feeds (Sports, News, Tech, Runtastic, Reddit) render as expandable `DisclosureGroup` sections with sub-item rows
- Selected feed shows a checkmark indicator
- On feed selection, collapses sidebar to detail-only on compact (iPhone) devices via `@Binding columnVisibility`

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
- Accepts `FeedServiceProtocol` via `init(feedService:)` for testable dependency injection (defaults to `FeedService()`)
- `func loadConfig()` - decode feeds.json, build flat `allFeeds` list and hierarchical `menuItems` for grouped navigation
- `func selectFeed(_ feed: RssFeedModel) async` - set selected, set `isLoading`, call `fetchFeed`, update `feedItems`
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

**On-Device AI Summary (Planned)**

- Model: `smollm2:1.7b-instruct-q4_K_M` — a 1.7B parameter instruction-tuned SLM, quantized to Q4_K_M for efficient on-device inference
- Runtime: Ollama / llama.cpp integration for local summarisation of article content
- Goal: Generate article summaries entirely on-device with no network dependency

**9. Building & Running**

**iOS (Simulator)**

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

   # Via CLI: build and deploy
   xcodebuild -project Feeds.xcodeproj -scheme Feeds \
     -destination 'platform=iOS Simulator,name=iPhone 17' \
     build

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
     build

   # Find your device UDID:
   xcrun xctrace list devices
   ```

4. **Wireless debugging** (iOS 14+): In Xcode → Window → Devices and Simulators → select your device → check "Connect via network". After initial USB pairing, deploy wirelessly.

5. **Limitations (free Apple Developer account)**:
   - Apps expire after 7 days - reinstall to refresh
   - Limited to 3 apps installed via free provisioning at a time
   - No App Store distribution, push notifications, or some entitlements
   - Paid account ($99/year) removes these limits and enables App Store publishing

**Android (Emulator)**

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
- For a full `.apk` app: use [swift-java](https://github.com/swiftlang/swift-java) to build Swift as a shared library, embed in a Kotlin/Java Android app, and deploy with Gradle
- See [swift-android-examples](https://github.com/swiftlang/swift-android-examples) for complete app packaging templates

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
    -resultBundlePath TestResults.xcresult
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

**12. Android App Packaging (Beyond CLI)**

- The Swift SDK for Android compiles Swift to native Android binaries, but full apps need a Kotlin/Java app shell
- Use [swift-java](https://github.com/swiftlang/swift-java) to generate JNI bindings so Kotlin calls Swift functions
- Build Swift modules as `.so` shared libraries, bundle into the Android app's `jniLibs/` directory
- The Kotlin shell handles Android-specific UI (Jetpack Compose) while Swift handles shared business logic (models, services, networking, XML parsing)
- See [swift-android-examples](https://github.com/swiftlang/swift-android-examples) for full working projects

**13. Resources**

- [Swift SDK for Android - Getting Started](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html)
- [swift-java interoperability library](https://github.com/swiftlang/swift-java)
- [swift-android-examples](https://github.com/swiftlang/swift-android-examples)
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
