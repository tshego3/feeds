import Foundation

/// In-memory bookmark store for testing and fallback scenarios.
final class InMemoryBookmarkStore: BookmarkStore, @unchecked Sendable {

    private var articles: [SavedArticle] = []

    func fetchAll() async throws -> [SavedArticle] {
        articles.sorted { $0.savedDate > $1.savedDate }
    }

    func insert(_ article: SavedArticle) async throws {
        articles.removeAll { $0.link == article.link }
        articles.append(article)
    }

    func delete(byID id: UUID) async throws {
        articles.removeAll { $0.id == id }
    }

    func delete(byLink link: String) async throws {
        articles.removeAll { $0.link == link }
    }

    func contains(link: String) async throws -> Bool {
        articles.contains { $0.link == link }
    }
}
