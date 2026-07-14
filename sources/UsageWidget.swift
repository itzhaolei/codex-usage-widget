// UsageWidget.swift — 常驻桌面配额进度浮动窗
// 编译: swiftc -parse-as-library -o UsageWidget UsageWidget.swift -framework Cocoa

import Cocoa

// MARK: — 快照模型
struct UsageSnapshot: Codable {
    var updated_at: String?
    var plan_type: String?
    var balance_usd: String?
    var five_hour: UsageWindow?
    var seven_day: UsageWindow?
    var reset_credits: ResetCredits?
}

struct UsageWindow: Codable {
    var used_percentage: Int?
    var resets_at: TimeInterval?
}

struct ResetCredits: Codable {
    var available_count: Int?
    var expires_at: [String]?
}

// MARK: — Localization
struct AppLanguage {
    let title: String
    let week: String
    let reset: String
    let availableReset: String
    let balance: String
    let times: String
    let alreadyReset: String
    let unableToReadSnapshot: String
    let switchToDark: String
    let switchToLight: String
    let pin: String
    let unpin: String
    let close: String
    let separator: String
    let afterSuffix: String
    let day: (Int) -> String
    let hour: (Int) -> String
    let minute: (Int) -> String
    let second: (Int) -> String
}

func plural(_ value: Int, _ one: String, _ other: String) -> String {
    "\(value) \(value == 1 ? one : other)"
}

let zhLanguage = AppLanguage(
    title: "Codex 额度", week: "周", reset: "重置", availableReset: "可用重置", balance: "余额", times: "次",
    alreadyReset: "已重置", unableToReadSnapshot: "无法读取快照",
    switchToDark: "切换到黑色模式", switchToLight: "切换到白色模式",
    pin: "置顶", unpin: "取消置顶", close: "关闭窗口", separator: " ",
    afterSuffix: "后",
    day: { "\($0)天" }, hour: { "\($0)小时" }, minute: { "\($0)分钟" }, second: { "\($0)秒" }
)

func languagePreferencePath() -> String {
    NSString(string: "~/.codex/usage-widget/language.txt").expandingTildeInPath
}

func readLanguageOverride() -> String? {
    guard let raw = try? String(contentsOfFile: languagePreferencePath(), encoding: .utf8) else { return nil }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return ["en", "zh", "ja", "ko", "de", "fr", "es", "pt", "it", "nl"].contains(value) ? value : nil
}

func systemLanguageCode() -> String {
    let code = Locale.preferredLanguages.first?.lowercased() ?? "en"
    if code.hasPrefix("zh") { return "zh" }
    if code.hasPrefix("ja") { return "ja" }
    if code.hasPrefix("ko") { return "ko" }
    if code.hasPrefix("de") { return "de" }
    if code.hasPrefix("fr") { return "fr" }
    if code.hasPrefix("es") { return "es" }
    if code.hasPrefix("pt") { return "pt" }
    if code.hasPrefix("it") { return "it" }
    if code.hasPrefix("nl") { return "nl" }
    return "en"
}

func effectiveLanguageCode() -> String {
    readLanguageOverride() ?? systemLanguageCode()
}

func localizedLanguage() -> AppLanguage {
    let code = effectiveLanguageCode()
    if code == "zh" { return zhLanguage }
    if code == "ja" {
        return AppLanguage(title: "Codex 使用量", week: "週", reset: "リセット", availableReset: "利用可能なリセット", balance: "残高", times: "回",
            alreadyReset: "リセット済み", unableToReadSnapshot: "スナップショットを読み込めません",
            switchToDark: "ダークモードに切り替え", switchToLight: "ライトモードに切り替え",
            pin: "最前面に固定", unpin: "固定を解除", close: "ウィンドウを閉じる", separator: " ",
            afterSuffix: "後", day: { "\($0)日" }, hour: { "\($0)時間" }, minute: { "\($0)分" }, second: { "\($0)秒" })
    }
    if code == "ko" {
        return AppLanguage(title: "Codex 사용량", week: "주", reset: "재설정", availableReset: "사용 가능 재설정", balance: "잔액", times: "회",
            alreadyReset: "재설정됨", unableToReadSnapshot: "스냅샷을 읽을 수 없음",
            switchToDark: "다크 모드로 전환", switchToLight: "라이트 모드로 전환",
            pin: "항상 위", unpin: "항상 위 해제", close: "창 닫기", separator: " ",
            afterSuffix: " 후", day: { "\($0)일" }, hour: { "\($0)시간" }, minute: { "\($0)분" }, second: { "\($0)초" })
    }
    if code == "de" {
        return AppLanguage(title: "Codex Limit", week: "Woche", reset: "Reset", availableReset: "Verfügbare Resets", balance: "Guthaben", times: "Mal",
            alreadyReset: "Zurückgesetzt", unableToReadSnapshot: "Snapshot kann nicht gelesen werden",
            switchToDark: "Zu Dunkel wechseln", switchToLight: "Zu Hell wechseln",
            pin: "Anheften", unpin: "Lösen", close: "Fenster schließen", separator: " ",
            afterSuffix: " später", day: { plural($0, "Tag", "Tage") }, hour: { plural($0, "Stunde", "Stunden") }, minute: { plural($0, "Minute", "Minuten") }, second: { plural($0, "Sekunde", "Sekunden") })
    }
    if code == "fr" {
        return AppLanguage(title: "Quota Codex", week: "Semaine", reset: "Réinit.", availableReset: "Réinitialisations dispo.", balance: "Solde", times: "fois",
            alreadyReset: "Réinitialisé", unableToReadSnapshot: "Impossible de lire l’instantané",
            switchToDark: "Passer en mode sombre", switchToLight: "Passer en mode clair",
            pin: "Épingler", unpin: "Détacher", close: "Fermer la fenêtre", separator: " ",
            afterSuffix: " plus tard", day: { plural($0, "jour", "jours") }, hour: { plural($0, "heure", "heures") }, minute: { plural($0, "minute", "minutes") }, second: { plural($0, "seconde", "secondes") })
    }
    if code == "es" {
        return AppLanguage(title: "Cuota Codex", week: "Semana", reset: "Reinicio", availableReset: "Reinicios disponibles", balance: "Saldo", times: "veces",
            alreadyReset: "Reiniciado", unableToReadSnapshot: "No se puede leer la instantánea",
            switchToDark: "Cambiar a modo oscuro", switchToLight: "Cambiar a modo claro",
            pin: "Fijar", unpin: "Desfijar", close: "Cerrar ventana", separator: " ",
            afterSuffix: " después", day: { plural($0, "día", "días") }, hour: { plural($0, "hora", "horas") }, minute: { plural($0, "minuto", "minutos") }, second: { plural($0, "segundo", "segundos") })
    }
    if code == "pt" {
        return AppLanguage(title: "Cota Codex", week: "Semana", reset: "Redefinir", availableReset: "Redefinições disponíveis", balance: "Saldo", times: "vezes",
            alreadyReset: "Redefinido", unableToReadSnapshot: "Não foi possível ler o snapshot",
            switchToDark: "Alternar para modo escuro", switchToLight: "Alternar para modo claro",
            pin: "Fixar", unpin: "Desafixar", close: "Fechar janela", separator: " ",
            afterSuffix: " depois", day: { plural($0, "dia", "dias") }, hour: { plural($0, "hora", "horas") }, minute: { plural($0, "minuto", "minutos") }, second: { plural($0, "segundo", "segundos") })
    }
    if code == "it" {
        return AppLanguage(title: "Quota Codex", week: "Settimana", reset: "Ripristino", availableReset: "Ripristini disponibili", balance: "Saldo", times: "volte",
            alreadyReset: "Ripristinato", unableToReadSnapshot: "Impossibile leggere lo snapshot",
            switchToDark: "Passa alla modalità scura", switchToLight: "Passa alla modalità chiara",
            pin: "Fissa", unpin: "Rimuovi fissaggio", close: "Chiudi finestra", separator: " ",
            afterSuffix: " dopo", day: { plural($0, "giorno", "giorni") }, hour: { plural($0, "ora", "ore") }, minute: { plural($0, "minuto", "minuti") }, second: { plural($0, "secondo", "secondi") })
    }
    if code == "nl" {
        return AppLanguage(title: "Codex-limiet", week: "Week", reset: "Reset", availableReset: "Beschikbare resets", balance: "Saldo", times: "keer",
            alreadyReset: "Gereset", unableToReadSnapshot: "Kan snapshot niet lezen",
            switchToDark: "Schakel naar donker", switchToLight: "Schakel naar licht",
            pin: "Vastzetten", unpin: "Losmaken", close: "Venster sluiten", separator: " ",
            afterSuffix: " later", day: { plural($0, "dag", "dagen") }, hour: { plural($0, "uur", "uur") }, minute: { plural($0, "minuut", "minuten") }, second: { plural($0, "seconde", "seconden") })
    }
    return AppLanguage(title: "Codex Quota", week: "Week", reset: "Reset", availableReset: "Available resets", balance: "Balance", times: "times",
        alreadyReset: "Reset", unableToReadSnapshot: "Unable to read snapshot",
        switchToDark: "Switch to dark mode", switchToLight: "Switch to light mode",
        pin: "Pin", unpin: "Unpin", close: "Close window", separator: " ",
        afterSuffix: " later", day: { plural($0, "day", "days") }, hour: { plural($0, "hour", "hours") }, minute: { plural($0, "minute", "minutes") }, second: { plural($0, "second", "seconds") })
}

