import AppKit
import Combine
import CryptoKit
import Foundation

enum SetupIssue: Equatable {
    case ready
    case missingNode
    case missingCli
    case missingLogin
    case waitingForSnapshot
    case installing
    case installFailed
}

@MainActor
final class QuotaStore: ObservableObject {
    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var auth = AuthDisplayInfo()
    @Published private(set) var resetRows: [ResetExpirationRow] = []
    @Published private(set) var setupIssue: SetupIssue = .ready
    @Published private(set) var hasUpdate = false
    @Published private(set) var languageCode = effectiveLanguageCode()
    @Published var isLightMode: Bool {
        didSet { UserDefaults.standard.set(isLightMode, forKey: Self.lightModeKey) }
    }
    @Published var isPinned: Bool {
        didSet { UserDefaults.standard.set(isPinned, forKey: Self.pinnedKey) }
    }

    static let lightModeKey = "CodexUsageWidget.isLightMode"
    static let pinnedKey = "CodexUsageWidget.isPinned"
    static let savedFrameKey = "CodexUsageWidget.savedFrame"

    private let codexHome: String
    private lazy var snapshotPath = "\(codexHome)/codex-usage-snapshot.json"
    private lazy var snapshotScriptPath = "\(codexHome)/scripts/codex-usage-snapshot.mjs"
    private lazy var authPath = "\(codexHome)/auth.json"
    private var timer: Timer?
    private var refreshInFlight = false
    private var installInFlight = false
    private var lastVersionCheck = Date.distantPast
    private var lastSessionCheck = Date.distantPast
    private var cachedSessionAvailable = false
    private var authReadFailureSince: Date?

    init(codexHome: String? = nil) {
        self.codexHome = codexHome ?? ProcessInfo.processInfo.environment["CODEX_HOME"]
            ?? NSString(string: "~/.codex").expandingTildeInPath
        Self.migrateLegacyPreferences()
        isLightMode = UserDefaults.standard.bool(forKey: Self.lightModeKey)
        isPinned = UserDefaults.standard.object(forKey: Self.pinnedKey) as? Bool ?? true
    }

