import Combine
import CryptoKit
import Darwin
import Foundation

@MainActor
final class QuotaStore: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var auth = AuthDisplayInfo()
    @Published private(set) var resetRows: [ResetExpirationRow] = []
    @Published private(set) var hasUpdate = false
    @Published private(set) var languageCode = effectiveLanguageCode()
    @Published private(set) var rechargeAnimationEvent: QuotaRechargeAnimationEvent?
    @Published private(set) var availableStorageText = "—"
    @Published private(set) var availableMemoryText = "—"

    static let lightModeKey = "CodexUsageWidget.isLightMode"
    static let pinnedKey = "CodexUsageWidget.isPinned"
    static let progressColorKey = "CodexUsageWidget.progressColorIndex"
    static let savedFrameKey = "CodexUsageWidget.savedFrame"
    private static let snapshotSchemaKey = "QuotaBubble.snapshotSchemaVersion"
    private static let snapshotSchemaVersion = 2

    private let codexHome: String
    private let snapshotService: QuotaSnapshotService?
    private lazy var snapshotPath = "\(codexHome)/codex-usage-snapshot.json"
    private lazy var authPath = "\(codexHome)/auth.json"
    private var timer: Timer?
    private var refreshInFlight = false
    private var lastVersionCheck = Date.distantPast
    private var authReadFailureSince: Date?
    private var nextRechargeAnimationID: UInt = 0

    init(codexHome: String? = nil, refreshesRemotely: Bool = true) {
        let resolvedHome = codexHome ?? ProcessInfo.processInfo.environment["CODEX_HOME"]
            ?? NSString(string: "~/.codex").expandingTildeInPath
        self.codexHome = resolvedHome
        snapshotService = refreshesRemotely ? QuotaSnapshotService(codexHome: resolvedHome) : nil
        Self.migrateLegacyPreferences()
        if refreshesRemotely { Self.invalidateGeneratedSnapshotIfNeeded(codexHome: resolvedHome) }
    }

    var copy: AppCopy { localizedCopy(languageCode) }
    var remainingPercentage: Int? { remainingPercent(fromUsedPercent: weeklyUsageWindow(from: snapshot)?.used_percentage) }
    var resetText: String { compactDuration(until: weeklyUsageWindow(from: snapshot)?.resets_at, copy: copy) }
    var resetDateText: String { formattedResetDate(weeklyUsageWindow(from: snapshot)?.resets_at) }
    var planText: String { planBadgeText(snapshot?.plan_type) }
    var balanceText: String { formattedBalance(snapshot?.balance_usd) }
    var resetCountText: String { snapshot?.reset_credits?.available_count.map(String.init) ?? "—" }
    var accountText: String { auth.email?.nonEmpty ?? "—" }
    var subscriptionText: String { formattedDate(auth.subscriptionExpiresAt) }
    var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return "v\(version)"
    }
    var desiredHeight: CGFloat {
        287 + (resetRows.isEmpty ? 0 : 18 + CGFloat(resetRows.count) * 18)
    }

    func start() {
        guard timer == nil else { return }
        refreshSystemCapacity()
        readLocalState()
        refreshSnapshot(force: true)
        checkVersion(force: true)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerDidFire), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func tick() {
        let currentLanguage = effectiveLanguageCode()
        if currentLanguage != languageCode { languageCode = currentLanguage }
        refreshSystemCapacity()
        readLocalState()
        refreshSnapshot()
        checkVersion()
    }

    @objc private func timerDidFire() { tick() }

    func selectLanguage(_ code: String?) {
        writeLanguageOverride(code)
        languageCode = effectiveLanguageCode()
        rebuildDerivedState()
    }

    func markUpdateInstalled() { hasUpdate = false }

    private func refreshSystemCapacity() {
        availableStorageText = formattedAvailableStorage(systemStorageCapacity(), languageCode: languageCode)
        availableMemoryText = formattedAvailableMemory(systemMemoryCapacity(), languageCode: languageCode)
    }

    private static func invalidateGeneratedSnapshotIfNeeded(codexHome: String) {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: snapshotSchemaKey) < snapshotSchemaVersion else { return }
        try? FileManager.default.removeItem(atPath: "\(codexHome)/codex-usage-snapshot.json")
        defaults.set(snapshotSchemaVersion, forKey: snapshotSchemaKey)
    }

    private func publishRechargeAnimation(from: Int, to: Int) {
        nextRechargeAnimationID &+= 1
        rechargeAnimationEvent = QuotaRechargeAnimationEvent(
            id: nextRechargeAnimationID,
            fromPercentage: from,
            toPercentage: to
        )
    }

    private func readLocalState() {
        let previousSnapshot = snapshot
        let currentAuth: AuthDisplayInfo
        if let decodedAuth = readAuthInfo() {
            authReadFailureSince = nil
            currentAuth = decodedAuth
        } else if FileManager.default.fileExists(atPath: authPath) {
            let failureSince = authReadFailureSince ?? Date()
            authReadFailureSince = failureSince
            currentAuth = Date().timeIntervalSince(failureSince) < 3 ? auth : AuthDisplayInfo()
        } else {
            authReadFailureSince = nil
            currentAuth = AuthDisplayInfo()
        }
        if snapshot?.account_fingerprint != currentAuth.accountFingerprint {
            snapshot = nil
        }
        if let data = try? Data(contentsOf: URL(fileURLWithPath: snapshotPath)),
           let decoded = try? JSONDecoder().decode(UsageSnapshot.self, from: data) {
            let snapshotFingerprint = decoded.account_fingerprint
            let authFingerprint = currentAuth.accountFingerprint
            if snapshotFingerprint == authFingerprint && snapshotFingerprint != nil {
                snapshot = decoded
            } else if snapshotFingerprint == nil && authFingerprint == nil {
                snapshot = decoded
            } else {
                snapshot = nil
            }
        }
        if let transition = quotaRechargeTransition(previous: previousSnapshot, next: snapshot) {
            publishRechargeAnimation(from: transition.fromPercentage, to: transition.toPercentage)
        }
        auth = currentAuth
        rebuildDerivedState()
    }

    private func rebuildDerivedState() {
        resetRows = formatResetRows(snapshot?.reset_credits)
    }

    private func refreshSnapshot(force: Bool = false) {
        guard !refreshInFlight, let snapshotService else { return }
        refreshInFlight = true
        let existing = snapshot
        Task { [weak self] in
            guard let self else { return }
            _ = await snapshotService.refresh(existing: existing)
            self.refreshInFlight = false
            self.readLocalState()
        }
    }

    private func readAuthInfo() -> AuthDisplayInfo? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: authPath)),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tokens = root["tokens"] as? [String: Any],
              let idToken = tokens["id_token"] as? String else { return nil }
        let parts = idToken.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count > 1 else { return nil }
        var payload = String(parts[1]).replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        guard let payloadData = Data(base64Encoded: payload),
              let claims = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any] else { return nil }
        let authClaims = claims["https://api.openai.com/auth"] as? [String: Any]
        let accountID = tokens["account_id"] as? String
        let accessToken = tokens["access_token"] as? String
        let fingerprint = accountID.map { accountFingerprint(kind: "account", value: $0) }
            ?? accessToken.map { accountFingerprint(kind: "token", value: $0) }
        return AuthDisplayInfo(
            email: claims["email"] as? String,
            subscriptionExpiresAt: authClaims?["chatgpt_subscription_active_until"] as? String,
            accountFingerprint: fingerprint
        )
    }

    private func formatResetRows(_ credits: ResetCredits?) -> [ResetExpirationRow] {
        let values = credits?.expires_at ?? []
        let count = max(0, credits?.available_count ?? values.count)
        guard count > 0 else { return [] }
        return (0..<count).map { index in
            guard index < values.count else { return ResetExpirationRow(id: index, dateText: "—", isExpiringSoon: nil) }
            let raw = values[index]
            let date = parseISODate(raw)
            return ResetExpirationRow(
                id: index,
                dateText: date.map(displayDate) ?? raw,
                isExpiringSoon: date.map { $0.timeIntervalSinceNow <= 3 * 86_400 }
            )
        }
    }

    private func formattedDate(_ raw: String?) -> String {
        guard let raw = raw?.nonEmpty else { return "—" }
        return parseISODate(raw).map(displayDate) ?? raw
    }

    private func parseISODate(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        return ISO8601DateFormatter().date(from: raw)
    }

    private func displayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func checkVersion(force: Bool = false) {
        guard force || Date().timeIntervalSince(lastVersionCheck) >= 1_800 else { return }
        lastVersionCheck = Date()
        let completion: @MainActor @Sendable (Bool) -> Void = { [weak self] hasUpdate in self?.hasUpdate = hasUpdate }
        DispatchQueue.global(qos: .utility).async {
            guard let url = URL(string: "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest"),
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let latest = normalizedVersion(json["tag_name"] as? String),
                  let current = normalizedVersion(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) else { return }
            let result = compareVersions(current, latest) == .orderedAscending
            Task { @MainActor in completion(result) }
        }
    }

    private static func migrateLegacyPreferences() {
        let current = UserDefaults.standard
        guard current.object(forKey: pinnedKey) == nil,
              let legacy = UserDefaults(suiteName: "local.codex.usage-widget") else { return }
        for key in [lightModeKey, pinnedKey, progressColorKey, savedFrameKey] {
            if let value = legacy.object(forKey: key) { current.set(value, forKey: key) }
        }
    }
}

