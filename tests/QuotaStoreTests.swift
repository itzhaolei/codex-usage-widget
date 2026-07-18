import CryptoKit
import Foundation

@main
@MainActor
enum QuotaStoreTests {
    static func main() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("quota-store-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try writeAuth(accountID: "account-a", email: "a@example.test", root: root)
        try writeSnapshot(accountID: "account-a", used: 20, root: root)

        let store = QuotaStore(codexHome: root.path, refreshesRemotely: false)
        store.tick()
        expect(store.snapshot?.seven_day?.used_percentage == 20, "same-account weekly snapshot loads")
        expect(store.accountText == "a@example.test", "account A loads")

        try writeAuth(accountID: "account-b", email: "b@example.test", root: root)
        store.tick()
        expect(store.snapshot == nil, "old snapshot clears on account switch")
        expect(store.accountText == "b@example.test", "account B loads")

        try writeSnapshot(accountID: "account-b", used: 63, root: root)
        store.tick()
        expect(store.snapshot?.seven_day?.used_percentage == 63, "new-account weekly snapshot loads")
        expect(store.remainingPercentage == 37, "new-account remaining quota")

        print("Quota store tests passed.")
    }

    private static func writeAuth(accountID: String, email: String, root: URL) throws {
        let payload = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "https://api.openai.com/auth": ["chatgpt_subscription_active_until": "2026-08-01T00:00:00Z"],
        ])
        let encoded = payload.base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
        let auth: [String: Any] = ["tokens": ["account_id": accountID, "id_token": "x.\(encoded).x"]]
        let data = try JSONSerialization.data(withJSONObject: auth)
        try data.write(to: root.appendingPathComponent("auth.json"), options: .atomic)
    }

    private static func writeSnapshot(accountID: String, used: Int, root: URL) throws {
        let digest = SHA256.hash(data: Data(accountID.utf8)).map { String(format: "%02x", $0) }.joined()
        let snapshot: [String: Any] = [
            "account_fingerprint": "account:\(digest.prefix(16))",
            "plan_type": "plus",
            "seven_day": ["used_percentage": used, "resets_at": Date().addingTimeInterval(7 * 86_400).timeIntervalSince1970],
            "reset_credits": ["available_count": 0, "expires_at": []],
        ]
        let data = try JSONSerialization.data(withJSONObject: snapshot)
        try data.write(to: root.appendingPathComponent("codex-usage-snapshot.json"), options: .atomic)
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fputs("FAILED: \(message)\n", stderr); exit(1) }
    }
}
