import Combine
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
        expect(store.availableStorageText.hasSuffix("G"), "available storage is refreshed")
        expect(store.availableMemoryText.contains("G / "), "available memory is refreshed")
        expect(
            formattedAvailableStorage(SystemCapacity(available: 356_800_000_000, total: 494_380_000_000), languageCode: "zh") == "可用存储内存：356.8G",
            "available storage formatting"
        )
        expect(
            formattedAvailableMemory(SystemCapacity(available: 4_080_218_931, total: 17_179_869_184), languageCode: "zh") == "可用运行内存：3.8G / 16.0G",
            "available memory formatting"
        )
        expect(isStorageCapacityWarning(SystemCapacity(available: 49_999_999_999, total: 500_000_000_000)), "storage below 50G warns")
        expect(!isStorageCapacityWarning(SystemCapacity(available: 50_000_000_000, total: 500_000_000_000)), "storage at 50G stays healthy")
        expect(isMemoryCapacityWarning(SystemCapacity(available: 11 * 1_073_741_824 + 1, total: 17_179_869_184)), "memory above 11G warns")
        expect(!isMemoryCapacityWarning(SystemCapacity(available: 11 * 1_073_741_824, total: 17_179_869_184)), "memory at 11G stays healthy")

        try writeAuth(accountID: "account-b", email: "b@example.test", root: root)
        store.tick()
        expect(store.snapshot == nil, "old snapshot clears on account switch")
        expect(store.accountText == "b@example.test", "account B loads")

        try writeSnapshot(accountID: "account-b", used: 63, root: root)
        store.tick()
        expect(store.snapshot?.seven_day?.used_percentage == 63, "new-account weekly snapshot loads")
        expect(store.remainingPercentage == 37, "new-account remaining quota")
        expect(store.statusPercentage == 37, "weekly-only status item uses weekly quota")

        let weeklyHeight = store.desiredHeight
        expect(store.fiveHourWindow == nil, "weekly-only account hides five-hour quota")
        try writeSnapshot(accountID: "account-b", used: 63, fiveHourUsed: 0, root: root)
        store.tick()
        expect(store.fiveHourWindow?.used_percentage == 0, "unused five-hour quota is visible")
        expect(store.remainingPercentage == 37, "five-hour quota does not change weekly quota")
        expect(store.statusPercentage == 100, "five-hour status item uses five-hour quota")
        expect(store.desiredHeight > weeklyHeight, "two quotas expand window")
        try writeSnapshot(accountID: "account-b", used: 63, fiveHourUsed: 100, root: root)
        store.tick()
        expect(store.fiveHourWindow?.used_percentage == 100, "exhausted five-hour quota stays visible")
        expect(store.statusPercentage == 0, "exhausted five-hour status item stays visible")
        try writeSnapshot(accountID: "account-b", used: 63, root: root)
        store.tick()
        expect(store.fiveHourWindow == nil, "removed five-hour limit hides quota")
        expect(store.statusPercentage == 37, "status item returns to weekly quota")
        expect(store.desiredHeight == weeklyHeight, "weekly-only layout restores original height")

        store.setWindowVisible(false)
        var windowChanges = 0
        let observation = store.objectWillChange.sink { windowChanges += 1 }
        var statusChanges: [Int?] = []
        let statusObservation = store.statusPercentagePublisher.dropFirst().sink { statusChanges.append($0) }
        try writeSnapshot(accountID: "account-b", used: 82, fiveHourUsed: 42, root: root)
        store.tick()
        expect(store.statusPercentage == 58, "hidden status item receives fresh five-hour quota")
        expect(store.remainingPercentage == 37, "hidden window keeps its last displayed values")
        expect(windowChanges == 0, "hidden refresh does not invalidate window or sample capacity")
        store.tick()
        expect(statusChanges.count == 1, "unchanged percentage does not republish status")

        try writeAuth(accountID: "account-c", email: "c@example.test", root: root)
        store.tick()
        expect(store.statusPercentage == nil, "hidden account switch clears old status")
        expect(windowChanges == 0, "hidden account switch does not render the window")
        try writeSnapshot(accountID: "account-c", used: 10, root: root)
        store.tick()
        expect(store.statusPercentage == 90, "hidden new account refreshes status")
        store.setWindowVisible(true)
        expect(store.remainingPercentage == 90, "reopening immediately displays latest quota")
        expect(store.accountText == "c@example.test", "reopening displays latest account")
        expect(store.rechargeAnimationEvent == nil, "reopening does not replay hidden recharge")
        expect(windowChanges > 0, "visible window resumes updates")
        withExtendedLifetime((observation, statusObservation)) {}

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

    private static func writeSnapshot(accountID: String, used: Int, fiveHourUsed: Int? = nil, root: URL) throws {
        let digest = SHA256.hash(data: Data(accountID.utf8)).map { String(format: "%02x", $0) }.joined()
        var snapshot: [String: Any] = [
            "account_fingerprint": "account:\(digest.prefix(16))",
            "plan_type": "plus",
            "seven_day": ["used_percentage": used, "resets_at": Date().addingTimeInterval(7 * 86_400).timeIntervalSince1970],
            "reset_credits": ["available_count": 0, "expires_at": []],
        ]
        if let fiveHourUsed {
            snapshot["five_hour"] = ["used_percentage": fiveHourUsed, "resets_at": Date().addingTimeInterval(5 * 3_600).timeIntervalSince1970]
        }
        let data = try JSONSerialization.data(withJSONObject: snapshot)
        try data.write(to: root.appendingPathComponent("codex-usage-snapshot.json"), options: .atomic)
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fputs("FAILED: \(message)\n", stderr); exit(1) }
    }
}
