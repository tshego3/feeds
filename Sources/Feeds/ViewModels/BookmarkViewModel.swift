import Foundation

/// Persistent bookmark store backed by encrypted SQLite.
/// Uses @MainActor to ensure thread-safe UI updates.
@MainActor
final class BookmarkViewModel: ObservableObject {

    @Published private(set) var savedArticles: [SavedArticle] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let store: BookmarkStore

    init(store: BookmarkStore? = nil) {
        if let store {
            self.store = store
        } else {
            do {
                self.store = try SQLiteBookmarkStore()
            } catch {
                // Fallback: this should not happen in normal operation.
                // If it does, the app will function without persistence.
                fatalError("Failed to initialize bookmark database: \(error)")
            }
        }
    }

    var hasSavedArticles: Bool { !savedArticles.isEmpty }

    func loadBookmarks() async {
        isLoading = true
        defer { isLoading = false }
        do {
            savedArticles = try await store.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load saved articles."
        }
    }

    func isBookmarked(_ item: FeedItem) -> Bool {
        savedArticles.contains { $0.link == item.link }
    }

    func toggle(_ item: FeedItem, source: String = "Feed") {
        if let index = savedArticles.firstIndex(where: { $0.link == item.link }) {
            let article = savedArticles[index]
            savedArticles.remove(at: index)
            Task {
                do {
                    try await store.delete(byID: article.id)
                } catch {
                    savedArticles.insert(article, at: index)
                    errorMessage = "Failed to remove bookmark."
                }
            }
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
            Task {
                do {
                    try await store.insert(saved)
                } catch {
                    savedArticles.removeAll { $0.id == saved.id }
                    errorMessage = "Failed to save bookmark."
                }
            }
        }
    }

    func remove(_ article: SavedArticle) {
        savedArticles.removeAll { $0.id == article.id }
        Task {
            do {
                try await store.delete(byID: article.id)
            } catch {
                errorMessage = "Failed to remove bookmark."
                await loadBookmarks()
            }
        }
    }

    func articles(for tag: String) -> [SavedArticle] {
        guard tag != "#all" else { return savedArticles }
        let cleaned = String(tag.dropFirst())
        return savedArticles.filter { $0.tag == cleaned }
    }
}
