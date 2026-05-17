// FeedViewModel.swift — The ViewModel: holds state and business logic for the feed screen.
//
// C# parallel: a ViewModel class implementing INotifyPropertyChanged (like in MVVM Toolkit).
// SwiftUI uses @Published properties + ObservableObject instead of OnPropertyChanged().
// "@Published" ≈ C# [ObservableProperty] from CommunityToolkit.Mvvm — auto-notifies the UI.

import Foundation

// "@MainActor" ensures all property updates happen on the main/UI thread.
// C#: like wrapping every setter in Dispatcher.Invoke() or MainThread.BeginInvokeOnMainThread().
// Swift enforces thread safety at compile time — C# doesn't (you get runtime crashes instead).
@MainActor
class FeedViewModel: ObservableObject {
    // "ObservableObject" protocol ≈ C# INotifyPropertyChanged.
    // "@Published" ≈ C# [ObservableProperty] — auto-fires change notifications.
    // When any @Published var changes, all observing Views re-render automatically.

    @Published private(set) var feedItems: [FeedItem] = []        // C#: ObservableCollection<FeedItem>
    @Published private(set) var allFeeds: [RssFeedModel] = []     // C#: ObservableCollection<RssFeedModel>
    @Published private(set) var menuItems: [FeedMenuItem] = []    // Hierarchical menu structure
    @Published var selectedFeedId: String?                        // Drives List selection → NavigationSplitView navigation
    @Published private(set) var selectedFeed: RssFeedModel?       // C#: RssFeedModel? SelectedFeed { get; set; }
    @Published private(set) var errorMessage: String?             // C#: string? ErrorMessage { get; set; }
    @Published private(set) var isLoading: Bool = false            // C#: bool IsLoading { get; set; }
    @Published private(set) var readArticleLinks: Set<String> = [] // C#: HashSet<string> — tracks read article links

    /// Whether any feed items are available to display.
    var hasItems: Bool { !feedItems.isEmpty }

    /// Articles not yet marked as read. C#: feedItems.Where(x => !readArticleLinks.Contains(x.Link)).ToList()
    var unreadItems: [FeedItem] {
        feedItems.filter { !readArticleLinks.contains($0.link) }
    }

    /// Marks an article as read by its link. C#: public void MarkAsRead(FeedItem item) { readArticleLinks.Add(item.Link); }
    func markAsRead(_ item: FeedItem) {
        readArticleLinks.insert(item.link)
    }

    // MARK: - Load Config

    /// Reads feeds.json from the app bundle and flattens categories into allFeeds.
    /// C#: public void LoadConfig() { var json = File.ReadAllText("feeds.json"); ... }
    func loadConfig() {
        // "Bundle.main" = the app's resource bundle. C#: Assembly.GetExecutingAssembly() or AppContext.BaseDirectory.
        // "guard let url = Bundle.main.url(...) else { return }" — safe unwrap + early exit.
        // C#: if (!File.Exists(path)) return;
        guard let url = Bundle.main.url(forResource: "feeds", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            errorMessage = "Could not load feeds.json"
            return
        }

        // "do { try } catch { }" = C# "try { } catch (Exception ex) { }"
        do {
            // JSONDecoder ≈ C# JsonSerializer.Deserialize<T>()
            let configs = try JSONDecoder().decode([FeedConfig].self, from: data)
            var feeds: [RssFeedModel] = []
            var items: [FeedMenuItem] = []

            for config in configs {
                if let categories = config.categories {
                    // Build sub-feeds and group them into a menu item
                    var subFeeds: [RssFeedModel] = []
                    for cat in categories {
                        let feed = RssFeedModel(id: "\(config.id)-\(cat.id)", title: cat.title, url: cat.url)
                        subFeeds.append(feed)
                        feeds.append(feed)
                    }
                    items.append(.group(id: "\(config.id)", title: config.title, feeds: subFeeds))
                } else if let url = config.url {
                    let feed = RssFeedModel(id: "\(config.id)", title: config.title, url: url)
                    feeds.append(feed)
                    items.append(.single(feed))
                }
            }

            allFeeds = feeds
            menuItems = items
        } catch {
            // "error" is the implicit caught error — C#: catch (Exception ex) { /* ex */ }
            errorMessage = "Failed to parse feeds.json: \(error.localizedDescription)"
        }
    }

    // MARK: - Select Feed

    /// Fetches articles for the given feed. C#: public async Task SelectFeed(RssFeedModel feed) { }
    /// "async" = same as C# async. No "Task" return type needed — Swift infers it.
    func selectFeed(_ feed: RssFeedModel) async {
        selectedFeed = feed
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // "try await" = C# "await" (Swift requires explicit "try" for throwing async calls).
            feedItems = try await FeedService.fetchFeed(url: feed.url)
        } catch let feedError as FeedError {
            switch feedError {
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            case .parsingError:
                errorMessage = "Unable to read feed data."
            case .feedUnavailable(let status):
                errorMessage = "Feed unavailable (status \(status)). Please try again."
            }
            feedItems = []
        } catch is URLError {
            errorMessage = "Network error. Please check your connection."
            feedItems = []
        } catch {
            errorMessage = "Something went wrong. Please try again."
            feedItems = []
        }
    }
}
