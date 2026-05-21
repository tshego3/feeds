// FeedRecord.swift — Database model for a feed subscription row.
//
// C#: public record FeedRecord — a flat DTO representing one row in feed_subscription table.
// Maps to RssFeedModel at runtime (the UI-facing model).

import Foundation

/// One row from the feed_subscription SQLite table.
/// C#: public record FeedRecord(int Id, string Title, string Url, string? GroupId, string? GroupTitle, int SortOrder, bool SuppressHeroImage);
struct FeedRecord: Identifiable, Equatable {
    let id: Int
    let title: String
    let url: String
    let groupId: String?       // Groups feeds under a collapsible menu section
    let groupTitle: String?    // Display name for the group (e.g. "Sports", "Tech")
    let sortOrder: Int         // Controls display order in navigation
    let suppressHeroImage: Bool // If true, article reader skips hero image (content already has images)
}
