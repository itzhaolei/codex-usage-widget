import Foundation

@main
enum QuotaModelsTests {
    static func main() throws {
        expect(normalizedPlanType("pro_20x") == "pro20x", "Pro20x normalization")
        expect(planBadgeText("pro") == "Pro20x", "generic Pro badge")
        expect(planBadgeText("chatgpt_pro_5x") == "Pro5x", "Pro5x badge")
        expect(planBadgeText("free") == "Free", "Free badge")
        expect(localizedCopy("zh").website == "官网", "Chinese website menu")
        expect(localizedNewWindowLabel("zh") == "新建窗口", "Chinese new-window menu")
        for language in supportedLanguages {
            expect(!localizedNewWindowLabel(language.code).isEmpty, "new-window label for \(language.code)")
        }
    expect(URL(string: officialWebsiteURLString)?.host == "htmlpreview.github.io", "official website URL")
    for language in supportedLanguages {
        expect(!localizedWebsiteShareLabel(language.code).isEmpty, "share label for \(language.code)")
        expect(!localizedWebsiteCopiedMessage(language.code).isEmpty, "share confirmation for \(language.code)")
    }
        expect(
            macOSInstallerDownloadURL(for: "v3.0.4") == "https://github.com/itzhaolei/codex-usage-widget/releases/download/v3.0.4/QuotaBubble-3.0.4-macOS-Installer.zip",
            "fallback installer URL"
        )
        expect(macOSInstallerDownloadURL(for: "3.0.5")?.contains("/v3.0.5/QuotaBubble-3.0.5-") == true, "fallback URL normalizes tag")
        expect(macOSInstallerDownloadURL(for: "v[3, 0, 4]") == nil, "fallback URL rejects malformed tag")
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
        expect(weeklyUsageWindow(from: snapshot)?.used_percentage == 45, "legacy single-window snapshot remains readable")

        let oldCycle = UsageSnapshot(account_fingerprint: "same", seven_day: UsageWindow(used_percentage: 50, resets_at: 1_000))
        let newCycle = UsageSnapshot(account_fingerprint: "same", seven_day: UsageWindow(used_percentage: 0, resets_at: 20_000))
        expect(
            quotaRechargeTransition(previous: oldCycle, next: newCycle) == QuotaRechargeTransition(fromPercentage: 50, toPercentage: 100),
            "new quota cycle triggers recharge animation"
        )
        let ordinaryUsage = UsageSnapshot(account_fingerprint: "same", seven_day: UsageWindow(used_percentage: 55, resets_at: 1_000))
        expect(quotaRechargeTransition(previous: oldCycle, next: ordinaryUsage) == nil, "ordinary usage does not trigger recharge animation")
        let switchedAccount = UsageSnapshot(account_fingerprint: "other", seven_day: UsageWindow(used_percentage: 0, resets_at: 20_000))
        expect(quotaRechargeTransition(previous: oldCycle, next: switchedAccount) == nil, "account switch does not trigger recharge animation")
        let fiveHourOnlyReset = UsageSnapshot(
            account_fingerprint: "same",
            five_hour: UsageWindow(used_percentage: 0, resets_at: 20_000),
            seven_day: UsageWindow(used_percentage: 50, resets_at: 1_000)
        )
        expect(quotaRechargeTransition(previous: oldCycle, next: fiveHourOnlyReset) == nil, "five-hour reset does not trigger weekly animation")

        print("Quota model tests passed.")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        guard condition() else {
            fputs("FAILED: \(message)\n", stderr)
            exit(1)
        }
    }
}
