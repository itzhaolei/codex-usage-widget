import CryptoKit
import Foundation

private struct NativeAuthContext: Equatable {
    let accessToken: String
    let accountID: String?
    let fingerprint: String
}

func quotaRequestHeaders(token: String, accountID: String?) -> [String: String] {
    var headers = [
        "Authorization": "Bearer \(token)",
        "OAI-Language": "en",
        "originator": "Codex Desktop",
    ]
    if let accountID = accountID?.trimmingCharacters(in: .whitespacesAndNewlines), !accountID.isEmpty {
        headers["ChatGPT-Account-Id"] = accountID
    }
    return headers
}

struct NativeUsagePayload: Equatable {
    var planType: String?
    var balanceUsd: String?
    var fiveHour: UsageWindow?
    var sevenDay: UsageWindow?
    var resetCredits: ResetCredits?
}

enum NativeQuotaParser {
    static func usage(from data: Data) -> NativeUsagePayload? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let rateLimit = object(root["rate_limit"]) ?? object(root["rate_limits"])
        let credits = object(root["credits"])
        let resetValue = object(root["rate_limit_reset_credits"])
        let resetCount = integer(resetValue?["available_count"])
        let resetCredits = resetCount.map {
            ResetCredits(available_count: max(0, $0), expires_at: resetExpirations(from: resetValue ?? [:], limit: max(0, $0)))
        }

