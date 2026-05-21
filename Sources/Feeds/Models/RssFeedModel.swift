// RssFeedModel.swift — Runtime feed models used throughout the app.
//
// C# parallel: these are DTOs / record types for representing feed subscriptions at runtime.
// Swift "struct" = C# "struct" (value type), but Swift structs are used far more often than C# structs.
// Swift "Identifiable" protocol ≈ C# "IIdentifiable<T>" — requires an "id" property.

import Foundation

// MARK: - Runtime Models

/// Flattened model used at runtime (after resolving categories).
/// C#: public class RssFeedModel { public string Id { get; set; } ... }
struct RssFeedModel: Identifiable, Equatable {
    let id: String          // Using String id for Identifiable conformance
    let title: String
    let url: String
    let suppressHeroImage: Bool  // If true, article reader skips hero image (feed embeds images in HTML)

    init(id: String, title: String, url: String, suppressHeroImage: Bool = false) {
        self.id = id
        self.title = title
        self.url = url
        self.suppressHeroImage = suppressHeroImage
    }
}

/// Represents a menu entry — either a single feed or a group with sub-feeds.
/// C#: like a discriminated union — single item vs. dropdown with children.
enum FeedMenuItem: Identifiable, Equatable {
    case single(RssFeedModel)
    case group(id: String, title: String, feeds: [RssFeedModel])

    var id: String {
        switch self {
        case .single(let feed): return feed.id
        case .group(let id, _, _): return id
        }
    }
}