struct SystemCapacity: Equatable {
    let available: Int64
    let total: Int64
}

func systemStorageCapacity() -> SystemCapacity? {
    let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
    if let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey]),
       let available = values.volumeAvailableCapacityForImportantUsage,
       let total = values.volumeTotalCapacity {
        return SystemCapacity(available: max(0, available), total: max(0, Int64(total)))
    }
    guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: home.path),
          let available = attributes[.systemFreeSize] as? NSNumber,
          let total = attributes[.systemSize] as? NSNumber else { return nil }
    return SystemCapacity(available: max(0, available.int64Value), total: max(0, total.int64Value))
}

func systemMemoryCapacity() -> SystemCapacity? {
    var pageSize: vm_size_t = 0
    guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else { return nil }

    var statistics = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
    let result = withUnsafeMutablePointer(to: &statistics) { pointer in
        pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
            host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
        }
    }
    guard result == KERN_SUCCESS else { return nil }

    let availablePages = UInt64(statistics.free_count)
        + UInt64(statistics.inactive_count)
        + UInt64(statistics.speculative_count)
    return SystemCapacity(
        available: Int64(min(UInt64(Int64.max), availablePages * UInt64(pageSize))),
        total: Int64(min(UInt64(Int64.max), ProcessInfo.processInfo.physicalMemory))
    )
}

