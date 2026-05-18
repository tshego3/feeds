import Foundation
import Crypto
#if canImport(Security)
import Security
#endif

/// Cross-platform encryption service using AES-GCM (256-bit).
/// Works on iOS, macOS, and Android/Linux via swift-crypto.
struct BookmarkEncryptionService: Sendable {

    private let key: SymmetricKey

    init(key: SymmetricKey) {
        self.key = key
    }

    /// Encrypts data using AES-GCM. Returns combined nonce + ciphertext + tag.
    func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw BookmarkEncryptionError.encryptionFailed
        }
        return combined
    }

    /// Decrypts AES-GCM combined data (nonce + ciphertext + tag).
    func decrypt(_ combined: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(sealedBox, using: key)
    }

    // MARK: - Key Management

    /// Loads or creates an encryption key.
    /// On Apple: stored in Keychain.
    /// On Android/Linux: stored in a protected file.
    static func loadOrCreateKey() throws -> SymmetricKey {
        #if canImport(Security)
        return try loadOrCreateKeyFromKeychain()
        #else
        return try loadOrCreateKeyFromFile()
        #endif
    }

    // MARK: - Apple Keychain

    #if canImport(Security)
    private static let keychainService = "com.feeds.bookmark-db"
    private static let keychainAccount = "aes-gcm-key"

    private static func loadOrCreateKeyFromKeychain() throws -> SymmetricKey {
        if let existing = try loadKeyFromKeychain() {
            return existing
        }
        let key = SymmetricKey(size: .bits256)
        try saveKeyToKeychain(key)
        return key
    }

    private static func loadKeyFromKeychain() throws -> SymmetricKey? {
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
            guard let data = result as? Data else {
                throw BookmarkEncryptionError.keyLoadFailed
            }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        default:
            throw BookmarkEncryptionError.keyLoadFailed
        }
    }

    private static func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw BookmarkEncryptionError.keySaveFailed
        }
    }
    #endif

    // MARK: - File-based key (Android/Linux)

    #if !canImport(Security)
    private static func loadOrCreateKeyFromFile() throws -> SymmetricKey {
        let keyPath = try keyFilePath()

        if FileManager.default.fileExists(atPath: keyPath) {
            let data = try Data(contentsOf: URL(fileURLWithPath: keyPath))
            guard data.count == 32 else {
                throw BookmarkEncryptionError.keyLoadFailed
            }
            return SymmetricKey(data: data)
        }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }

        let dir = URL(fileURLWithPath: keyPath).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try keyData.write(to: URL(fileURLWithPath: keyPath), options: [.atomic])

        // Set restrictive file permissions (owner read/write only)
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
}

// MARK: - Errors

enum BookmarkEncryptionError: Error {
    case encryptionFailed
    case decryptionFailed
    case keyLoadFailed
    case keySaveFailed
}