// MARK: — 时间工具
func secondsUntil(_ timestamp: TimeInterval?) -> Int? {
    guard let t = timestamp, t > 0 else { return nil }
    let date = t > 1_000_000_000_000 ? Date(timeIntervalSince1970: t / 1000) : Date(timeIntervalSince1970: t)
    return Int(ceil(date.timeIntervalSinceNow))
}

func formatCompactDuration(_ interval: Int) -> String {
    let normalized = max(interval, 1)
    let d = normalized / 86400
    let h = (normalized % 86400) / 3600
    let m = (normalized % 3600) / 60
    let s = normalized % 60

    var parts: [String] = []
    if d > 0 { parts.append("\(d)d") }
    if h > 0 { parts.append("\(h)h") }
    if m > 0 { parts.append("\(m)m") }
    if s > 0 || parts.isEmpty { parts.append("\(s)s") }
    return parts.joined(separator: " ")
}

func formatFiveHourReset(_ timestamp: TimeInterval?, language: AppLanguage) -> String {
    guard let rawInterval = secondsUntil(timestamp) else { return "—" }
    if rawInterval <= 0 { return language.alreadyReset }
    return formatCompactDuration(rawInterval)
}

func formatSevenDayReset(_ timestamp: TimeInterval?, language: AppLanguage) -> String {
    guard let interval = secondsUntil(timestamp) else { return "—" }
    if interval <= 0 { return language.alreadyReset }
    return formatCompactDuration(interval)
}

func progressBar(percent: Int, width: Int = 15) -> String {
    let filled = Int(round(Double(percent) / 100.0 * Double(width)))
    let empty = width - filled
    return String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
}

func formatUSDBalanceValue(_ rawBalance: String?) -> String {
    guard let raw = rawBalance?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
        return "—"
    }
    if let value = Double(raw) {
        return String(format: "%.2f", value)
    }
    if raw.hasPrefix("$") {
        return String(raw.dropFirst())
    }
    return raw
}

func planBadgeText(_ planType: String?) -> String {
    switch normalizedPlanType(planType) {
    case "free":
        return "Free"
    case "plus":
        return "Plus"
    case "pro":
        return "Pro"
    case "pro5x":
        return "Pro5x"
    case "pro20x":
        return "Pro20x"
    default:
        return ""
    }
}

func normalizedPlanType(_ planType: String?) -> String? {
    guard let raw = planType?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !raw.isEmpty else {
        return nil
    }
    let compact = raw.replacingOccurrences(of: #"[\s_-]+"#, with: "", options: .regularExpression)
    switch compact {
    case "free":
        return "free"
    case "plus":
        return "plus"
    case "pro":
        return "pro"
    default:
        break
    }
    if compact.contains("20x") || compact.contains("pro20") {
        return "pro20x"
    }
    if compact.contains("5x") || compact.contains("pro5") {
        return "pro5x"
    }
    return nil
}

class MetricCardView: NSView {
    private let highlightLayer = CALayer()
    private let titleLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private var accentColor = NSColor.green
    private var muted = false
    private var lightMode = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 9
        layer?.masksToBounds = false
        layer?.borderWidth = 1
        highlightLayer.cornerRadius = 9
        highlightLayer.masksToBounds = true
        layer?.addSublayer(highlightLayer)

        titleLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .medium)
        titleLabel.backgroundColor = .clear
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.alignment = .center
        addSubview(titleLabel)

        valueLabel.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        valueLabel.backgroundColor = .clear
        valueLabel.isBezeled = false
        valueLabel.isEditable = false
        valueLabel.isSelectable = false
        valueLabel.lineBreakMode = .byTruncatingTail
        valueLabel.alignment = .center
        addSubview(valueLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        highlightLayer.frame = bounds
        titleLabel.frame = NSRect(x: 10, y: 29, width: bounds.width - 20, height: 12)
        valueLabel.frame = NSRect(x: 10, y: 7, width: bounds.width - 20, height: 17)
    }

    func configure(title: String, value: String, symbol: String, accentColor: NSColor, muted: Bool, lightMode: Bool, secondaryTextColor: NSColor) {
        self.accentColor = accentColor
        self.muted = muted
        self.lightMode = lightMode
        titleLabel.stringValue = title
        valueLabel.stringValue = value
        titleLabel.textColor = secondaryTextColor
        applyAppearance(secondaryTextColor: secondaryTextColor)
        needsLayout = true
    }

    func applyAppearance(secondaryTextColor: NSColor) {
        layer?.backgroundColor = (lightMode
            ? NSColor.white.withAlphaComponent(0.42)
            : NSColor.white.withAlphaComponent(0.07)).cgColor
        layer?.borderColor = (lightMode
            ? NSColor.white.withAlphaComponent(0.46)
            : NSColor.white.withAlphaComponent(0.12)).cgColor
        highlightLayer.backgroundColor = (lightMode
            ? NSColor.white.withAlphaComponent(0.18)
            : NSColor.white.withAlphaComponent(0.04)).cgColor
        highlightLayer.borderColor = (lightMode
            ? NSColor.black.withAlphaComponent(0.05)
            : NSColor.black.withAlphaComponent(0.24)).cgColor
        highlightLayer.borderWidth = 1
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = lightMode ? 0.10 : 0.22
        layer?.shadowRadius = 10
        layer?.shadowOffset = NSSize(width: 3, height: -3)
        valueLabel.textColor = lightMode ? NSColor.black : NSColor.white
        titleLabel.textColor = secondaryTextColor
    }
}

