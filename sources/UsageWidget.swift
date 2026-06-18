// UsageWidget.swift — 常驻桌面配额进度浮动窗
// 编译: swiftc -parse-as-library -o UsageWidget UsageWidget.swift -framework Cocoa

import Cocoa

// MARK: — 快照模型
struct UsageSnapshot: Codable {
    var updated_at: String?
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
}

// MARK: — Localization
struct AppLanguage {
    let title: String
    let week: String
    let reset: String
    let availableReset: String
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
    title: "Codex 额度", week: "周", reset: "重置", availableReset: "可用重置", times: "次",
    alreadyReset: "已重置", unableToReadSnapshot: "无法读取快照",
    switchToDark: "切换到黑色模式", switchToLight: "切换到白色模式",
    pin: "置顶", unpin: "取消置顶", close: "关闭窗口", separator: " ",
    afterSuffix: "后",
    day: { "\($0)天" }, hour: { "\($0)小时" }, minute: { "\($0)分钟" }, second: { "\($0)秒" }
)

func localizedLanguage() -> AppLanguage {
    let code = Locale.preferredLanguages.first?.lowercased() ?? "en"
    if code.hasPrefix("zh") { return zhLanguage }
    if code.hasPrefix("ja") {
        return AppLanguage(title: "Codex 使用量", week: "週", reset: "リセット", availableReset: "利用可能なリセット", times: "回",
            alreadyReset: "リセット済み", unableToReadSnapshot: "スナップショットを読み込めません",
            switchToDark: "ダークモードに切り替え", switchToLight: "ライトモードに切り替え",
            pin: "最前面に固定", unpin: "固定を解除", close: "ウィンドウを閉じる", separator: " ",
            afterSuffix: "後", day: { "\($0)日" }, hour: { "\($0)時間" }, minute: { "\($0)分" }, second: { "\($0)秒" })
    }
    if code.hasPrefix("ko") {
        return AppLanguage(title: "Codex 사용량", week: "주", reset: "재설정", availableReset: "사용 가능 재설정", times: "회",
            alreadyReset: "재설정됨", unableToReadSnapshot: "스냅샷을 읽을 수 없음",
            switchToDark: "다크 모드로 전환", switchToLight: "라이트 모드로 전환",
            pin: "항상 위", unpin: "항상 위 해제", close: "창 닫기", separator: " ",
            afterSuffix: " 후", day: { "\($0)일" }, hour: { "\($0)시간" }, minute: { "\($0)분" }, second: { "\($0)초" })
    }
    if code.hasPrefix("de") {
        return AppLanguage(title: "Codex Limit", week: "Woche", reset: "Reset", availableReset: "Verfügbare Resets", times: "Mal",
            alreadyReset: "Zurückgesetzt", unableToReadSnapshot: "Snapshot kann nicht gelesen werden",
            switchToDark: "Zu Dunkel wechseln", switchToLight: "Zu Hell wechseln",
            pin: "Anheften", unpin: "Lösen", close: "Fenster schließen", separator: " ",
            afterSuffix: " später", day: { plural($0, "Tag", "Tage") }, hour: { plural($0, "Stunde", "Stunden") }, minute: { plural($0, "Minute", "Minuten") }, second: { plural($0, "Sekunde", "Sekunden") })
    }
    if code.hasPrefix("fr") {
        return AppLanguage(title: "Quota Codex", week: "Semaine", reset: "Réinit.", availableReset: "Réinitialisations dispo.", times: "fois",
            alreadyReset: "Réinitialisé", unableToReadSnapshot: "Impossible de lire l’instantané",
            switchToDark: "Passer en mode sombre", switchToLight: "Passer en mode clair",
            pin: "Épingler", unpin: "Détacher", close: "Fermer la fenêtre", separator: " ",
            afterSuffix: " plus tard", day: { plural($0, "jour", "jours") }, hour: { plural($0, "heure", "heures") }, minute: { plural($0, "minute", "minutes") }, second: { plural($0, "seconde", "secondes") })
    }
    if code.hasPrefix("es") {
        return AppLanguage(title: "Cuota Codex", week: "Semana", reset: "Reinicio", availableReset: "Reinicios disponibles", times: "veces",
            alreadyReset: "Reiniciado", unableToReadSnapshot: "No se puede leer la instantánea",
            switchToDark: "Cambiar a modo oscuro", switchToLight: "Cambiar a modo claro",
            pin: "Fijar", unpin: "Desfijar", close: "Cerrar ventana", separator: " ",
            afterSuffix: " después", day: { plural($0, "día", "días") }, hour: { plural($0, "hora", "horas") }, minute: { plural($0, "minuto", "minutos") }, second: { plural($0, "segundo", "segundos") })
    }
    if code.hasPrefix("pt") {
        return AppLanguage(title: "Cota Codex", week: "Semana", reset: "Redefinir", availableReset: "Redefinições disponíveis", times: "vezes",
            alreadyReset: "Redefinido", unableToReadSnapshot: "Não foi possível ler o snapshot",
            switchToDark: "Alternar para modo escuro", switchToLight: "Alternar para modo claro",
            pin: "Fixar", unpin: "Desafixar", close: "Fechar janela", separator: " ",
            afterSuffix: " depois", day: { plural($0, "dia", "dias") }, hour: { plural($0, "hora", "horas") }, minute: { plural($0, "minuto", "minutos") }, second: { plural($0, "segundo", "segundos") })
    }
    if code.hasPrefix("it") {
        return AppLanguage(title: "Quota Codex", week: "Settimana", reset: "Ripristino", availableReset: "Ripristini disponibili", times: "volte",
            alreadyReset: "Ripristinato", unableToReadSnapshot: "Impossibile leggere lo snapshot",
            switchToDark: "Passa alla modalità scura", switchToLight: "Passa alla modalità chiara",
            pin: "Fissa", unpin: "Rimuovi fissaggio", close: "Chiudi finestra", separator: " ",
            afterSuffix: " dopo", day: { plural($0, "giorno", "giorni") }, hour: { plural($0, "ora", "ore") }, minute: { plural($0, "minuto", "minuti") }, second: { plural($0, "secondo", "secondi") })
    }
    if code.hasPrefix("nl") {
        return AppLanguage(title: "Codex-limiet", week: "Week", reset: "Reset", availableReset: "Beschikbare resets", times: "keer",
            alreadyReset: "Gereset", unableToReadSnapshot: "Kan snapshot niet lezen",
            switchToDark: "Schakel naar donker", switchToLight: "Schakel naar licht",
            pin: "Vastzetten", unpin: "Losmaken", close: "Venster sluiten", separator: " ",
            afterSuffix: " later", day: { plural($0, "dag", "dagen") }, hour: { plural($0, "uur", "uur") }, minute: { plural($0, "minuut", "minuten") }, second: { plural($0, "seconde", "seconden") })
    }
    return AppLanguage(title: "Codex Quota", week: "Week", reset: "Reset", availableReset: "Available resets", times: "times",
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

func formatFiveHourReset(_ timestamp: TimeInterval?, language: AppLanguage) -> String {
    guard let rawInterval = secondsUntil(timestamp) else { return "—" }
    if rawInterval <= 0 { return language.alreadyReset }

    let normalized = rawInterval - 1
    let d = normalized / 86400
    let h = (normalized % 86400) / 3600
    let m = (normalized % 3600) / 60
    let s = (normalized % 60) + 1

    var parts: [String] = []
    if d > 0 { parts.append(language.day(d)) }
    if h > 0 { parts.append(language.hour(h)) }
    if m > 0 { parts.append(language.minute(m)) }
    parts.append(language.second(s))
    return "\(parts.joined(separator: language.separator))\(language.afterSuffix)"
}

func formatSevenDayReset(_ timestamp: TimeInterval?, language: AppLanguage) -> String {
    guard let interval = secondsUntil(timestamp) else { return "—" }
    if interval <= 0 { return language.alreadyReset }
    if interval < 60 { return "\(language.second(interval))\(language.afterSuffix)" }

    let d = interval / 86400
    let h = (interval % 86400) / 3600
    let m = (interval % 3600) / 60

    var parts: [String] = []
    if d > 0 { parts.append(language.day(d)) }
    if h > 0 { parts.append(language.hour(h)) }
    if m > 0 { parts.append(language.minute(m)) }
    if parts.isEmpty {
        return "\(language.minute(1))\(language.afterSuffix)"
    }
    return "\(parts.joined(separator: language.separator))\(language.afterSuffix)"
}

func progressBar(percent: Int, width: Int = 15) -> String {
    let filled = Int(round(Double(percent) / 100.0 * Double(width)))
    let empty = width - filled
    return String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
}

// MARK: — 主窗口控制器
class WindowController: NSWindowController, NSWindowDelegate {
    var label: NSTextView!
    var rootView: NSView!
    var vibrancyView: NSVisualEffectView!
    var capsuleView: NSView!
    var dividerViews: [NSView] = []
    var controlButtons: [NSButton] = []
    var themeButton: NSButton!
    var pinButton: NSButton!
    var timer: Timer!
    var lastSnapshotRefresh = Date.distantPast
    var snapshotRefreshInFlight = false
    var isPinned = true
    var isLightMode = false
    let language = localizedLanguage()
    let savedFrameKey = "CodexUsageWidget.savedFrame"
    let pinnedKey = "CodexUsageWidget.isPinned"
    let lightModeKey = "CodexUsageWidget.isLightMode"
    let snapshotPath = NSString(string: "~/.codex/codex-usage-snapshot.json").expandingTildeInPath
    let snapshotScriptPath = NSString(string: "~/.codex/scripts/codex-usage-snapshot.mjs").expandingTildeInPath
    let closedMarkerPath = NSString(string: "~/.codex/usage-widget/.closed-by-user").expandingTildeInPath

    convenience init() {
        let w: CGFloat = 330
        let h: CGFloat = 190
        let contentRect = NSRect(x: 0, y: 0, width: w, height: h)

        let panel = NSPanel(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.minSize = NSSize(width: w, height: h)
        panel.maxSize = NSSize(width: w, height: h)
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

        label = NSTextView(frame: NSRect(x: 12, y: 6, width: w - 24, height: h - 22))
        label.autoresizingMask = [.width, .height]
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.textContainerInset = NSSize(width: 0, height: 0)
        label.textContainer?.lineFragmentPadding = 0
        label.backgroundColor = NSColor.clear
        rootView.addSubview(label)

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
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
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
        frame.size = defaultSize

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
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    func refresh() {
        refreshSnapshotIfNeeded()

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: snapshotPath)),
              let snap = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else {
            updateText("⚠ \(language.unableToReadSnapshot):\n\(snapshotPath)")
            return
        }

        let five = snap.five_hour
        let seven = snap.seven_day

        let fivePct = remainingPercent(fromUsedPercent: five?.used_percentage)
        let sevenPct = remainingPercent(fromUsedPercent: seven?.used_percentage)
        let fiveReset = formatFiveHourReset(five?.resets_at, language: language)
        let sevenReset = formatSevenDayReset(seven?.resets_at, language: language)
        let resetCredits = snap.reset_credits?.available_count

        let emptyBar = String(repeating: "░", count: 15)
        let fiveBar = fivePct >= 0 ? progressBar(percent: fivePct) : emptyBar
        let sevenBar = sevenPct >= 0 ? progressBar(percent: sevenPct) : emptyBar

        buildAttributedText(
            fiveBar: fiveBar, fivePct: fivePct, fiveReset: fiveReset,
            sevenBar: sevenBar, sevenPct: sevenPct, sevenReset: sevenReset,
            resetCredits: resetCredits
        )
    }

    func refreshSnapshotIfNeeded() {
        guard !snapshotRefreshInFlight,
              -lastSnapshotRefresh.timeIntervalSinceNow >= 1,
              FileManager.default.fileExists(atPath: snapshotScriptPath) else { return }

        snapshotRefreshInFlight = true
        lastSnapshotRefresh = Date()

        DispatchQueue.global(qos: .utility).async { [scriptPath = snapshotScriptPath, outputPath = snapshotPath, weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["node", scriptPath, outputPath]
            process.standardOutput = Pipe()
            process.standardError = Pipe()

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                // Keep displaying the previous snapshot if the refresh command cannot run.
            }

            DispatchQueue.main.async {
                self?.snapshotRefreshInFlight = false
            }
        }
    }

    func buildAttributedText(fiveBar: String, fivePct: Int, fiveReset: String,
                             sevenBar: String, sevenPct: Int, sevenReset: String,
                             resetCredits: Int?) {
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

        let title = attrs(font: NSFont.systemFont(ofSize: 15, weight: .bold),
                          color: primaryTextColor, lineHeight: 18, spacing: 20)
        let percent = attrs(font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                            color: primaryTextColor, lineHeight: 20)
        let green = attrs(font: NSFont.monospacedSystemFont(ofSize: 20, weight: .regular),
                          color: NSColor.green, lineHeight: 20)
        let greenText = attrs(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
                              color: NSColor.green, lineHeight: 16)
        let mutedText = attrs(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold),
                              color: secondaryTextColor, lineHeight: 16)
        let warn = attrs(font: NSFont.monospacedSystemFont(ofSize: 20, weight: .regular),
                         color: NSColor.systemRed, lineHeight: 20)
        let barBottomSpacer = attrs(font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                                    color: NSColor.clear, lineHeight: 10)
        let dim = attrs(font: NSFont.monospacedSystemFont(ofSize: 10, weight: .regular),
                        color: secondaryTextColor, lineHeight: 16)
        let rowLabel = attrs(font: NSFont.monospacedSystemFont(ofSize: 13, weight: .bold),
                             color: primaryTextColor, lineHeight: 16)
        let separator = attrs(font: NSFont.monospacedSystemFont(ofSize: 8, weight: .bold),
                              color: secondaryTextColor, lineHeight: 16, baseline: 2.0)

        let mas = NSMutableAttributedString()
        mas.append(NSAttributedString(string: "\(language.title)\n", attributes: title))
        mas.append(NSAttributedString(string: "5h", attributes: rowLabel))
        mas.append(NSAttributedString(string: "  ┃  ", attributes: separator))
        mas.append(NSAttributedString(string: "\(language.reset) \(fiveReset)\n", attributes: dim))
        mas.append(NSAttributedString(string: fiveBar, attributes: fivePct <= 20 ? warn : green))
        mas.append(NSAttributedString(string: "  \(fivePct >= 0 ? "\(fivePct)%" : "—")\n", attributes: percent))
        mas.append(NSAttributedString(string: " \n", attributes: barBottomSpacer))
        mas.append(NSAttributedString(string: language.week, attributes: rowLabel))
        mas.append(NSAttributedString(string: "   ┃  ", attributes: separator))
        mas.append(NSAttributedString(string: "\(language.reset) \(sevenReset)\n", attributes: dim))
        mas.append(NSAttributedString(string: sevenBar, attributes: sevenPct <= 20 ? warn : green))
        mas.append(NSAttributedString(string: "  \(sevenPct >= 0 ? "\(sevenPct)%" : "—")\n", attributes: percent))
        mas.append(NSAttributedString(string: " \n", attributes: barBottomSpacer))
        let resetText = resetCredits.map { "\($0) \(language.times)" } ?? "—"
        let resetAttributes = (resetCredits ?? 0) > 0 ? greenText : mutedText
        mas.append(NSAttributedString(string: "\(language.availableReset) \(resetText)", attributes: resetAttributes))

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
