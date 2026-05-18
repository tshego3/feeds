import Foundation
import GRDB
import Crypto

/// SQLite-backed bookmark store with AES-GCM encryption.
/// All bookmark content is encrypted before storage.
/// Lookups use SHA-256 hashes of links (non-reversible).
/// Key management: Keychain (Apple) or protected file (Android/Linux).
final class SQLiteBookmarkStore: BookmarkStore, @unchecked Sendable {

    private let dbQueue: DatabaseQueue
    private let encryption: BookmarkEncryptionService

    init(databasePath: String? = nil) throws {
        let path = try databasePath ?? SQLiteBookmarkStore.defaultDatabasePath()
        let key = try BookmarkEncryptionService.loadOrCreateKey()
        self.encryption = BookmarkEncryptionService(key: key)

        let config = Configuration()
        dbQueue = try DatabaseQueue(path: path, configuration: config)
        try applyFileProtection(at: path)
        try migrator.migrate(dbQueue)
    }

    // MARK: - BookmarkStore

    func fetchAll() async throws -> [SavedArticle] {
        try await dbQueue.read { [encryption] db in
            let rows = try EncryptedBookmarkRecord
                .order(EncryptedBookmarkRecord.Columns.savedDate.desc)
                .fetchAll(db)
            return try rows.compactMap { row in
                let data = try encryption.decrypt(row.encryptedData)
                return try JSONDecoder().decode(SavedArticlePayload.self, from: data).toSavedArticle()
            }
        }
    }

    func insert(_ article: SavedArticle) async throws {
        let payload = SavedArticlePayload(from: article)
        let plaintext = try JSONEncoder().encode(payload)
        let ciphertext = try encryption.encrypt(plaintext)
        let linkHash = SHA256.hash(data: Data(article.link.utf8)).hexString

        let record = EncryptedBookmarkRecord(
            id: article.id.uuidString,
            linkHash: linkHash,
            savedDate: article.savedDate,
            encryptedData: ciphertext
        )

        try await dbQueue.write { db in
            try record.insert(db)
        }
    }

    func delete(byID id: UUID) async throws {
        try await dbQueue.write { db in
            _ = try EncryptedBookmarkRecord
                .filter(EncryptedBookmarkRecord.Columns.id == id.uuidString)
                .deleteAll(db)
        }
    }

    func delete(byLink link: String) async throws {
        let linkHash = SHA256.hash(data: Data(link.utf8)).hexString
        try await dbQueue.write { db in
            _ = try EncryptedBookmarkRecord
                .filter(EncryptedBookmarkRecord.Columns.linkHash == linkHash)
                .deleteAll(db)
        }
    }

    func contains(link: String) async throws -> Bool {
        let linkHash = SHA256.hash(data: Data(link.utf8)).hexString
        return try await dbQueue.read { db in
            try EncryptedBookmarkRecord
                .filter(EncryptedBookmarkRecord.Columns.linkHash == linkHash)
                .fetchCount(db) > 0
        }
    }

    // MARK: - Database Migration

    private var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v2_encryptedBookmarks") { db in
            // Drop v1 table if it exists (unencrypted data)
            try db.execute(sql: "DROP TABLE IF EXISTS bookmark")

            try db.create(table: "encrypted_bookmark") { t in
                t.primaryKey("id", .text).notNull()
                t.column("linkHash", .text).notNull()
                t.column("savedDate", .datetime).notNull()
                t.column("encryptedData", .blob).notNull()
            }

            try db.create(
                index: "encrypted_bookmark_on_linkHash",
                on: "encrypted_bookmark",
                columns: ["linkHash"],
                unique: true
            )
        }

        return migrator
    }

    // MARK: - File Protection

    private func applyFileProtection(at path: String) throws {
        #if os(iOS)
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.complete
        ]
        try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
        #endif
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

// MARK: - Encrypted Database Record

private struct EncryptedBookmarkRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "encrypted_bookmark"

    let id: String
    let linkHash: String
    let savedDate: Date
    let encryptedData: Data

    enum Columns {
        static let id = Column("id")
        static let linkHash = Column("linkHash")
        static let savedDate = Column("savedDate")
        static let encryptedData = Column("encryptedData")
    }
}

// MARK: - Serializable Payload (encrypted at rest)

private struct SavedArticlePayload: Codable {
    let id: String
    let title: String
    let source: String
    let description: String
    let link: String
    let savedDate: Date
    let tag: String
    let readingTime: String
    let imageURL: String?

    init(from article: SavedArticle) {
        self.id = article.id.uuidString
        self.title = article.title
        self.source = article.source
        self.description = article.description
        self.link = article.link
        self.savedDate = article.savedDate
        self.tag = article.tag
        self.readingTime = article.readingTime
        self.imageURL = article.imageURL?.absoluteString
    }

    func toSavedArticle() -> SavedArticle {
        SavedArticle(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            source: source,
            description: description,
            link: link,
            savedDate: savedDate,
            tag: tag,
            readingTime: readingTime,
            imageURL: imageURL.flatMap { URL(string: $0) }
        )
    }
}

// MARK: - SHA256 Hex Helper

private extension SHA256Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