        let primaryWindow = usageWindow(object(rateLimit?["primary_window"]) ?? object(rateLimit?["primary"]))
        let secondaryWindow = usageWindow(object(rateLimit?["secondary_window"]) ?? object(rateLimit?["secondary"]))
        let payload = NativeUsagePayload(
            planType: planType(in: root),
            balanceUsd: balance(credits?["balance"]),
            fiveHour: secondaryWindow == nil ? nil : primaryWindow,
            sevenDay: secondaryWindow ?? primaryWindow,
            resetCredits: resetCredits
        )
        guard payload.fiveHour != nil || payload.sevenDay != nil || payload.resetCredits != nil || payload.balanceUsd != nil else {
            return nil
        }
        return payload
    }

    static func detailedResetCredits(from data: Data) -> ResetCredits? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let count = integer(root["available_count"]) else { return nil }
        let normalizedCount = max(0, count)
        return ResetCredits(
            available_count: normalizedCount,
            expires_at: resetExpirations(from: root, limit: normalizedCount)
        )
    }

    static func mergedWindow(existing: UsageWindow?, next: UsageWindow?, sameAccount: Bool) -> UsageWindow? {
        guard let next else { return sameAccount ? existing : nil }
        guard sameAccount, let existing else { return next }

        if let existingReset = existing.resets_at, let nextReset = next.resets_at {
            let cycleTolerance: TimeInterval = 5 * 60
            if nextReset < existingReset - cycleTolerance {
                return existing
            }
            if abs(existingReset - nextReset) <= cycleTolerance,
               let existingUsed = existing.used_percentage,
               let nextUsed = next.used_percentage {
                return UsageWindow(used_percentage: max(existingUsed, nextUsed), resets_at: existingReset)
            }
        }
        return next
    }

    private static func usageWindow(_ value: [String: Any]?) -> UsageWindow? {
        let directUsed = number(value?["used_percent"])
            ?? number(value?["used_percentage"])
            ?? number(value?["usedPercent"])
        let remaining = number(value?["remaining_percent"])
            ?? number(value?["remaining_percentage"])
            ?? number(value?["remainingPercent"])
        guard let used = directUsed ?? remaining.map({ 100 - $0 }) else { return nil }
        let reset = number(value?["reset_at"])
            ?? number(value?["resets_at"])
            ?? number(value?["resetAt"])
        return UsageWindow(
            used_percentage: min(100, max(0, Int(used.rounded()))),
            resets_at: reset
        )
    }

    private static func planType(in root: [String: Any]) -> String? {
        let plan = object(root["plan"])
        let subscription = object(root["subscription"])
        let account = object(root["account"])
        let candidates: [Any?] = [
            root["plan_type"], root["plan"], plan?["type"], plan?["id"], plan?["name"], plan?["tier"],
            subscription?["plan"], subscription?["plan_type"], subscription?["plan_id"], subscription?["tier"],
            account?["plan"], account?["plan_type"], account?["plan_id"], account?["tier"],
        ]
        let values = candidates.compactMap { normalizedPlanType($0 as? String) }
        return ["pro20x", "pro5x", "plus", "free"].first(where: values.contains)
    }

    private static func balance(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        guard let number = number(value) else { return nil }
        return String(number)
    }

    private static func resetExpirations(from value: Any, limit: Int) -> [String] {
        var dates: [Date] = []
        collectExpirations(value, into: &dates)
        let sorted = dates.sorted()
        let limited = limit >= 0 ? Array(sorted.prefix(limit)) : sorted
        return limited.map(isoString)
    }

    private static func collectExpirations(_ value: Any, into output: inout [Date]) {
        if let values = value as? [Any] {
            values.forEach { collectExpirations($0, into: &output) }
            return
        }
        guard let object = value as? [String: Any] else { return }
        let expirationKeys = ["expires_at", "expire_at", "expiration_at", "expiresAt", "expires_on", "valid_until", "validUntil"]
        for key in expirationKeys {
            guard let date = date(object[key]) else { continue }
            let copies = min(50, max(1, integer(object["count"]) ?? integer(object["quantity"]) ?? integer(object["available_count"]) ?? integer(object["availableCount"]) ?? 1))
            output.append(contentsOf: repeatElement(date, count: copies))
            break
        }
        for key in ["credits", "items", "grants", "available", "reset_credits", "rate_limit_reset_credits", "reset_credit_grants"] {
            if let child = object[key] { collectExpirations(child, into: &output) }
        }
    }

    private static func object(_ value: Any?) -> [String: Any]? { value as? [String: Any] }

    private static func number(_ value: Any?) -> Double? {
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private static func integer(_ value: Any?) -> Int? {
        number(value).map { Int($0.rounded()) }
    }

    private static func date(_ value: Any?) -> Date? {
        if let number = number(value) {
            return Date(timeIntervalSince1970: number > 1_000_000_000_000 ? number / 1000 : number)
        }
        guard let value = value as? String, !value.isEmpty else { return nil }
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    private static func isoString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

actor QuotaSnapshotService {
    private struct ResetCache {
        let fingerprint: String
        let value: ResetCredits
        let fetchedAt: Date
    }

    private let snapshotPath: String
    private let authPath: String
    private let session: URLSession
    private var resetCache: ResetCache?
    private var usageFailureStartedAt: Date?
    private let staleQuotaGracePeriod: TimeInterval = 15

    init(codexHome: String) {
        snapshotPath = "\(codexHome)/codex-usage-snapshot.json"
        authPath = "\(codexHome)/auth.json"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 5
        configuration.timeoutIntervalForResource = 8
        session = URLSession(configuration: configuration)
    }

    func refresh(existing: UsageSnapshot?) async -> UsageSnapshot? {
        guard let auth = readAuth() else { return nil }
        let sameAccount = existing?.account_fingerprint == auth.fingerprint
        guard let usageData = await request(
            "https://chatgpt.com/backend-api/wham/usage",
            token: auth.accessToken,
            accountID: auth.accountID,
            timeout: 5
        ),
              let usage = NativeQuotaParser.usage(from: usageData) else {
            return snapshotAfterUsageFailure(existing: existing, fingerprint: auth.fingerprint, sameAccount: sameAccount)
        }
        usageFailureStartedAt = nil

        var nextResetCredits = usage.resetCredits
        let needsDetails = nextResetCredits == nil
            || ((nextResetCredits?.available_count ?? 0) > 0 && (nextResetCredits?.expires_at?.isEmpty ?? true))
        if needsDetails {
            nextResetCredits = await resetCredits(token: auth.accessToken, accountID: auth.accountID, fingerprint: auth.fingerprint)
                ?? (sameAccount ? existing?.reset_credits : nil)
        }

        guard readAuth()?.fingerprint == auth.fingerprint else { return nil }
        let snapshot = UsageSnapshot(
            updated_at: ISO8601DateFormatter().string(from: Date()),
            account_fingerprint: auth.fingerprint,
            plan_type: usage.planType ?? (sameAccount ? existing?.plan_type : nil),
            balance_usd: usage.balanceUsd ?? (sameAccount ? existing?.balance_usd : nil),
            five_hour: NativeQuotaParser.mergedWindow(existing: existing?.five_hour, next: usage.fiveHour, sameAccount: sameAccount),
            seven_day: NativeQuotaParser.mergedWindow(existing: existing?.seven_day, next: usage.sevenDay, sameAccount: sameAccount),
            reset_credits: nextResetCredits ?? (sameAccount ? existing?.reset_credits : nil)
        )
        write(snapshot)
        return snapshot
    }

    private func resetCredits(token: String, accountID: String?, fingerprint: String) async -> ResetCredits? {
        if let resetCache,
           resetCache.fingerprint == fingerprint,
           Date().timeIntervalSince(resetCache.fetchedAt) < 30 {
            return resetCache.value
        }
        guard let data = await request(
            "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits",
            token: token,
            accountID: accountID,
            timeout: 3
        ),
              let value = NativeQuotaParser.detailedResetCredits(from: data) else {
            return resetCache?.fingerprint == fingerprint ? resetCache?.value : nil
        }
        resetCache = ResetCache(fingerprint: fingerprint, value: value, fetchedAt: Date())
        return value
    }

    private func request(_ rawURL: String, token: String, accountID: String?, timeout: TimeInterval) async -> Data? {
        guard let url = URL(string: rawURL) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        for (name, value) in quotaRequestHeaders(token: token, accountID: accountID) {
            request.setValue(value, forHTTPHeaderField: name)
        }
        do {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else { return nil }
            return data
        } catch {
            return nil
        }
    }

    private func readAuth() -> NativeAuthContext? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: authPath)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = root["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String,
              !accessToken.isEmpty else { return nil }
        let accountID = tokens["account_id"] as? String
        let kind = accountID == nil ? "token" : "account"
        let value = accountID ?? accessToken
        let digest = SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
        return NativeAuthContext(accessToken: accessToken, accountID: accountID, fingerprint: "\(kind):\(digest.prefix(16))")
    }

    private func snapshotAfterUsageFailure(existing: UsageSnapshot?, fingerprint: String, sameAccount: Bool) -> UsageSnapshot {
        let now = Date()
        let failureStartedAt = usageFailureStartedAt ?? now
        usageFailureStartedAt = failureStartedAt
        if sameAccount, let existing, now.timeIntervalSince(failureStartedAt) < staleQuotaGracePeriod {
            return existing
        }

        var snapshot = sameAccount ? (existing ?? emptySnapshot(for: fingerprint)) : emptySnapshot(for: fingerprint)
        snapshot.updated_at = ISO8601DateFormatter().string(from: now)
        snapshot.account_fingerprint = fingerprint
        snapshot.five_hour = nil
        snapshot.seven_day = nil
        write(snapshot)
        return snapshot
    }

    private func emptySnapshot(for fingerprint: String) -> UsageSnapshot {
        UsageSnapshot(
            updated_at: ISO8601DateFormatter().string(from: Date()),
            account_fingerprint: fingerprint,
            plan_type: nil,
            balance_usd: nil,
            five_hour: nil,
            seven_day: nil,
            reset_credits: nil
        )
    }

    private func write(_ snapshot: UsageSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let url = URL(fileURLWithPath: snapshotPath)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