// MARK: — 主窗口控制器
class WindowController: NSWindowController, NSWindowDelegate {
    var label: NSTextView!
    var versionLabel: NSTextField!
    var versionUpdateDot: NSView!
    var balanceCardView: MetricCardView!
    var resetCardView: MetricCardView!
    var setupOverlayView: NSView!
    var setupTitleLabel: NSTextField!
    var setupMessageLabel: NSTextField!
    var setupStepLabels: [NSTextField] = []
    var setupStepDots: [NSView] = []
    var setupActionButton: NSButton!
    var rootView: NSView!
    var vibrancyView: NSVisualEffectView!
    var capsuleView: NSView!
    var dividerViews: [NSView] = []
    var controlButtons: [NSButton] = []
    var themeButton: NSButton!
    var pinButton: NSButton!
    var timer: Timer!
    var clickMonitor: Any?
    var lastSnapshotRefresh = Date.distantPast
    var lastGoodSnapshot: UsageSnapshot?
    var snapshotRefreshInFlight = false
    var lastNodeCheck = Date.distantPast
    var cachedNodeAvailable = false
    var lastVersionCheck = Date.distantPast
    var versionCheckInFlight = false
    var cliInstallInFlight = false
    var isPinned = true
    var isLightMode = false
    var language = localizedLanguage()
    var languageIdentity = effectiveLanguageCode()
    let savedFrameKey = "CodexUsageWidget.savedFrame"
    let pinnedKey = "CodexUsageWidget.isPinned"
    let lightModeKey = "CodexUsageWidget.isLightMode"
    let snapshotPath = NSString(string: "~/.codex/codex-usage-snapshot.json").expandingTildeInPath
    let snapshotScriptPath = NSString(string: "~/.codex/scripts/codex-usage-snapshot.mjs").expandingTildeInPath
    let closedMarkerPath = NSString(string: "~/.codex/usage-widget/.closed-by-user").expandingTildeInPath
    let codexHomePath = NSString(string: "~/.codex").expandingTildeInPath
    let codexAuthPath = NSString(string: "~/.codex/auth.json").expandingTildeInPath

    enum SetupIssue {
        case ready
        case missingNode
        case missingCli
        case missingLogin
        case waitingForSnapshot
        case installing
        case installFailed
    }

    convenience init() {
        let w: CGFloat = 330
        let h: CGFloat = 240
        let contentRect = NSRect(x: 0, y: 0, width: w, height: h)

        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.minSize = NSSize(width: w, height: 200)
        panel.maxSize = NSSize(width: w, height: 1000)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        self.init(window: panel)

        rootView = NSView(frame: contentRect)
        rootView.autoresizingMask = [.width, .height]
        rootView.wantsLayer = true
        rootView.layer?.cornerRadius = 12
        rootView.layer?.masksToBounds = true

        vibrancyView = NSVisualEffectView(frame: contentRect)
        vibrancyView.autoresizingMask = [.width, .height]
        vibrancyView.material = .hudWindow
        vibrancyView.blendingMode = .withinWindow
        vibrancyView.state = .active
        vibrancyView.wantsLayer = true
        vibrancyView.layer?.cornerRadius = 12
        vibrancyView.layer?.masksToBounds = true
        rootView.addSubview(vibrancyView)

        label = NSTextView(frame: NSRect(x: 12, y: 78, width: w - 24, height: h - 94))
        label.autoresizingMask = [.width, .height]
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.textContainerInset = NSSize(width: 0, height: 0)
        label.textContainer?.lineFragmentPadding = 0
        label.backgroundColor = NSColor.clear
        rootView.addSubview(label)

        balanceCardView = MetricCardView(frame: NSRect(x: 12, y: 38, width: 131, height: 47))
        balanceCardView.autoresizingMask = [.maxXMargin, .maxYMargin]
        rootView.addSubview(balanceCardView)

        resetCardView = MetricCardView(frame: NSRect(x: 153, y: 38, width: 131, height: 47))
        resetCardView.autoresizingMask = [.minXMargin, .maxYMargin]
        rootView.addSubview(resetCardView)

        let versionText = appVersionText()
        let versionFont = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        versionLabel = NSTextField(labelWithString: versionText)
        versionLabel.frame = NSRect(x: w - 82, y: 8, width: 68, height: 16)
        versionLabel.autoresizingMask = [.minXMargin, .maxYMargin]
        versionLabel.alignment = .right
        versionLabel.font = versionFont
        versionLabel.textColor = secondaryTextColor
        versionLabel.backgroundColor = NSColor.clear
        versionLabel.isBezeled = false
        versionLabel.isEditable = false
        versionLabel.isSelectable = false
        rootView.addSubview(versionLabel)

        let versionTextWidth = ceil((versionText as NSString).size(withAttributes: [.font: versionFont]).width)
        let dotSize: CGFloat = 4
        let dotGap: CGFloat = 4
        let dotX = versionLabel.frame.maxX - versionTextWidth - dotGap - dotSize
        let dotY = versionLabel.frame.midY - dotSize / 2 + 1
        versionUpdateDot = NSView(frame: NSRect(x: dotX, y: dotY, width: dotSize, height: dotSize))
        versionUpdateDot.autoresizingMask = [.minXMargin, .maxYMargin]
        versionUpdateDot.wantsLayer = true
        versionUpdateDot.layer?.cornerRadius = 2
        versionUpdateDot.layer?.masksToBounds = true
        versionUpdateDot.layer?.backgroundColor = NSColor.systemRed.cgColor
        versionUpdateDot.isHidden = true
        rootView.addSubview(versionUpdateDot)

        setupOverlayView = makeSetupOverlay(frame: contentRect)
        setupOverlayView.autoresizingMask = [.width, .height]
        setupOverlayView.isHidden = true
        rootView.addSubview(setupOverlayView)

        let controls = makeControlCapsule(frame: NSRect(x: w - 125, y: h - 38, width: 111, height: 28))
        controls.autoresizingMask = [.minXMargin, .minYMargin]
        rootView.addSubview(controls)

        panel.contentView = rootView

        loadUserPreferences()
        applyTheme()
        applyPinnedState()

        if let savedFrame = restoredFrame(defaultSize: NSSize(width: w, height: h)) {
            panel.setFrame(savedFrame, display: true)
        } else {
            // 窗口位置：右上角，留出菜单栏空间
            if let screen = NSScreen.main?.visibleFrame {
                let x = screen.maxX - w - 20
                let y = screen.maxY - h - 30  // 更靠近顶部，在菜单栏下方
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            } else {
                // fallback
                panel.setFrameOrigin(NSPoint(x: 980, y: 700))
            }
        }

        panel.delegate = self
        installClickActivationMonitor()
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
        refreshVersionUpdateStatus(force: true)
    }

