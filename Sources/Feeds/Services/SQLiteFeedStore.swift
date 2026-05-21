// SQLiteFeedStore.swift — Persistent feed subscription store using SQLite + SQLCipher.
//
// C#: Like an EF Core DbContext with a Feeds DbSet<FeedEntity>.
// Replaces the static feeds.json bundle — allows dynamic add/remove without app rebuild.

import Foundation
import SkipSQLPlus

/// Errors specific to feed store operations.
/// C#: public enum FeedStoreError : Exception { ... }
enum FeedStoreError: Error {
    case databaseError(String)
    case feedNotFound
}

/// SQLite-backed feed subscription store with encryption.
/// C#: public sealed class SqliteFeedStore : IFeedStore
final class SQLiteFeedStore: @unchecked Sendable {

    private let db: SQLContext

    init(databasePath: String? = nil) throws {
        let path = try databasePath ?? SQLiteFeedStore.defaultDatabasePath()
        db = try SQLContext(path: path, flags: [.create, .readWrite], configuration: .plus)

        // C#: using var connection = new SqliteConnection(connectionString); connection.Open();
        let key = try BookmarkKeyManager.loadOrCreateKey()
        try db.exec(sql: "PRAGMA key = '\(key)'")

        try migrateSchema()
    }

    // MARK: - Public API

    /// Loads all feed subscriptions, ordered by sortOrder.
    /// C#: public async Task<List<FeedRecord>> GetAllAsync()
    func fetchAll() throws -> [FeedRecord] {
        let rows = try db.selectAll(
            sql: """
                SELECT id, title, url, groupId, groupTitle, sortOrder, suppressHeroImage
                FROM feed_subscription
                ORDER BY sortOrder ASC
                """
        )
        return rows.compactMap { row in
            guard let idVal = Self.intValue(row[safe: 0]),
                  let title = Self.textValue(row[safe: 1]),
                  let url = Self.textValue(row[safe: 2])
            else { return nil }

            let groupId = Self.textValue(row[safe: 3])
            let groupTitle = Self.textValue(row[safe: 4])
            let sortOrder = Self.intValue(row[safe: 5]) ?? 0
            let suppressHeroImage = (Self.intValue(row[safe: 6]) ?? 0) != 0

            return FeedRecord(
                id: idVal,
                title: title,
                url: url,
                groupId: groupId,
                groupTitle: groupTitle,
                sortOrder: sortOrder,
                suppressHeroImage: suppressHeroImage
            )
        }
    }

