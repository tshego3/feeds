import Foundation

/// In-memory bookmark store shared across the app.
/// Uses @MainActor to ensure thread-safe UI updates.
// TODO: Explore using SQLite (e.g. swift-sqlite or GRDB) to persist saved articles across app launches.
//       Current in-memory store loses all bookmarks on restart. Migration path:
//       1. Add SQLite dependency to Package.swift
//       2. Create a `BookmarkStore` protocol with async CRUD methods
//       3. Implement `SQLiteBookmarkStore` conforming to that protocol
//       4. Replace in-memory array with SQLite-backed queries
//       5. Add migration support for schema changes
@MainActor
final class BookmarkViewModel: ObservableObject {

    @Published private(set) var savedArticles: [SavedArticle] = []

    init() {}

    var hasSavedArticles: Bool { !savedArticles.isEmpty }

    func isBookmarked(_ item: FeedItem) -> Bool {
        savedArticles.contains { $0.link == item.link }
    }

    func toggle(_ item: FeedItem, source: String = "Feed") {
        if let index = savedArticles.firstIndex(where: { $0.link == item.link }) {
            savedArticles.remove(at: index)
        } else {
            let saved = SavedArticle(
                title: item.title,
                source: source,
                description: item.description,
                link: item.link,
                tag: "readlater",
                readingTime: "",
                imageURL: item.displayImage
            )
            savedArticles.insert(saved, at: 0)
        }
    }

    func remove(_ article: SavedArticle) {
        savedArticles.removeAll { $0.id == article.id }
    }

    func articles(for tag: String) -> [SavedArticle] {
        guard tag != "#all" else { return savedArticles }
        let cleaned = String(tag.dropFirst())
        return savedArticles.filter { $0.tag == cleaned }
    }
}
