// RssFeedModel.swift — Feed configuration models, decoded from feeds.json.
//
// C# parallel: these are DTOs / record types you'd deserialize from JSON with System.Text.Json.
// Swift "struct" = C# "struct" (value type), but Swift structs are used far more often than C# structs.
// Swift "Codable" protocol ≈ C# [JsonSerializable] or implementing IJsonOnDeserialized — auto JSON support.
// Swift "Identifiable" protocol ≈ C# "IIdentifiable<T>" — requires an "id" property.

import Foundation

// MARK: - JSON Config Shapes
// "MARK" comments create section headers in Xcode/VS Code — like #region in C#.

/// The top-level array element from feeds.json.
/// C#: public record FeedConfig(double Id, string Title, string? Url, List<FeedCategory>? Categories);
struct FeedConfig: Codable, Identifiable {
    // "let" = readonly field. Swift infers types, but you can annotate: "let id: Double".
    let id: Double          // C#: public double Id { get; init; }
    let title: String       // C#: public string Title { get; init; }
    let url: String?        // "String?" = nullable — same syntax as C# nullable reference types
    let categories: [FeedCategory]?  // "[T]" = Array<T> or List<T> in C#
}

/// A sub-category within a feed config.
/// C#: public record FeedCategory(double Id, string Title, string Url);
struct FeedCategory: Codable, Identifiable {
    let id: Double
    let title: String
    let url: String
}

// MARK: - Runtime Models

/// Flattened model used at runtime (after resolving categories).
/// C#: public class RssFeedModel { public string Id { get; set; } ... }
struct RssFeedModel: Identifiable, Equatable {
    let id: String          // Using String id for Identifiable conformance
    let title: String
    let url: String
}

/// Represents a menu entry — either a single feed or a group with sub-feeds.
/// C#: like a discriminated union — single item vs. dropdown with children.
enum FeedMenuItem: Identifiable {
    case single(RssFeedModel)
    case group(id: String, title: String, feeds: [RssFeedModel])

    var id: String {
        switch self {
        case .single(let feed): return feed.id
        case .group(let id, _, _): return id
        }
    }
}
