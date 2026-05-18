import Foundation
import SkipSQLPlus

/// SQLite-backed bookmark store with SQLCipher full-database encryption.
/// Works identically on iOS and Android via SkipSQL.
/// Key management: Keychain (Apple) or protected file (Android/Linux).
final class SQLiteBookmarkStore: BookmarkStore, @unchecked Sendable {

    private let db: SQLContext

    init(databasePath: String? = nil) throws {
        let path = try databasePath ?? SQLiteBookmarkStore.defaultDatabasePath()
        db = try SQLContext(path: path, flags: [.create, .readWrite], configuration: .plus)

        let key = try BookmarkKeyManager.loadOrCreateKey()
        try db.exec(sql: "PRAGMA key = '\(key)'")

        try migrateSchema()
    }

    // MARK: - BookmarkStore

    func fetchAll() async throws -> [SavedArticle] {
        let rows = try db.selectAll(
            sql: "SELECT id, title, source, description, link, savedDate, tag, readingTime, imageURL FROM bookmark ORDER BY savedDate DESC"
        )
        return rows.compactMap { row in
            guard case .text(let id) = row[safe: 0],
                  case .text(let title) = row[safe: 1],
                  case .text(let source) = row[safe: 2],
                  case .text(let desc) = row[safe: 3],
                  case .text(let link) = row[safe: 4],
                  case .real(let timestamp) = row[safe: 5],
                  case .text(let tag) = row[safe: 6],
                  case .text(let readingTime) = row[safe: 7]
            else { return nil }

            let imageURL: URL? = {
                if case .text(let urlString) = row[safe: 8] { return URL(string: urlString) }
                return nil
            }()

            return SavedArticle(
                id: UUID(uuidString: id) ?? UUID(),
                title: title,
                source: source,
                description: desc,
                link: link,
                savedDate: Date(timeIntervalSince1970: timestamp),
                tag: tag,
                readingTime: readingTime,
                imageURL: imageURL
            )
        }
    }

    func insert(_ article: SavedArticle) async throws {
        try db.exec(
            sql: """
                INSERT OR REPLACE INTO bookmark (id, title, source, description, link, savedDate, tag, readingTime, imageURL)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
            parameters: [
                .text(article.id.uuidString),
                .text(article.title),
                .text(article.source),
                .text(article.description),
                .text(article.link),
                .real(article.savedDate.timeIntervalSince1970),
                .text(article.tag),
                .text(article.readingTime),
                article.imageURL.map { .text($0.absoluteString) } ?? .null
            ]
        )
    }

    func delete(byID id: UUID) async throws {
        try db.exec(sql: "DELETE FROM bookmark WHERE id = ?", parameters: [.text(id.uuidString)])
    }

    func delete(byLink link: String) async throws {
        try db.exec(sql: "DELETE FROM bookmark WHERE link = ?", parameters: [.text(link)])
    }

    func contains(link: String) async throws -> Bool {
        let rows = try db.selectAll(
            sql: "SELECT 1 FROM bookmark WHERE link = ? LIMIT 1",
            parameters: [.text(link)]
        )
        return !rows.isEmpty
    }

    // MARK: - Schema Migration

    private func migrateSchema() throws {
        if db.userVersion < 1 {
            try db.transaction {
                try db.exec(sql: """
                    CREATE TABLE IF NOT EXISTS bookmark (
                        id TEXT PRIMARY KEY NOT NULL,
                        title TEXT NOT NULL,
                        source TEXT NOT NULL,
                        description TEXT NOT NULL DEFAULT '',
                        link TEXT NOT NULL,
                        savedDate REAL NOT NULL,
                        tag TEXT NOT NULL DEFAULT 'readlater',
                        readingTime TEXT NOT NULL DEFAULT '',
                        imageURL TEXT
                    )
                    """)
                try db.exec(sql: "CREATE UNIQUE INDEX IF NOT EXISTS idx_bookmark_link ON bookmark(link)")
                db.userVersion = 1
            }
        }
    }

    // MARK: - Default Path

    private static func defaultDatabasePath() throws -> String {
        #if os(Android) || os(Linux)
        let base = ProcessInfo.processInfo.environment["HOME"] ?? "/tmp"
        let dir = URL(fileURLWithPath: base).appendingPathComponent(".feeds", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("bookmarks.sqlite").path
        #else
        let url = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Feeds", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.appendingPathComponent("bookmarks.sqlite").path
        #endif
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