    /// Inserts a new feed subscription.
    /// C#: public async Task AddAsync(FeedRecord record)
    func insert(_ record: FeedRecord) throws {
        try db.exec(
            sql: """
                INSERT INTO feed_subscription (title, url, groupId, groupTitle, sortOrder, suppressHeroImage)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
            parameters: [
                .text(record.title),
                .text(record.url),
                record.groupId.map { .text($0) } ?? .null,
                record.groupTitle.map { .text($0) } ?? .null,
                .long(Int64(record.sortOrder)),
                .long(record.suppressHeroImage ? 1 : 0)
            ]
        )
    }

    /// Deletes a feed subscription by its database ID.
    /// C#: public async Task DeleteAsync(int id)
    func delete(byID id: Int) throws {
        try db.exec(sql: "DELETE FROM feed_subscription WHERE id = ?", parameters: [.long(Int64(id))])
    }

    /// Updates the suppressHeroImage flag for a specific feed.
    /// C#: public void UpdateSuppressHeroImage(int feedId, bool value)
    func updateSuppressHeroImage(feedID: Int, value: Bool) throws {
        try db.exec(
            sql: "UPDATE feed_subscription SET suppressHeroImage = ? WHERE id = ?",
            parameters: [.long(value ? 1 : 0), .long(Int64(feedID))]
        )
    }

    /// Checks if hero image should be suppressed for a given feed ID.
    /// C#: public bool ShouldSuppressHeroImage(int feedId)
    func shouldSuppressHeroImage(feedID: Int) -> Bool {
        guard let rows = try? db.selectAll(
            sql: "SELECT suppressHeroImage FROM feed_subscription WHERE id = ? LIMIT 1",
            parameters: [.long(Int64(feedID))]
        ), let row = rows.first else { return false }

        return (Self.intValue(row[safe: 0]) ?? 0) != 0
    }

    /// Returns the set of feed IDs that suppress hero images.
    /// C#: public HashSet<int> GetHeroImageSuppressedIds()
    func heroImageSuppressedIDs() -> Set<Int> {
        guard let rows = try? db.selectAll(
            sql: "SELECT id FROM feed_subscription WHERE suppressHeroImage = 1"
        ) else { return [] }

        var ids: Set<Int> = []
        for row in rows {
            if let val = Self.intValue(row[safe: 0]) { ids.insert(val) }
        }
        return ids
    }

    /// Checks if any feed subscriptions exist.
    /// C#: public bool HasSubscriptions()
    func isEmpty() -> Bool {
        guard let rows = try? db.selectAll(sql: "SELECT COUNT(*) FROM feed_subscription"),
              let row = rows.first,
              let count = Self.intValue(row[safe: 0]) else { return true }
        return count == 0
    }

    // MARK: - Schema Migration

    private func migrateSchema() throws {
        if db.userVersion < 1 {
            try db.transaction {
                try db.exec(sql: """
                    CREATE TABLE IF NOT EXISTS feed_subscription (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        title TEXT NOT NULL,
                        url TEXT NOT NULL,
                        groupId TEXT,
                        groupTitle TEXT,
                        sortOrder INTEGER NOT NULL DEFAULT 0,
                        suppressHeroImage INTEGER NOT NULL DEFAULT 0
                    )
                    """)
                try db.exec(sql: "CREATE INDEX IF NOT EXISTS idx_feed_sort ON feed_subscription(sortOrder)")
                db.userVersion = 1
            }
        }
        // Future: if db.userVersion < 2 { ... ALTER TABLE ...; db.userVersion = 2 }
    }

    // MARK: - Seed Default Feeds

    /// Seeds the database with default feeds on first launch.
    /// C#: public void SeedDefaults(List<FeedRecord> defaults)
    func seedDefaults(_ records: [FeedRecord]) throws {
        try db.transaction {
            for record in records {
                try db.exec(
                    sql: """
                        INSERT INTO feed_subscription (title, url, groupId, groupTitle, sortOrder, suppressHeroImage)
                        VALUES (?, ?, ?, ?, ?, ?)
                        """,
                    parameters: [
                        .text(record.title),
                        .text(record.url),
                        record.groupId.map { .text($0) } ?? .null,
                        record.groupTitle.map { .text($0) } ?? .null,
                        .long(Int64(record.sortOrder)),
                        .long(record.suppressHeroImage ? 1 : 0)
                    ]
                )
            }
        }
    }

    // MARK: - Default Path

    private static func defaultDatabasePath() throws -> String {
        #if os(Android) || os(Linux)
        let base = ProcessInfo.processInfo.environment["HOME"] ?? "/tmp"
        let dir = URL(fileURLWithPath: base).appendingPathComponent(".feeds", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("feeds.sqlite").path
        #else
        let url = try FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Feeds", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url.appendingPathComponent("feeds.sqlite").path
        #endif
    }

    // MARK: - SQLValue Helpers

    /// Extracts a String from an optional SQLValue, returns nil if not .text.
    private static func textValue(_ value: SQLValue?) -> String? {
        guard let value else { return nil }
        switch value {
        case .text(let val): return val
        default: return nil
        }
    }

    /// Extracts an Int from an optional SQLValue, returns nil if not .long/.integer.
    private static func intValue(_ value: SQLValue?) -> Int? {
        guard let value else { return nil }
        switch value {
        case .long(let val): return Int(val)
        default: return nil
        }
    }
}

// MARK: - Safe array subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