    func installClickActivationMonitor() {
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            self.activateLauncherMenu()
            return event
        }
    }

    func activateLauncherMenu() {
        let bundleIdentifier = "local.codex.usage-widget.launcher"
        if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            app.activate(options: [.activateAllWindows])
            return
        }

        let launcherPath = NSString(string: "~/Applications/Quota Bubble.app").expandingTildeInPath
        let launcherURL = URL(fileURLWithPath: launcherPath)
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.openApplication(at: launcherURL, configuration: configuration)
    }

    func makeControlCapsule(frame: NSRect) -> NSView {
        let capsule = NSView(frame: frame)
        capsuleView = capsule
        capsule.wantsLayer = true
        capsule.layer?.cornerRadius = frame.height / 2
        capsule.layer?.masksToBounds = true
        capsule.layer?.borderWidth = 1

        let segmentWidth = frame.width / 3
        for index in 1...2 {
            let divider = NSView(frame: NSRect(x: segmentWidth * CGFloat(index), y: 6, width: 1, height: frame.height - 12))
            divider.wantsLayer = true
            dividerViews.append(divider)
            capsule.addSubview(divider)
        }

        themeButton = makeCapsuleButton(frame: NSRect(x: 0, y: 0, width: segmentWidth, height: frame.height),
                                        symbolName: "circle.lefthalf.filled",
                                        fallbackTitle: "◐",
                                        action: #selector(toggleTheme))
        themeButton.toolTip = isLightMode ? language.switchToDark : language.switchToLight
        capsule.addSubview(themeButton)

        pinButton = makeCapsuleButton(frame: NSRect(x: segmentWidth, y: 0, width: segmentWidth, height: frame.height),
                                      symbolName: "pin.fill",
                                      fallbackTitle: "P",
                                      action: #selector(togglePinned))
        pinButton.toolTip = isPinned ? language.unpin : language.pin
        capsule.addSubview(pinButton)

        let closeButton = makeCapsuleButton(frame: NSRect(x: segmentWidth * 2, y: 0, width: segmentWidth, height: frame.height),
                                            symbolName: "xmark",
                                            fallbackTitle: "x",
                                            action: #selector(closeFromButton))
        closeButton.toolTip = language.close
        capsule.addSubview(closeButton)

        return capsule
    }

    func makeCapsuleButton(frame: NSRect, symbolName: String, fallbackTitle: String, action: Selector) -> NSButton {
        let button = NSButton(frame: frame)
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.title = ""
        button.target = self
        button.action = action
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.clear.cgColor
        controlButtons.append(button)
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
        } else {
            button.title = fallbackTitle
            button.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        }
        return button
    }

    func makeSetupOverlay(frame: NSRect) -> NSView {
        let overlay = NSView(frame: frame)
        overlay.wantsLayer = true
        overlay.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.64).cgColor
        overlay.layer?.cornerRadius = 12
        overlay.layer?.masksToBounds = true

        let panel = NSView(frame: NSRect(x: 18, y: 36, width: frame.width - 36, height: 158))
        panel.autoresizingMask = [.width, .minYMargin, .maxYMargin]
        panel.wantsLayer = true
        panel.layer?.cornerRadius = 12
        panel.layer?.backgroundColor = NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.11, alpha: 0.92).cgColor
        panel.layer?.borderWidth = 1
        panel.layer?.borderColor = NSColor.white.withAlphaComponent(0.14).cgColor
        panel.layer?.shadowColor = NSColor.black.cgColor
        panel.layer?.shadowOpacity = 0.28
        panel.layer?.shadowRadius = 18
        panel.layer?.shadowOffset = NSSize(width: 0, height: -8)
        overlay.addSubview(panel)

        setupTitleLabel = NSTextField(labelWithString: "")
        setupTitleLabel.frame = NSRect(x: 18, y: 118, width: panel.frame.width - 36, height: 22)
        setupTitleLabel.autoresizingMask = [.width, .minYMargin]
        setupTitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .bold)
        setupTitleLabel.textColor = NSColor.white
        setupTitleLabel.backgroundColor = .clear
        setupTitleLabel.isBezeled = false
        setupTitleLabel.isEditable = false
        setupTitleLabel.isSelectable = false
        panel.addSubview(setupTitleLabel)

        setupMessageLabel = NSTextField(labelWithString: "")
        setupMessageLabel.frame = NSRect(x: 18, y: 78, width: panel.frame.width - 36, height: 38)
        setupMessageLabel.autoresizingMask = [.width, .minYMargin]
        setupMessageLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        setupMessageLabel.textColor = NSColor.white.withAlphaComponent(0.72)
        setupMessageLabel.backgroundColor = .clear
        setupMessageLabel.isBezeled = false
        setupMessageLabel.isEditable = false
        setupMessageLabel.isSelectable = false
        setupMessageLabel.maximumNumberOfLines = 2
        setupMessageLabel.lineBreakMode = .byWordWrapping
        panel.addSubview(setupMessageLabel)

        let steps = ["安装 CLI", "完成登录", "同步配额"]
        for (index, step) in steps.enumerated() {
            let x = CGFloat(18 + index * 84)
            let dot = NSView(frame: NSRect(x: x, y: 53, width: 7, height: 7))
            dot.wantsLayer = true
            dot.layer?.cornerRadius = 3.5
            dot.layer?.masksToBounds = true
            panel.addSubview(dot)
            setupStepDots.append(dot)

            let stepLabel = NSTextField(labelWithString: step)
            stepLabel.frame = NSRect(x: x + 12, y: 47, width: 66, height: 18)
            stepLabel.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
            stepLabel.textColor = NSColor.white.withAlphaComponent(0.62)
            stepLabel.backgroundColor = .clear
            stepLabel.isBezeled = false
            stepLabel.isEditable = false
            stepLabel.isSelectable = false
            panel.addSubview(stepLabel)
            setupStepLabels.append(stepLabel)
        }

        setupActionButton = NSButton(frame: NSRect(x: panel.frame.width - 108, y: 14, width: 90, height: 28))
        setupActionButton.autoresizingMask = [.minXMargin, .maxYMargin]
        setupActionButton.isBordered = false
        setupActionButton.bezelStyle = .regularSquare
        setupActionButton.wantsLayer = true
        setupActionButton.layer?.cornerRadius = 8
        setupActionButton.layer?.masksToBounds = true
        setupActionButton.layer?.backgroundColor = NSColor(calibratedRed: 0.05, green: 0.42, blue: 0.14, alpha: 0.72).cgColor
        setupActionButton.layer?.borderWidth = 1
        setupActionButton.layer?.borderColor = NSColor(calibratedRed: 0.12, green: 0.95, blue: 0.22, alpha: 0.62).cgColor
        setupActionButton.font = NSFont.systemFont(ofSize: 11, weight: .semibold)
        setupActionButton.target = self
        setupActionButton.action = #selector(installCodexCliFromOverlay)
        panel.addSubview(setupActionButton)

        return overlay
    }

    func codexCliPath() -> String? {
        let candidates = [
            "~/.local/bin/codex",
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            "/usr/bin/codex",
        ].map { NSString(string: $0).expandingTildeInPath }
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func codexCliAvailable() -> Bool {
        codexCliPath() != nil
    }

    func nodeAvailable() -> Bool {
        if Date().timeIntervalSince(lastNodeCheck) < 5 {
            return cachedNodeAvailable
        }
        lastNodeCheck = Date()

        let candidates = [
            "/opt/homebrew/bin/node",
            "/usr/local/bin/node",
            "/usr/bin/node",
        ]
        if candidates.contains(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
            cachedNodeAvailable = true
            return true
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", "command -v node >/dev/null 2>&1"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            cachedNodeAvailable = process.terminationStatus == 0
        } catch {
            cachedNodeAvailable = false
        }
        return cachedNodeAvailable
    }

    func hasCodexSessionData() -> Bool {
        let dirs = [
            NSString(string: "~/.codex/sessions").expandingTildeInPath,
            NSString(string: "~/.codex/archived_sessions").expandingTildeInPath,
        ]
        for dir in dirs {
            guard let enumerator = FileManager.default.enumerator(atPath: dir) else { continue }
            for case let file as String in enumerator {
                if file.hasSuffix(".jsonl") { return true }
            }
        }
        return false
    }

    func currentSetupIssue() -> SetupIssue {
        if cliInstallInFlight { return .installing }
        if !nodeAvailable() { return .missingNode }
        if !codexCliAvailable() { return .missingCli }
        if !FileManager.default.fileExists(atPath: codexAuthPath) && !hasCodexSessionData() {
            return .missingLogin
        }
        if !FileManager.default.fileExists(atPath: snapshotPath) {
            return .waitingForSnapshot
        }
        return .ready
    }

    func setupText(for issue: SetupIssue) -> (title: String, message: String, button: String) {
        let zh = effectiveLanguageCode() == "zh"
        switch issue {
        case .ready:
            return ("", "", "")
        case .missingNode:
            return zh
                ? ("需要安装 Node.js", "Quota Bubble 需要 Node.js 运行本地同步脚本。点击安装后会优先通过 Homebrew 安装。", "安装")
                : ("Node.js required", "Quota Bubble needs Node.js to run the local sync script. Click install to install with Homebrew when available.", "Install")
        case .missingCli:
            return zh
                ? ("需要安装 Codex CLI", "Quota Bubble 需要 Codex CLI 创建本地数据目录，安装后会自动重新检测。", "安装")
                : ("Codex CLI required", "Quota Bubble needs Codex CLI to create local Codex data. It will recheck automatically after install.", "Install")
        case .missingLogin:
            return zh
                ? ("需要登录 Codex CLI", "已检测到 CLI，但还没有本地登录数据。请完成 codex login 后等待自动同步。", "打开登录")
                : ("Codex CLI login required", "CLI is installed, but local login data is missing. Run codex login, then the widget will sync automatically.", "Log in")
        case .waitingForSnapshot:
            return zh
                ? ("正在同步配额", "本地配额快照还没有生成。工具会自动重试，Codex CLI 登录完成后会恢复显示。", "重试")
                : ("Syncing quota", "The local quota snapshot has not been created yet. The widget will keep retrying after Codex CLI login is ready.", "Retry")
        case .installing:
            return zh
                ? ("正在安装 Codex CLI", "正在通过官方安装脚本安装。完成后会自动检测本地数据是否可用。", "安装中")
                : ("Installing Codex CLI", "Installing with the official script. The widget will recheck local data when it finishes.", "Installing")
        case .installFailed:
            return zh
                ? ("安装未完成", "无法自动安装 Codex CLI。请检查网络后重试，或在终端手动安装。", "重试")
                : ("Install did not finish", "Could not install Codex CLI automatically. Check your network and retry, or install it from Terminal.", "Retry")
        }
    }

    func updateSetupOverlay(_ forcedIssue: SetupIssue? = nil) {
        let issue = forcedIssue ?? currentSetupIssue()
        if issue == .ready {
            setupOverlayView?.isHidden = true
            setupActionButton?.isEnabled = true
            return
        }

        let copy = setupText(for: issue)
        setupTitleLabel.stringValue = copy.title
        setupMessageLabel.stringValue = copy.message
        setupActionButton.isEnabled = issue != .installing
        setupActionButton.alphaValue = issue == .installing ? 0.58 : 1
        setupActionButton.attributedTitle = NSAttributedString(
            string: copy.button,
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: NSColor(calibratedRed: 0.25, green: 1, blue: 0.34, alpha: 1),
            ]
        )
        setupOverlayView.isHidden = false

        let steps = effectiveLanguageCode() == "zh"
            ? ["安装 CLI", "完成登录", "同步配额"]
            : ["Install CLI", "Log in", "Sync quota"]
        for index in setupStepLabels.indices {
            setupStepLabels[index].stringValue = steps[index]
        }

        let activeIndex: Int
        switch issue {
        case .missingNode, .missingCli, .installing, .installFailed:
            activeIndex = 0
        case .missingLogin:
            activeIndex = 1
        case .waitingForSnapshot, .ready:
            activeIndex = 2
        }

        for index in setupStepDots.indices {
            let completed = index < activeIndex
            let active = index == activeIndex
            let failed = issue == .installFailed && index == 0
            let color: NSColor
            if failed {
                color = NSColor.systemRed
            } else if completed {
                color = NSColor.green
            } else if active {
                color = NSColor(calibratedRed: 0.12, green: 0.95, blue: 0.22, alpha: 1)
            } else {
                color = NSColor.white.withAlphaComponent(0.22)
            }
            setupStepDots[index].layer?.backgroundColor = color.cgColor
            setupStepLabels[index].textColor = (completed || active)
                ? NSColor.white.withAlphaComponent(0.86)
                : NSColor.white.withAlphaComponent(0.44)
        }
    }

    @objc func installCodexCliFromOverlay() {
        let issue = currentSetupIssue()
        if issue == .missingNode {
            installNodeFromOverlay()
            updateSetupOverlay()
            return
        }
        if issue == .missingLogin {
            openCodexLoginInTerminal()
            updateSetupOverlay()
            return
        }
        if issue == .waitingForSnapshot {
            refreshSnapshotIfNeeded(force: true, redrawAfterCompletion: true)
            updateSetupOverlay()
            return
        }

        cliInstallInFlight = true
        updateSetupOverlay(.installing)

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
            } catch {
                success = false
            }

            DispatchQueue.main.async {
                guard let self else { return }
                self.cliInstallInFlight = false
                if success {
                    self.refreshSnapshotIfNeeded(force: true, redrawAfterCompletion: true)
                    self.updateSetupOverlay()
                } else {
                    self.updateSetupOverlay(.installFailed)
                }
            }
        }
    }

    func openCodexLoginInTerminal() {
        let command = "\(shellQuoted(codexCliPath() ?? "codex")) login"
        let script = """
        tell application "Terminal"
            activate
            do script "\(command)"
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    func homebrewPath() -> String? {
        let candidates = [
            "/opt/homebrew/bin/brew",
            "/usr/local/bin/brew",
        ]
        return candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    func installNodeFromOverlay() {
        guard let brew = homebrewPath() else {
            if let url = URL(string: "https://nodejs.org/") {
                NSWorkspace.shared.open(url)
            }
            return
        }

        let command = "\(shellQuoted(brew)) install node; echo; echo 'Node.js install finished. Quota Bubble will recheck automatically.'"
        let script = """
        tell application "Terminal"
            activate
            do script "\(command)"
        end tell
        """
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    var primaryTextColor: NSColor {
        isLightMode ? NSColor.black : NSColor.white
    }

    var secondaryTextColor: NSColor {
        isLightMode ? NSColor.black.withAlphaComponent(0.64) : NSColor.white.withAlphaComponent(0.72)
    }

    var controlTintColor: NSColor {
        isLightMode ? NSColor.black.withAlphaComponent(0.70) : NSColor.white.withAlphaComponent(0.76)
    }

    func applyTheme() {
        rootView?.layer?.backgroundColor = isLightMode
            ? NSColor.white.withAlphaComponent(0.78).cgColor
            : NSColor.black.withAlphaComponent(0.78).cgColor
        vibrancyView?.appearance = NSAppearance(named: isLightMode ? .vibrantLight : .vibrantDark)
        capsuleView?.layer?.backgroundColor = (isLightMode
            ? NSColor.black.withAlphaComponent(0.04)
            : NSColor.white.withAlphaComponent(0.04)).cgColor
        capsuleView?.layer?.borderColor = (isLightMode
            ? NSColor.black.withAlphaComponent(0.14)
            : NSColor.white.withAlphaComponent(0.16)).cgColor
        for divider in dividerViews {
            divider.layer?.backgroundColor = (isLightMode
                ? NSColor.black.withAlphaComponent(0.14)
                : NSColor.white.withAlphaComponent(0.16)).cgColor
        }
        for button in controlButtons {
            button.contentTintColor = controlTintColor
        }
        balanceCardView?.applyAppearance(secondaryTextColor: secondaryTextColor)
        resetCardView?.applyAppearance(secondaryTextColor: secondaryTextColor)
        versionLabel?.textColor = secondaryTextColor
        versionUpdateDot?.layer?.backgroundColor = NSColor.systemRed.cgColor
        if let image = NSImage(systemSymbolName: isLightMode ? "moon.fill" : "sun.max.fill", accessibilityDescription: nil) {
            image.isTemplate = true
            themeButton?.image = image
        }
        themeButton?.toolTip = isLightMode ? language.switchToDark : language.switchToLight
    }

    func applyPinnedState() {
        guard let panel = window as? NSPanel else { return }
        panel.isFloatingPanel = isPinned
        panel.level = isPinned ? .statusBar : .normal
        if let image = NSImage(systemSymbolName: isPinned ? "pin.fill" : "pin.slash", accessibilityDescription: nil) {
            image.isTemplate = true
            pinButton?.image = image
        }
        pinButton?.toolTip = isPinned ? language.unpin : language.pin
    }

    func loadUserPreferences() {
        let defaults = UserDefaults.standard
        isLightMode = defaults.object(forKey: lightModeKey) as? Bool ?? false
        isPinned = defaults.object(forKey: pinnedKey) as? Bool ?? true
    }

    func saveUserPreferences() {
        let defaults = UserDefaults.standard
        defaults.set(isLightMode, forKey: lightModeKey)
        defaults.set(isPinned, forKey: pinnedKey)
        defaults.synchronize()
    }

    @objc func togglePinned() {
        isPinned.toggle()
        saveUserPreferences()
        applyPinnedState()
    }

    @objc func toggleTheme() {
        isLightMode.toggle()
        saveUserPreferences()
        applyTheme()
        refresh()
    }

    @objc func closeFromButton() {
        saveWindowFrame()
        FileManager.default.createFile(atPath: closedMarkerPath, contents: nil)
        NSApp.terminate(nil)
    }

    func restoredFrame(defaultSize: NSSize) -> NSRect? {
        guard let raw = UserDefaults.standard.string(forKey: savedFrameKey) else { return nil }
        var frame = NSRectFromString(raw)
        guard frame.width > 100, frame.height > 80 else { return nil }
        if frame.width.isNaN || frame.height.isNaN || frame.origin.x.isNaN || frame.origin.y.isNaN {
            return nil
        }
        if frame.width <= 0 || frame.height <= 0 {
            frame.size = defaultSize
        }
        let savedTop = frame.maxY
        frame.size = defaultSize
        frame.origin.y = savedTop - defaultSize.height

        let isVisible = NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }
        return isVisible ? frame : nil
    }

    func saveWindowFrame() {
        guard let window else { return }
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: savedFrameKey)
    }

    func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }

    func windowDidResize(_ notification: Notification) {
        saveWindowFrame()
    }

    func windowWillClose(_ notification: Notification) {
        saveWindowFrame()
    }

    func startRefresh() {
        updateSetupOverlay()
        refreshSnapshotIfNeeded(force: true, redrawAfterCompletion: true)
        renderSnapshot()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        reloadLanguageIfNeeded()
        updateSetupOverlay()
        refreshVersionUpdateStatus()
        refreshSnapshotIfNeeded(redrawAfterCompletion: true)
        renderSnapshot()
    }

    func refreshVersionUpdateStatus(force: Bool = false) {
        if versionCheckInFlight { return }
        if !force, Date().timeIntervalSince(lastVersionCheck) < 1800 { return }
        versionCheckInFlight = true
        lastVersionCheck = Date()

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let latestVersion = Self.fetchLatestReleaseTag()
            let current = Self.normalizedVersion(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String)
            let latest = Self.normalizedVersion(latestVersion)
            let hasUpdate: Bool
            if let current, let latest {
                hasUpdate = Self.compareVersions(current, latest) == .orderedAscending
            } else {
                hasUpdate = false
            }

            DispatchQueue.main.async {
                guard let self else { return }
                self.versionCheckInFlight = false
                self.versionUpdateDot?.isHidden = !hasUpdate
            }
        }
    }

    static func fetchLatestReleaseTag() -> String? {
        guard let url = URL(string: "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["tag_name"] as? String
    }

    static func normalizedVersion(_ value: String?) -> [Int]? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let version = trimmed.hasPrefix("v") ? String(trimmed.dropFirst()) : trimmed
        let parts = version.split(separator: ".")
        guard !parts.isEmpty else { return nil }

        var numbers: [Int] = []
        for part in parts {
            let digits = part.prefix { $0.isNumber }
            guard let number = Int(digits) else { return nil }
            numbers.append(number)
        }
        return numbers
    }

    static func compareVersions(_ lhs: [Int], _ rhs: [Int]) -> ComparisonResult {
        let count = max(lhs.count, rhs.count)
        for index in 0..<count {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left > right { return .orderedDescending }
            if left < right { return .orderedAscending }
        }
        return .orderedSame
    }

    func reloadLanguageIfNeeded() {
        let identity = effectiveLanguageCode()
        guard identity != languageIdentity else { return }
        languageIdentity = identity
        language = localizedLanguage()
        themeButton?.toolTip = isLightMode ? language.switchToDark : language.switchToLight
        pinButton?.toolTip = isPinned ? language.unpin : language.pin
        refresh()
    }

    func renderSnapshot() {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: snapshotPath)),
              let snap = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else {
            if let lastGoodSnapshot {
                render(lastGoodSnapshot)
            } else {
                updateSetupOverlay()
            }
            return
        }

        lastGoodSnapshot = snap
        render(snap)
    }

    func render(_ snap: UsageSnapshot) {
        let five = snap.five_hour

        let fivePct = remainingPercent(fromUsedPercent: five?.used_percentage)
        let fiveReset = formatFiveHourReset(five?.resets_at, language: language)
        let resetCredits = snap.reset_credits?.available_count
        let resetExpirationRows = formattedResetExpirationRows(snap.reset_credits)
        let balance = formatUSDBalanceValue(snap.balance_usd)
        let resetText = resetCredits.map { "\($0)" } ?? "—"
        let hasResetCredits = (resetCredits ?? 0) > 0
        balanceCardView.configure(
            title: "\(language.balance)（$）",
            value: balance,
            symbol: "$",
            accentColor: NSColor.green,
            muted: balance == "—",
            lightMode: isLightMode,
            secondaryTextColor: secondaryTextColor
        )
        resetCardView.configure(
            title: "\(language.availableReset)（\(language.times)）",
            value: resetText,
            symbol: "R",
            accentColor: NSColor.green,
            muted: !hasResetCredits,
            lightMode: isLightMode,
            secondaryTextColor: secondaryTextColor
        )

        let emptyBar = String(repeating: "░", count: 15)
        let fiveBar = fivePct >= 0 ? progressBar(percent: fivePct) : emptyBar

        adjustWindowHeight(forResetExpirationCount: resetExpirationRows.count)

        buildAttributedText(
            planType: snap.plan_type,
            fiveBar: fiveBar, fivePct: fivePct, fiveReset: fiveReset,
            resetExpirationRows: resetExpirationRows
        )
    }

    func formattedResetExpirationRows(_ credits: ResetCredits?) -> [String] {
        let rawValues = credits?.expires_at ?? []
        let expectedCount = max(0, credits?.available_count ?? rawValues.count)
        guard expectedCount > 0 else { return [] }

        let fractionalFormatter = ISO8601DateFormatter()
        fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let standardFormatter = ISO8601DateFormatter()
        standardFormatter.formatOptions = [.withInternetDateTime]
        let displayFormatter = DateFormatter()
        displayFormatter.locale = Locale(identifier: languageIdentity)
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short

        return (0..<expectedCount).map { index in
            guard index < rawValues.count else { return "\(language.reset) \(index + 1)  —" }
            let rawValue = rawValues[index]
            let date = fractionalFormatter.date(from: rawValue) ?? standardFormatter.date(from: rawValue)
            let displayValue = date.map(displayFormatter.string(from:)) ?? rawValue
            return "\(language.reset) \(index + 1)  \(displayValue)"
        }
    }

    func adjustWindowHeight(forResetExpirationCount count: Int) {
        guard let window else { return }
        let desiredHeight = min(window.maxSize.height, 200 + CGFloat(count) * 17)
        guard abs(window.frame.height - desiredHeight) >= 0.5 else { return }

        var frame = window.frame
        let top = frame.maxY
        frame.size = NSSize(width: 330, height: desiredHeight)
        frame.origin.y = top - desiredHeight
        window.setFrame(frame, display: true, animate: false)
    }

    func refreshSnapshotIfNeeded(force: Bool = false, redrawAfterCompletion: Bool = false) {
        guard !snapshotRefreshInFlight,
              (force || -lastSnapshotRefresh.timeIntervalSinceNow >= 1),
              FileManager.default.fileExists(atPath: snapshotScriptPath) else { return }

        snapshotRefreshInFlight = true
        lastSnapshotRefresh = Date()

        DispatchQueue.global(qos: .utility).async { [scriptPath = snapshotScriptPath, outputPath = snapshotPath, weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["node", scriptPath, outputPath]
            process.environment = [
                "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/homebrew/sbin:/usr/sbin"
            ]
            process.standardOutput = Pipe()
            process.standardError = Pipe()

            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus != 0 {
                    let fallback = Process()
                    fallback.executableURL = URL(fileURLWithPath: "/bin/zsh")
                    fallback.arguments = ["-lc", "node \"\(scriptPath)\" \"\(outputPath)\""]
                    fallback.standardOutput = Pipe()
                    fallback.standardError = Pipe()
                    try? fallback.run()
                    fallback.waitUntilExit()
                }
            } catch {
                let fallback = Process()
                fallback.executableURL = URL(fileURLWithPath: "/bin/zsh")
                fallback.arguments = ["-lc", "node \"\(scriptPath)\" \"\(outputPath)\""]
                fallback.standardOutput = Pipe()
                fallback.standardError = Pipe()
                try? fallback.run()
                fallback.waitUntilExit()
            }

            DispatchQueue.main.async {
                guard let self else { return }
                self.snapshotRefreshInFlight = false
                if redrawAfterCompletion {
                    self.renderSnapshot()
                }
            }
        }
    }

    func buildAttributedText(planType: String?,
                             fiveBar: String, fivePct: Int, fiveReset: String,
                             resetExpirationRows: [String]) {
        func fixedParagraph(height: CGFloat, spacing: CGFloat = 0) -> NSMutableParagraphStyle {
            let style = NSMutableParagraphStyle()
            style.minimumLineHeight = height
            style.maximumLineHeight = height
            style.paragraphSpacing = spacing
            return style
        }
        func attrs(font: NSFont, color: NSColor, lineHeight: CGFloat, spacing: CGFloat = 0, baseline: CGFloat = 0) -> [NSAttributedString.Key: Any] {
            var value: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: fixedParagraph(height: lineHeight, spacing: spacing)
            ]
            if baseline != 0 {
                value[.baselineOffset] = baseline
            }
            return value
        }
        func textWidth(_ text: String, font: NSFont) -> CGFloat {
            (text as NSString).size(withAttributes: [.font: font]).width
        }
        func ellipsized(_ text: String, font: NSFont, maxWidth: CGFloat) -> String {
            guard textWidth(text, font: font) > maxWidth else { return text }

            let ellipsis = "…"
            var low = 0
            var high = text.count
            let characters = Array(text)
            while low < high {
                let mid = (low + high + 1) / 2
                let candidate = String(characters.prefix(mid)) + ellipsis
                if textWidth(candidate, font: font) <= maxWidth {
                    low = mid
                } else {
                    high = mid - 1
                }
            }
            return String(characters.prefix(max(0, low))) + ellipsis
        }
        func badgeAttachment(text: String, font: NSFont, alignTo alignFont: NSFont, backgroundColor: NSColor, textColor: NSColor) -> NSTextAttachment {
            let horizontalPadding: CGFloat = 7
            let height: CGFloat = 16
            let width = ceil(textWidth(text, font: font) + horizontalPadding * 2)
            let image = NSImage(size: NSSize(width: width, height: height))
            image.lockFocus()
            backgroundColor.setFill()
            NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: width, height: height), xRadius: 2, yRadius: 2).fill()
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            let textSize = (text as NSString).size(withAttributes: attributes)
            (text as NSString).draw(at: NSPoint(x: (width - textSize.width) / 2, y: (height - textSize.height) / 2 + 0.5), withAttributes: attributes)
            image.unlockFocus()

            let attachment = NSTextAttachment()
            attachment.image = image
            let alignedCenter = (alignFont.ascender + alignFont.descender) / 2
            attachment.bounds = NSRect(x: 0, y: round(alignedCenter - height / 2), width: width, height: height)
            return attachment
        }
        func barAttachment(percent: Int, font: NSFont, color: NSColor) -> NSTextAttachment {
            let widthChars = 15
            let height: CGFloat = 20
            let normalizedPercent = min(100, max(0, percent))
            let filledChars = Int(round(Double(normalizedPercent) / 100.0 * Double(widthChars)))
            let fullBar = String(repeating: "█", count: widthChars)
            let barWidth = ceil(textWidth(fullBar, font: font))
            let charWidth = barWidth / CGFloat(widthChars)
            let filledWidth = charWidth * CGFloat(filledChars)
            let image = NSImage(size: NSSize(width: barWidth, height: height))
            image.lockFocus()

            color.setFill()
            NSBezierPath(rect: NSRect(x: 0, y: 0, width: filledWidth, height: height)).fill()
            let separatorColor = (color.blended(withFraction: 0.28, of: NSColor.black) ?? color).withAlphaComponent(0.45)
            separatorColor.setFill()
            let separatorWidth: CGFloat = 0.6
            for segment in 1..<5 {
                let x = barWidth * CGFloat(segment) / 5
                NSBezierPath(rect: NSRect(x: x, y: 0, width: separatorWidth, height: height)).fill()
            }
            if filledChars < widthChars {
                let emptyText = String(repeating: "░", count: widthChars - filledChars)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color
                ]
                let textSize = (emptyText as NSString).size(withAttributes: attributes)
                (emptyText as NSString).draw(
                    at: NSPoint(x: filledWidth, y: (height - textSize.height) / 2),
                    withAttributes: attributes
                )
            }
            image.unlockFocus()

            let attachment = NSTextAttachment()
            attachment.image = image
            let alignedCenter = (font.ascender + font.descender) / 2
            attachment.bounds = NSRect(x: 0, y: round(alignedCenter - height / 2), width: barWidth, height: height)
            return attachment
        }
        let titleFont = NSFont.systemFont(ofSize: 15, weight: .bold)
        let planFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
        let planBadge = planBadgeText(planType)
        let planColor: NSColor
        let planTextColor: NSColor
        let planStyle = normalizedPlanType(planBadge) ?? normalizedPlanType(planType)
        switch planStyle {
        case "plus":
            planColor = NSColor(calibratedRed: 0.0, green: 0.72, blue: 0.08, alpha: 1.0)
            planTextColor = NSColor.white
        case "pro", "pro5x", "pro20x":
            planColor = NSColor.systemOrange
            planTextColor = NSColor.white
        default:
            planColor = NSColor.systemGray
            planTextColor = NSColor.white
        }
        let title = attrs(font: titleFont,
                          color: primaryTextColor, lineHeight: 18, spacing: 20)
        let rowLabelFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .bold)
        let separatorFont = NSFont.monospacedSystemFont(ofSize: 8, weight: .bold)
        let dimFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let percent = attrs(font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                            color: primaryTextColor, lineHeight: 20)
        let barFont = NSFont.monospacedSystemFont(ofSize: 20, weight: .regular)
        let barBottomSpacer = attrs(font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                                    color: NSColor.clear, lineHeight: 10)
        let barTopSpacer = attrs(font: NSFont.monospacedSystemFont(ofSize: 4, weight: .regular),
                                 color: NSColor.clear, lineHeight: 4)
        let dim = attrs(font: dimFont, color: secondaryTextColor, lineHeight: 16)
        let rowLabel = attrs(font: rowLabelFont, color: primaryTextColor, lineHeight: 16)
        let separator = attrs(font: separatorFont,
                              color: secondaryTextColor, lineHeight: 16, baseline: 2.0)
        let planBadgeWidth = planBadge.isEmpty ? 0 : ceil(textWidth(planBadge, font: planFont) + 14)
        let titleRowMaxWidth: CGFloat = 184
        let titlePlanGap: CGFloat = planBadge.isEmpty ? 0 : 5
        let titleMaxWidth = max(20, titleRowMaxWidth - planBadgeWidth - titlePlanGap)
        let titleText = ellipsized(language.title, font: titleFont, maxWidth: titleMaxWidth)
        let fiveLabel = language.week
        let fiveSeparator = "  ┃  "
        let rowPadding: CGFloat = 2
        let fiveResetMaxWidth = max(80, label.bounds.width - textWidth(fiveLabel, font: rowLabelFont) - textWidth(fiveSeparator, font: separatorFont) - rowPadding)
        let fiveResetText = ellipsized("\(language.reset) \(fiveReset)", font: dimFont, maxWidth: fiveResetMaxWidth)
        let expirationRow = attrs(font: dimFont, color: secondaryTextColor, lineHeight: 17)

        let mas = NSMutableAttributedString()
        mas.append(NSAttributedString(string: titleText, attributes: title))
        if !planBadge.isEmpty {
            mas.append(NSAttributedString(string: " ", attributes: title))
            mas.append(NSAttributedString(attachment: badgeAttachment(text: planBadge, font: planFont, alignTo: titleFont, backgroundColor: planColor, textColor: planTextColor)))
        }
        mas.append(NSAttributedString(string: "\n", attributes: title))
        mas.append(NSAttributedString(string: fiveLabel, attributes: rowLabel))
        mas.append(NSAttributedString(string: fiveSeparator, attributes: separator))
        mas.append(NSAttributedString(string: "\(fiveResetText)\n", attributes: dim))
        mas.append(NSAttributedString(string: " \n", attributes: barTopSpacer))
        mas.append(NSAttributedString(attachment: barAttachment(percent: fivePct, font: barFont, color: fivePct <= 20 ? NSColor.systemRed : NSColor.green)))
        mas.append(NSAttributedString(string: "  \(fivePct >= 0 ? "\(fivePct)%" : "—")\n", attributes: percent))
        mas.append(NSAttributedString(string: " \n", attributes: barBottomSpacer))
        for (index, row) in resetExpirationRows.enumerated() {
            let suffix = index == resetExpirationRows.count - 1 ? "" : "\n"
            mas.append(NSAttributedString(string: row + suffix, attributes: expirationRow))
        }

        label.textStorage?.setAttributedString(mas)
    }

    func updateText(_ text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .foregroundColor: primaryTextColor
        ]
        label.textStorage?.setAttributedString(NSAttributedString(string: text, attributes: attrs))
    }
}

func remainingPercent(fromUsedPercent usedPercent: Int?) -> Int {
    guard let usedPercent else { return -1 }
    return 100 - max(0, min(100, usedPercent))
}

func appVersionText() -> String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let value = version?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let value, !value.isEmpty else { return "" }
    return "v\(value)"
}

// MARK: — App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: WindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        windowController = WindowController()
        windowController.startRefresh()
    }
}

@main
struct UsageWidgetMain {
    static var appDelegate: AppDelegate!

    static func main() {
        let app = NSApplication.shared
        appDelegate = AppDelegate()
        app.delegate = appDelegate
        app.run()
    }
}
