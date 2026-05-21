// FeedItem.swift — Represents a single parsed RSS article.
//
// C# parallel: a POCO / record that holds one RSS <item> element's data.
// UUID in Swift = Guid in C# — auto-generated unique identifier.

import Foundation

/// One article parsed from an RSS feed.
/// C#: public record FeedItem(Guid Id, string Title, string Link, string Description, string PubDate, List<string?> ImageURLs);
struct FeedItem: Identifiable, Equatable, Hashable {
    // Hashable via id only — Array<String?> doesn't auto-synthesize Hashable.
    // C#: override int GetHashCode() => Id.GetHashCode();
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    // "UUID()" auto-generates — like "Guid.NewGuid()" in C#.
    let id: UUID
    let title: String
    let link: String
    let description: String
    let pubDate: String
    let imageURLs: [String?]    // Array of nullable strings — C#: List<string?>
    let feedThumbnailURL: String?  // Channel-level image URL as fallback

    init(title: String, link: String, description: String, pubDate: String, imageURLs: [String?], feedThumbnailURL: String? = nil) {
        self.id = UUID()
        self.title = title
        self.link = link
        self.description = description
        self.pubDate = pubDate
        self.imageURLs = imageURLs
        self.feedThumbnailURL = feedThumbnailURL
    }

    // Computed property — C#: public Uri? DisplayImage => ...
    var displayImage: URL? {
        imageURLs.compactMap { $0 }.compactMap { URL(string: $0) }.first
    }

    var thumbnailImage: URL? {
        guard let urlString = feedThumbnailURL else { return nil }
        return URL(string: urlString)
    }

    /// Plain-text version of description with HTML tags stripped. Safe for card previews.
    var plainDescription: String {
        Helpers.stripHTML(description)
    }
}