    var copy: AppCopy { localizedCopy(languageCode) }
    var remainingPercentage: Int? { remainingPercent(fromUsedPercent: snapshot?.five_hour?.used_percentage) }
    var resetText: String { compactDuration(until: snapshot?.five_hour?.resets_at, copy: copy) }
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
        234 + (resetRows.isEmpty ? 0 : 18 + CGFloat(resetRows.count) * 18)
    }

    func start() {
        guard timer == nil else { return }
        readLocalState()
        refreshSnapshot(force: true)
        checkVersion(force: true)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func tick() {
        let currentLanguage = effectiveLanguageCode()
        if currentLanguage != languageCode { languageCode = currentLanguage }
        readLocalState()
        refreshSnapshot()
        checkVersion()
    }

    func selectLanguage(_ code: String?) {
        writeLanguageOverride(code)
        languageCode = effectiveLanguageCode()
        rebuildDerivedState()
    }

    func toggleTheme() { isLightMode.toggle() }
    func togglePinned() { isPinned.toggle() }
    func markUpdateInstalled() { hasUpdate = false }

    func performSetupAction() {
        switch setupIssue {
        case .missingNode:
            installNode()
        case .missingCli, .installFailed:
            installCodexCLI()
        case .missingLogin:
            openLogin()
        case .waitingForSnapshot:
            refreshSnapshot(force: true)
        case .ready, .installing:
            break
        }
    }

    private func tickSetupIssue() {
        if installInFlight {
            setupIssue = .installing
            return
        }
        if !nodeAvailable() { setupIssue = .missingNode; return }
        if !codexCLIAvailable() { setupIssue = .missingCli; return }
        if !FileManager.default.fileExists(atPath: authPath) && !hasSessionData() {
            setupIssue = .missingLogin
            return
        }
        if snapshot == nil { setupIssue = .waitingForSnapshot; return }
        setupIssue = .ready
    }

    private func readLocalState() {
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
        auth = currentAuth
        rebuildDerivedState()
        tickSetupIssue()
    }

    private func rebuildDerivedState() {
        resetRows = formatResetRows(snapshot?.reset_credits)
    }

    private func refreshSnapshot(force: Bool = false) {
        guard !refreshInFlight, FileManager.default.fileExists(atPath: snapshotScriptPath) else { return }
        refreshInFlight = true
        let script = snapshotScriptPath
        let output = snapshotPath
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["node", script, output]
            process.environment = ["PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/sbin:/usr/sbin"]
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            var succeeded = false
            do {
                try process.run()
                process.waitUntilExit()
                succeeded = process.terminationStatus == 0
            } catch {}
            if !succeeded {
                let fallback = Process()
                fallback.executableURL = URL(fileURLWithPath: "/bin/zsh")
                fallback.arguments = ["-lc", "node \(shellQuote(script)) \(shellQuote(output))"]
                fallback.standardOutput = Pipe()
                fallback.standardError = Pipe()
                try? fallback.run()
                fallback.waitUntilExit()
            }
            Task { @MainActor in
                guard let self else { return }
                self.refreshInFlight = false
                self.readLocalState()
            }
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

    private func nodeAvailable() -> Bool {
        var candidates = [
            "/opt/homebrew/bin/node", "/usr/local/bin/node", "/usr/bin/node",
            NSString(string: "~/.volta/bin/node").expandingTildeInPath,
            NSString(string: "~/.local/bin/node").expandingTildeInPath,
        ]
        let nvmRoot = NSString(string: "~/.nvm/versions/node").expandingTildeInPath
        if let versions = try? FileManager.default.contentsOfDirectory(atPath: nvmRoot) {
            candidates.append(contentsOf: versions.map { "\(nvmRoot)/\($0)/bin/node" })
        }
        return candidates.contains {
            FileManager.default.isExecutableFile(atPath: $0)
        }
    }

    private func codexCLIPath() -> String? {
        ["~/.local/bin/codex", "/opt/homebrew/bin/codex", "/usr/local/bin/codex", "/usr/bin/codex"]
            .map { NSString(string: $0).expandingTildeInPath }
            .first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    private func codexCLIAvailable() -> Bool { codexCLIPath() != nil }

    private func hasSessionData() -> Bool {
        if Date().timeIntervalSince(lastSessionCheck) < 30 { return cachedSessionAvailable }
        lastSessionCheck = Date()
        for path in ["\(codexHome)/sessions", "\(codexHome)/archived_sessions"] {
            guard let enumerator = FileManager.default.enumerator(atPath: path) else { continue }
            for case let file as String in enumerator where file.hasSuffix(".jsonl") {
                cachedSessionAvailable = true
                return true
            }
        }
        cachedSessionAvailable = false
        return cachedSessionAvailable
    }

    private func installNode() {
        if let brew = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"].first(where: FileManager.default.isExecutableFile) {
            openTerminal("\(shellQuote(brew)) install node")
        } else if let url = URL(string: "https://nodejs.org/") {
            NSWorkspace.shared.open(url)
        }
    }

    private func installCodexCLI() {
        installInFlight = true
        tickSetupIssue()
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", "curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh"]
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            var success = false
            do {
                try process.run()
                process.waitUntilExit()
                success = process.terminationStatus == 0
            } catch {}
            Task { @MainActor in
                guard let self else { return }
                self.installInFlight = false
                if success { self.refreshSnapshot(force: true); self.tickSetupIssue() }
                else { self.setupIssue = .installFailed }
            }
        }
    }

    private func openLogin() {
        openTerminal("\(shellQuote(codexCLIPath() ?? "codex")) login")
    }

    private func openTerminal(_ command: String) {
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", "tell application \"Terminal\" to do script \"\(escaped)\"", "-e", "tell application \"Terminal\" to activate"]
        try? process.run()
    }

    private func checkVersion(force: Bool = false) {
        guard force || Date().timeIntervalSince(lastVersionCheck) >= 1_800 else { return }
        lastVersionCheck = Date()
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let url = URL(string: "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest"),
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let latest = normalizedVersion(json["tag_name"] as? String),
                  let current = normalizedVersion(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) else { return }
            Task { @MainActor in self?.hasUpdate = compareVersions(current, latest) == .orderedAscending }
        }
    }

    private static func migrateLegacyPreferences() {
        let current = UserDefaults.standard
        guard current.object(forKey: pinnedKey) == nil,
              let legacy = UserDefaults(suiteName: "local.codex.usage-widget") else { return }
        for key in [lightModeKey, pinnedKey, savedFrameKey] {
            if let value = legacy.object(forKey: key) { current.set(value, forKey: key) }
        }
    }
}

func shellQuote(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
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
