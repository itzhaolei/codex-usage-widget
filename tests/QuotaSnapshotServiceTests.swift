import Foundation

@main
enum QuotaSnapshotServiceTests {
    static func main() throws {
        let usageJSON = #"{"plan_type":"pro","rate_limit":{"primary_window":{"used_percent":27,"reset_at":1784644006},"secondary_window":{"used_percent":41,"reset_at":1785248806}},"credits":{"balance":"1.50"},"rate_limit_reset_credits":{"available_count":2}}"#.data(using: .utf8)!
        let usage = try require(NativeQuotaParser.usage(from: usageJSON), "usage payload")
        expect(usage.planType == "pro20x", "generic Pro maps to Pro20x")
        expect(usage.fiveHour?.used_percentage == 27, "primary window")
        expect(usage.sevenDay?.used_percentage == 41, "secondary window")
        expect(usage.balanceUsd == "1.50", "balance")
        expect(usage.resetCredits?.available_count == 2, "reset count")

        let resetJSON = #"{"available_count":2,"grants":[{"expires_at":"2026-08-13T01:45:00Z"},{"expires_at":"2026-08-01T04:15:00Z"}]}"#.data(using: .utf8)!
        let resets = try require(NativeQuotaParser.detailedResetCredits(from: resetJSON), "reset payload")
        expect(resets.expires_at?.count == 2, "reset expirations")
        expect(resets.expires_at?.first?.contains("2026-08-01") == true, "reset expirations sort")

        let existing = UsageWindow(used_percentage: 79, resets_at: 1_784_644_006)
        let transient = UsageWindow(used_percentage: 22, resets_at: 1_784_644_010)
        let stabilized = NativeQuotaParser.mergedWindow(existing: existing, next: transient, sameAccount: true)
        expect(stabilized?.used_percentage == 79, "same-cycle usage cannot move backward")
        expect(NativeQuotaParser.mergedWindow(existing: existing, next: transient, sameAccount: false)?.used_percentage == 22, "new account does not inherit usage")

        let oldCycle = UsageWindow(used_percentage: 50, resets_at: 1_784_644_000)
        let newCycle = UsageWindow(used_percentage: 0, resets_at: 1_784_662_000)
        let acceptedReset = NativeQuotaParser.mergedWindow(existing: oldCycle, next: newCycle, sameAccount: true)
        expect(acceptedReset?.used_percentage == 0, "new quota cycle is accepted")
        expect(acceptedReset?.resets_at == newCycle.resets_at, "new quota cycle reset time is retained")

        let rejectedStaleCycle = NativeQuotaParser.mergedWindow(existing: acceptedReset, next: oldCycle, sameAccount: true)
        expect(rejectedStaleCycle == acceptedReset, "stale previous-cycle response cannot replace the new cycle")
        expect(NativeQuotaParser.mergedWindow(existing: newCycle, next: oldCycle, sameAccount: false) == oldCycle, "account changes may use an earlier reset time")

        print("Native quota snapshot tests passed.")
    }

    private static func require<T>(_ value: T?, _ message: String) throws -> T {
        guard let value else { throw TestFailure(message: message) }
        return value
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else { fputs("FAILED: \(message)\n", stderr); exit(1) }
    }

    private struct TestFailure: Error { let message: String }
}
