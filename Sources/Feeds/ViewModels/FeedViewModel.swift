// FeedViewModel.swift — The ViewModel: holds state and business logic for the feed screen.
//
// C# parallel: a ViewModel class implementing INotifyPropertyChanged (like in MVVM Toolkit).
// SwiftUI uses @Published properties + ObservableObject instead of OnPropertyChanged().
// "@Published" ≈ C# [ObservableProperty] from CommunityToolkit.Mvvm — auto-notifies the UI.

import Foundation
#if canImport(os)
import os
private let logger = Logger(subsystem: "co.za.eoitech.feeds", category: "FeedViewModel")
#endif

// "@MainActor" ensures all property updates happen on the main/UI thread.
// C#: like wrapping every setter in Dispatcher.Invoke() or MainThread.BeginInvokeOnMainThread().
// Swift enforces thread safety at compile time — C# doesn't (you get runtime crashes instead).
@MainActor
class FeedViewModel: ObservableObject {

    private let feedService: FeedServiceProtocol
    private var autoRefreshTask: Task<Void, Never>?
    private static let refreshInterval: TimeInterval = 900 // 15 minutes

    @Published private(set) var feedItems: [FeedItem] = []
    @Published private(set) var allFeeds: [RssFeedModel] = []
    @Published private(set) var menuItems: [FeedMenuItem] = []
    @Published var selectedFeedId: String?
    @Published private(set) var selectedFeed: RssFeedModel?
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var readArticleLinks: Set<String> = []
    @Published var newArticlesBanner: String?

    init(feedService: FeedServiceProtocol = FeedService()) {
        self.feedService = feedService
    }

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

