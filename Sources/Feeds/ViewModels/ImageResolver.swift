import Foundation
import SwiftUI

/// Lazily resolves and caches Open Graph preview images for articles.
/// Fetches only when requested (when a card appears on screen).
/// C#: Similar to a MemoryCache<string, Uri> + background Task pattern
@MainActor
class ImageResolver: ObservableObject {

    private let openGraphService = OpenGraphService()
    // C#: Dictionary<string, Uri> — triggers UI update via @Published
    @Published private var cache: [String: URL] = [:]
    private var inFlight: Set<String> = []

    /// Returns cached OG image URL for the given article link, or nil if not yet resolved.
    /// C#: like TryGetValue on ConcurrentDictionary
    func cachedImage(for link: String) -> URL? {
        cache[link]
    }

    /// Resolves the OG image for an article link if not already cached or in-flight.
    /// C#: like Task.Run(() => FetchAndCache(link)) with deduplication
    func resolve(link: String) {
        guard cache[link] == nil, !inFlight.contains(link) else { return }
        inFlight.insert(link)
        Task {
            let url = await openGraphService.fetchOGImage(for: link)
            inFlight.remove(link)
            if let url {
                cache[link] = url
            }
        }
    }
}
