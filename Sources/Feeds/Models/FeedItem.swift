// FeedItem.swift — Represents a single parsed RSS article.
//
// C# parallel: a POCO / record that holds one RSS <item> element's data.
// UUID in Swift = Guid in C# — auto-generated unique identifier.

import Foundation

/// One article parsed from an RSS feed.
/// C#: public record FeedItem(Guid Id, string Title, string Link, string Description, string PubDate, List<string?> ImageURLs);
struct FeedItem: Identifiable, Equatable {
    // "UUID()" auto-generates — like "Guid.NewGuid()" in C#.
    let id = UUID()
    let title: String
    let link: String
    let description: String
    let pubDate: String
    let imageURLs: [String?]    // Array of nullable strings — C#: List<string?>

    // Computed property — C#: public Uri? DisplayImage => ...
    // "var" for computed props (must be mutable syntax even though it's read-only).
    // "URL" in Swift = "Uri" in C#.
    var displayImage: URL? {
        // "compactMap" removes nils from a sequence — C#: .Where(x => x != null).Select(x => x!)
        // ".first" = C# .FirstOrDefault()
        // "URL(string:)" = new Uri(string) — returns nil if invalid (C# would throw).
        imageURLs.compactMap { $0 }.compactMap { URL(string: $0) }.first
    }
}
