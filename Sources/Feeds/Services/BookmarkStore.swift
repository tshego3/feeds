import Foundation

/// Protocol defining async CRUD operations for bookmark persistence.
protocol BookmarkStore: Sendable {
    func fetchAll() async throws -> [SavedArticle]
    func insert(_ article: SavedArticle) async throws
    func delete(byID id: UUID) async throws
    func delete(byLink link: String) async throws
    func contains(link: String) async throws -> Bool
}
