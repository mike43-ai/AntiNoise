import Foundation
import Security

// Keychain-backed key/value for sensitive strings. Access is gated by
// `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` so the value is
// readable after the user has unlocked the device once per boot.
//
// v1.0.1 removed the OpenAI BYOK key (server proxy now). The store is kept
// for future secrets and for the launch-migration cleanup of legacy keys.
enum SecretStore {
    static let service = "com.antinoise.secrets"

    // Legacy account name — only used by the v1.0.1 migration that nukes the
    // old BYOK key from Keychain on first launch after upgrade.
    static let legacyOpenAIAPIKey = "openai_api_key"

    @discardableResult
    static func set(_ value: String, forKey account: String) -> Bool {
        let data = Data(value.utf8)
        let base: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(base as CFDictionary)

        var attrs = base
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attrs as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func get(forKey account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func remove(forKey account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