    /// Loads feed subscriptions from SQLite (seeds defaults on first launch).
    /// C#: public void LoadConfig() { var records = feedStore.GetAll(); ... }
    func loadConfig() {
        do {
            let store = try SQLiteFeedStore()

            // Seed defaults on first launch — C#: if (!db.Feeds.Any()) db.SeedDefaults();
            if store.isEmpty() {
                try store.seedDefaults(DefaultFeeds.all)
            }

            let records = try store.fetchAll()
            var feeds: [RssFeedModel] = []
            var items: [FeedMenuItem] = []

            // Group records by groupId — C#: records.GroupBy(r => r.GroupId)
            var groupedFeeds: [(groupId: String, groupTitle: String, feeds: [RssFeedModel])] = []
            var seenGroups: [String: Int] = [:] // groupId → index in groupedFeeds

            for record in records {
                let feed = RssFeedModel(
                    id: "\(record.id)",
                    title: record.title,
                    url: record.url,
                    suppressHeroImage: record.suppressHeroImage
                )
                feeds.append(feed)

                if let groupId = record.groupId, let groupTitle = record.groupTitle {
                    if let idx = seenGroups[groupId] {
                        groupedFeeds[idx].feeds.append(feed)
                    } else {
                        seenGroups[groupId] = groupedFeeds.count
                        groupedFeeds.append((groupId: groupId, groupTitle: groupTitle, feeds: [feed]))
                    }
                } else {
                    items.append(.single(feed))
                }
            }

            // Append groups after singles (preserving sortOrder from DB)
            for group in groupedFeeds {
                items.append(.group(id: "group-\(group.groupId)", title: group.groupTitle, feeds: group.feeds))
            }

            allFeeds = feeds
            menuItems = items
        } catch {
            errorMessage = "Unable to load feed subscriptions. Please try again."
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
            feedItems = try await feedService.fetchFeed(url: feed.url)
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

    /// Silent refresh for pull-to-refresh — does not show loading spinner.
    func refreshFeed() async {
        guard let feed = selectedFeed else { return }
        do {
            feedItems = try await feedService.fetchFeed(url: feed.url)
            errorMessage = nil
        } catch {
            // Keep existing content on refresh failure
        }
    }

    // MARK: - Explore / Discover

    var discoverFeeds: [DiscoverFeed] {
        menuItems.flatMap { item -> [DiscoverFeed] in
            switch item {
            case .single(let feed):
                return [DiscoverFeed(id: feed.id, name: feed.title, category: "General")]
            case .group(_, let title, let feeds):
                return feeds.map { DiscoverFeed(id: $0.id, name: $0.title, category: title) }
            }
        }
    }

    func filteredDiscoverFeeds(query: String) -> [DiscoverFeed] {
        guard !query.isEmpty else { return discoverFeeds }
        let lower = query.lowercased()
        return discoverFeeds.filter {
            $0.name.lowercased().contains(lower) || $0.category.lowercased().contains(lower)
        }
    }

    func groupedDiscoverFeeds(query: String) -> [(String, [DiscoverFeed])] {
        let feeds = filteredDiscoverFeeds(query: query)
        var seen: [String] = []
        var grouped: [String: [DiscoverFeed]] = [:]
        for feed in feeds {
            if !seen.contains(feed.category) { seen.append(feed.category) }
            grouped[feed.category, default: []].append(feed)
        }
        return seen.compactMap { key in grouped[key].map { (key, $0) } }
    }

    var feedCategories: [String] {
        menuItems.compactMap { item -> String? in
            guard case .group(_, let title, _) = item else { return nil }
            return title
        }
    }

    // MARK: - OPML Export

    func generateOPML() -> String {
        var lines = [
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <opml version="2.0">
            <head><title>feeds export</title></head>
            <body>
            """
        ]
        for item in menuItems {
            switch item {
            case .single(let feed):
                lines.append("  <outline text=\"\(Helpers.escapeXML(feed.title))\" xmlUrl=\"\(Helpers.escapeXML(feed.url))\" type=\"rss\"/>")
            case .group(_, let title, let feeds):
                lines.append("  <outline text=\"\(Helpers.escapeXML(title))\">")
                for feed in feeds {
                    lines.append("    <outline text=\"\(Helpers.escapeXML(feed.title))\" xmlUrl=\"\(Helpers.escapeXML(feed.url))\" type=\"rss\"/>")
                }
                lines.append("  </outline>")
            }
        }
        lines.append("</body>\n</opml>")
        return lines.joined(separator: "\n")
    }

    // MARK: - Auto Refresh

    func startAutoRefresh() {
        stopAutoRefresh()
        autoRefreshTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                try? await Task.sleep(for: .seconds(Self.refreshInterval))
                guard !Task.isCancelled else { return }
                await self.refreshCurrentFeed()
            }
        }
    }

    func dismissBanner() {
        newArticlesBanner = nil
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }

    private func refreshCurrentFeed() async {
        guard let feed = selectedFeed else { return }
        let previousLinks = Set(feedItems.map(\.link))

        do {
            let newItems = try await feedService.fetchFeed(url: feed.url)
            let newLinks = Set(newItems.map(\.link))
            let addedCount = newLinks.subtracting(previousLinks).count

            feedItems = newItems

            if addedCount > 0 {
                newArticlesBanner = "\(addedCount) new \(addedCount == 1 ? "article" : "articles") in \(feed.title)"
            }
        } catch {
            // Silent failure on background refresh — don't overwrite existing content with an error
        }
    }

    // MARK: - Feed Management

    /// Adds a new feed subscription to the SQLite store and reloads config.
    /// C#: public void AddFeed(string title, string url, string? groupTitle, bool suppressHeroImage)
    func addFeed(title: String, url: String, groupTitle: String?, suppressHeroImage: Bool) {
        do {
            let store = try SQLiteFeedStore()
            let maxSort = allFeeds.count * 10
            let groupId = groupTitle.map { $0.lowercased().replacingOccurrences(of: " ", with: "-") }
            let record = FeedRecord(
                id: 0,
                title: title,
                url: url,
                groupId: groupId,
                groupTitle: groupTitle,
                sortOrder: maxSort,
                suppressHeroImage: suppressHeroImage
            )
            try store.insert(record)
            loadConfig()
        } catch {
            errorMessage = "Failed to add feed. Please try again."
        }
    }

    /// Deletes a feed subscription from the SQLite store and reloads config.
    /// C#: public void DeleteFeed(RssFeedModel feed)
    func deleteFeed(_ feed: RssFeedModel) {
        guard let feedID = Int(feed.id) else { return }
        do {
            let store = try SQLiteFeedStore()
            try store.delete(byID: feedID)
            loadConfig()
            // Clear selection if deleted feed was active
            if selectedFeedId == feed.id {
                selectedFeedId = nil
                selectedFeed = nil
                feedItems = []
            }
        } catch {
            errorMessage = "Failed to remove feed. Please try again."
        }
    }

    /// Toggles the suppressHeroImage flag for a feed and reloads config.
    /// C#: public void ToggleSuppressHeroImage(RssFeedModel feed)
    func toggleSuppressHeroImage(_ feed: RssFeedModel) {
        guard let feedID = Int(feed.id) else { return }
        do {
            let store = try SQLiteFeedStore()
            try store.updateSuppressHeroImage(feedID: feedID, value: !feed.suppressHeroImage)
            loadConfig()
        } catch {
            errorMessage = "Failed to update feed setting."
        }
    }
}
