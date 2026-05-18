import Foundation
#if canImport(Security)
import Security
#endif

/// Cross-platform key manager for SQLCipher database encryption.
/// Generates and securely stores a 256-bit hex passphrase.
/// On Apple: stored in Keychain.
/// On Android/Linux: stored in a protected file (0600 permissions).
enum BookmarkKeyManager: Sendable {

    /// Loads or creates the SQLCipher passphrase (64-char hex string).
    static func loadOrCreateKey() throws -> String {
        #if canImport(Security)
        return try loadOrCreateKeyFromKeychain()
        #else
        return try loadOrCreateKeyFromFile()
        #endif
    }

    // MARK: - Apple Keychain

    #if canImport(Security)
    private static let keychainService = "com.feeds.bookmark-db"
    private static let keychainAccount = "sqlcipher-key"

    private static func loadOrCreateKeyFromKeychain() throws -> String {
        if let existing = try loadKeyFromKeychain() {
            return existing
        }
        let key = generateHexKey()
        try saveKeyToKeychain(key)
        return key
    }

    private static func loadKeyFromKeychain() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
                throw BookmarkKeyError.keyLoadFailed
            }
            return key
        case errSecItemNotFound:
            return nil
        default:
            throw BookmarkKeyError.keyLoadFailed
        }
    }

    private static func saveKeyToKeychain(_ key: String) throws {
        guard let keyData = key.data(using: .utf8) else {
            throw BookmarkKeyError.keySaveFailed
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BookmarkKeyError.keySaveFailed
        }
    }
    #endif

    // MARK: - File-based key (Android/Linux)

    #if !canImport(Security)
    private static func loadOrCreateKeyFromFile() throws -> String {
        let keyPath = try keyFilePath()

        if FileManager.default.fileExists(atPath: keyPath) {
            let data = try Data(contentsOf: URL(fileURLWithPath: keyPath))
            guard let key = String(data: data, encoding: .utf8), key.count == 64 else {
                throw BookmarkKeyError.keyLoadFailed
            }
            return key
        }

        let key = generateHexKey()
        let dir = URL(fileURLWithPath: keyPath).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try key.data(using: .utf8)?.write(to: URL(fileURLWithPath: keyPath), options: [.atomic])

        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: keyPath
        )

        return key
    }

    private static func keyFilePath() throws -> String {
        let base = ProcessInfo.processInfo.environment["HOME"] ?? "/tmp"
        return URL(fileURLWithPath: base)
            .appendingPathComponent(".feeds")
            .appendingPathComponent(".bookmark_key")
            .path
    }
    #endif

    // MARK: - Key Generation

    private static func generateHexKey() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        #if canImport(Security)
        _ = SecRandomCopyBytes(kSecRandomDefault, 32, &bytes)
        #else
        // /dev/urandom fallback for Android/Linux
        if let fd = fopen("/dev/urandom", "r") {
            _ = fread(&bytes, 1, 32, fd)
            fclose(fd)
        }
        #endif
        return bytes.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Errors

enum BookmarkKeyError: Error {
    case keyLoadFailed
    case keySaveFailed
}
