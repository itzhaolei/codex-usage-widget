import Foundation

@main
enum QuotaModelsTests {
    static func main() throws {
        expect(normalizedPlanType("pro_20x") == "pro20x", "Pro20x normalization")
        expect(planBadgeText("pro") == "Pro20x", "generic Pro badge")
        expect(planBadgeText("chatgpt_pro_5x") == "Pro5x", "Pro5x badge")
        expect(planBadgeText("free") == "Free", "Free badge")
        expect(remainingPercent(fromUsedPercent: 0) == 100, "unused quota")
        expect(remainingPercent(fromUsedPercent: 29) == 71, "remaining quota")
        expect(remainingPercent(fromUsedPercent: 100) == 0, "exhausted quota")
        expect(formattedBalance("$1.5") == "1.5", "prefixed balance")
        expect(formattedBalance("2") == "2.00", "numeric balance")

        let future = Date().addingTimeInterval(6 * 86_400 + 23 * 3_600 + 57 * 60 + 38).timeIntervalSince1970
        let duration = compactDuration(until: future, copy: localizedCopy("en"))
        expect(duration.hasPrefix("6d 23h 57m"), "compact duration")

        let json = #"{"account_fingerprint":"account:0123456789abcdef","plan_type":"plus","balance_usd":"0","five_hour":{"used_percentage":45,"resets_at":1784644006},"reset_credits":{"available_count":2,"expires_at":["2026-08-01T04:15:00Z","2026-08-13T01:45:00Z"]}}"#.data(using: .utf8)!
        let snapshot = try JSONDecoder().decode(UsageSnapshot.self, from: json)
        expect(snapshot.plan_type == "plus", "snapshot plan")
        expect(snapshot.five_hour?.used_percentage == 45, "snapshot percentage")
        expect(snapshot.reset_credits?.expires_at?.count == 2, "snapshot reset expirations")
        expect(snapshot.account_fingerprint == "account:0123456789abcdef", "snapshot account fingerprint")

        print("Quota model tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("FAILED: \(message)\n", stderr)
            exit(1)
        }
    }
}