func formattedAvailableStorage(_ capacity: SystemCapacity?, languageCode: String) -> String {
    let label: String
    switch languageCode {
    case "zh": label = "可用存储内存"
    case "ja": label = "利用可能なストレージ"
    case "ko": label = "사용 가능 저장 공간"
    case "de": label = "Verfügbarer Speicherplatz"
    case "fr": label = "Stockage disponible"
    case "es": label = "Almacenamiento disponible"
    case "pt": label = "Armazenamento disponível"
    case "it": label = "Spazio disponibile"
    case "nl": label = "Beschikbare opslag"
    default: label = "Available storage"
    }
    guard let capacity else { return languageCode == "zh" ? "\(label)：—" : "\(label): —" }
    let available = Double(capacity.available) / 1_000_000_000
    let value = String(format: "%.1fG", available)
    return languageCode == "zh" ? "\(label)：\(value)" : "\(label): \(value)"
}

func formattedAvailableMemory(_ capacity: SystemCapacity?, languageCode: String) -> String {
    let label: String
    switch languageCode {
    case "zh": label = "可用运行内存"
    case "ja": label = "利用可能メモリ"
    case "ko": label = "사용 가능 메모리"
    case "de": label = "Verfügbarer Speicher"
    case "fr": label = "Mémoire disponible"
    case "es": label = "Memoria disponible"
    case "pt": label = "Memória disponível"
    case "it": label = "Memoria disponibile"
    case "nl": label = "Beschikbaar geheugen"
    default: label = "Available memory"
    }
    return formattedCapacity(capacity, label: label, languageCode: languageCode, divisor: 1_073_741_824)
}

private func formattedCapacity(_ capacity: SystemCapacity?, label: String, languageCode: String, divisor: Double) -> String {
    guard let capacity else { return languageCode == "zh" ? "\(label)：—" : "\(label): —" }
    let available = Double(capacity.available) / divisor
    let total = Double(capacity.total) / divisor
    let value = String(format: "%.1fG / %.1fG", available, total)
    return languageCode == "zh" ? "\(label)：\(value)" : "\(label): \(value)"
}

private func accountFingerprint(kind: String, value: String) -> String {
    let digest = SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    return "\(kind):\(digest.prefix(16))"
}

private extension String {
    var nonEmpty: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
