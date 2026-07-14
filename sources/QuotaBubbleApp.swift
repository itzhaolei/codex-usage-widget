import AppKit
import Combine
import SwiftUI

private let widgetWidth: CGFloat = 330

@main
struct QuotaBubbleApp: App {
    @StateObject private var store = QuotaStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            QuotaBubbleView(store: store)
                .background(WindowAccessor { window in
                    appDelegate.attach(window: window, store: store)
                })
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Divider()
                Menu(store.copy.language) {
                    Button {
                        store.selectLanguage(nil)
                    } label: {
                        HStack {
                            Text(store.copy.followSystem)
                            if readLanguageOverride() == nil { Image(systemName: "checkmark") }
                        }
                    }
                    Divider()
                    ForEach(supportedLanguages, id: \.code) { language in
                        Button {
                            store.selectLanguage(language.code)
                        } label: {
                            HStack {
                                Text(language.name)
                                if readLanguageOverride() == language.code { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }
                Button(store.copy.update) { appDelegate.checkForUpdates() }
                Divider()
                Button(role: .destructive) { appDelegate.confirmUninstall() } label: { Text(store.copy.uninstall) }
            }
        }
    }
}

private struct QuotaBubbleView: View {
    @ObservedObject var store: QuotaStore

    private var primary: Color { store.isLightMode ? .black : .white }
    private var secondary: Color { primary.opacity(0.68) }
    private var barColor: Color {
        guard let value = store.remainingPercentage else { return .red }
        return value <= 20 ? .red : Color(red: 0, green: 0.94, blue: 0.08)
    }

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, appearance: store.isLightMode ? .vibrantLight : .vibrantDark)
            (store.isLightMode ? Color.white.opacity(0.78) : Color.black.opacity(0.78))

            VStack(spacing: 0) {
                header
                quota
                    .padding(.top, 11)

                if !store.resetRows.isEmpty {
                    resetExpirations
                        .padding(.top, 13)
                }

                metricCards
                    .padding(.top, store.resetRows.isEmpty ? 15 : 10)
                identityRows
                    .padding(.top, 7)
                Spacer(minLength: 13)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 9)

            version
            if store.setupIssue != .ready { setupOverlay }
        }
        .frame(width: widgetWidth, height: store.desiredHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(primary.opacity(0.14), lineWidth: 1))
        .environment(\.colorScheme, store.isLightMode ? .light : .dark)
        .onAppear { store.start() }
        .onDisappear { store.stop() }
    }

    private var header: some View {
        HStack(spacing: 5) {
            Text(store.copy.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .layoutPriority(0)
            if !store.planText.isEmpty { planBadge }
            Spacer(minLength: 7)
            controlCapsule
                .fixedSize()
                .layoutPriority(2)
        }
        .frame(height: 28)
    }

    private var planBadge: some View {
        Text(store.planText)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 7)
            .frame(height: 16)
            .background(planColor)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .fixedSize(horizontal: true, vertical: false)
            .alignmentGuide(VerticalAlignment.center) { $0[VerticalAlignment.center] }
            .layoutPriority(2)
    }

    private var planColor: Color {
        switch normalizedPlanType(store.snapshot?.plan_type) {
        case "plus": return Color(red: 0, green: 0.72, blue: 0.08)
        case "pro", "pro5x", "pro20x": return .orange
        default: return .gray
        }
    }

    private var controlCapsule: some View {
        HStack(spacing: 0) {
            capsuleButton(store.isLightMode ? "moon.fill" : "sun.max.fill", help: store.isLightMode ? store.copy.switchToDark : store.copy.switchToLight) {
                store.toggleTheme()
            }
            divider
            capsuleButton("pin.fill", help: store.isPinned ? store.copy.unpin : store.copy.pin) {
                store.togglePinned()
                AppDelegate.shared?.applyPinnedState()
            }
            divider
            capsuleButton("xmark", help: store.copy.close) { NSApp.terminate(nil) }
        }
        .frame(width: 111, height: 28)
        .background(primary.opacity(0.04))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(primary.opacity(0.16), lineWidth: 1))
    }

    private var divider: some View {
        Rectangle().fill(primary.opacity(0.16)).frame(width: 1, height: 16)
    }

    private func capsuleButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(primary.opacity(0.76))
                .frame(width: 36, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var quota: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 7) {
                Text(store.copy.week)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(primary)
                Text("|")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(secondary)
                    .baselineOffset(1)
                Text("\(store.copy.reset) \(store.resetText)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            HStack(spacing: 12) {
                QuotaProgressBar(percentage: store.remainingPercentage, color: barColor)
                    .frame(width: 186, height: 20)
                Text(store.remainingPercentage.map { "\($0)%" } ?? "—")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(primary)
                    .frame(width: 38, alignment: .leading)
            }
        }
    }

    private var resetExpirations: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(store.resetRows) { row in
                HStack(spacing: 12) {
                    Circle()
                        .fill(row.isExpiringSoon == true ? Color.red : row.isExpiringSoon == false ? Color.green : secondary)
                        .frame(width: 7, height: 7)
                    Text(row.dateText)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(secondary)
                        .lineLimit(1)
                }
                .frame(height: 18)
            }
        }
    }

    private var metricCards: some View {
        HStack(spacing: 10) {
            MetricCard(title: "\(store.copy.balance)（$）", value: store.balanceText, lightMode: store.isLightMode, secondary: secondary)
            MetricCard(title: "\(store.copy.availableReset)（\(store.copy.times)）", value: store.resetCountText, lightMode: store.isLightMode, secondary: secondary)
        }
        .frame(width: 272, height: 47, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var identityRows: some View {
        VStack(spacing: 1) {
            InfoRow(symbol: "person.circle.fill", value: store.accountText, color: secondary)
            InfoRow(symbol: "calendar.badge.clock", value: store.subscriptionText, color: secondary)
        }
    }

    private var version: some View {
        HStack(spacing: 4) {
            if store.hasUpdate { Circle().fill(Color.red).frame(width: 4, height: 4) }
            Text(store.versionText)
                .font(.system(size: 9, weight: .light, design: .monospaced))
                .foregroundStyle(secondary)
        }
        .position(x: widgetWidth - 29, y: store.desiredHeight - 15)
    }

    private var setupOverlay: some View {
        ZStack {
            Color.black.opacity(0.64)
            VStack(alignment: .leading, spacing: 10) {
                Text(setupCopy.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
                Text(setupCopy.message)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(2)
                HStack(spacing: 16) {
                    setupStep("安装 CLI", index: 0)
                    setupStep("完成登录", index: 1)
                    setupStep("同步配额", index: 2)
                }
                HStack {
                    Spacer()
                    Button(setupCopy.button) { store.performSetupAction() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.25, green: 1, blue: 0.34))
                        .padding(.horizontal, 18)
                        .frame(height: 28)
                        .background(Color(red: 0.05, green: 0.42, blue: 0.14).opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.62)))
                        .disabled(store.setupIssue == .installing)
                }
            }
            .padding(18)
            .frame(width: widgetWidth - 36, height: 158)
            .background(Color(red: 0.06, green: 0.09, blue: 0.11).opacity(0.96))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.14)))
            .shadow(color: .black.opacity(0.28), radius: 18, y: 8)
        }
    }

    private var setupCopy: (title: String, message: String, button: String) {
        let zh = store.languageCode == "zh"
        switch store.setupIssue {
        case .missingNode: return zh ? ("需要安装 Node.js", "Quota Bubble 需要 Node.js 运行本地同步脚本，安装后会自动检测。", "安装") : ("Node.js required", "Node.js runs the local quota sync. It will be detected automatically after installation.", "Install")
        case .missingCli: return zh ? ("需要安装 Codex CLI", "安装后将自动创建本地数据并继续同步配额。", "安装") : ("Codex CLI required", "Install the CLI to create local data and start quota sync.", "Install")
        case .missingLogin: return zh ? ("需要登录 Codex CLI", "完成 codex login 后，工具会自动恢复显示。", "打开登录") : ("Codex CLI login required", "Complete codex login and the widget will recover automatically.", "Log in")
        case .waitingForSnapshot: return zh ? ("正在同步配额", "本地快照尚未生成，工具会持续重试。", "重试") : ("Syncing quota", "The local snapshot is not ready. Quota Bubble will keep retrying.", "Retry")
        case .installing: return zh ? ("正在安装 Codex CLI", "安装完成后会自动检测并同步配额。", "安装中") : ("Installing Codex CLI", "Quota Bubble will detect it and sync automatically.", "Installing")
        case .installFailed: return zh ? ("安装未完成", "请检查网络后重试。", "重试") : ("Installation incomplete", "Check the network and retry.", "Retry")
        case .ready: return ("", "", "")
        }
    }

    private func setupStep(_ title: String, index: Int) -> some View {
        let active: Int = {
            switch store.setupIssue {
            case .missingNode, .missingCli, .installing, .installFailed: return 0
            case .missingLogin: return 1
            case .waitingForSnapshot, .ready: return 2
            }
        }()
        return HStack(spacing: 5) {
            Circle().fill(index <= active ? Color.green : Color.white.opacity(0.22)).frame(width: 7, height: 7)
            Text(title).font(.system(size: 9, weight: .semibold)).foregroundStyle(Color.white.opacity(index <= active ? 0.86 : 0.44))
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let lightMode: Bool
    let secondary: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(secondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(lightMode ? Color.black : Color.white)
                .lineLimit(1)
        }
        .frame(width: 131, height: 47)
        .background(lightMode ? Color.white.opacity(0.42) : Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(lightMode ? 0.46 : 0.12)))
        .shadow(color: .black.opacity(lightMode ? 0.10 : 0.22), radius: 10, x: 3, y: 3)
    }
}

private struct InfoRow: View {
    let symbol: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: symbol).font(.system(size: 10)).frame(width: 13)
            Text(value)
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
        }
        .foregroundStyle(color)
        .frame(height: 17)
    }
}

private struct QuotaProgressBar: View {
    let percentage: Int?
    let color: Color

    var body: some View {
        Canvas { context, size in
            let percent = CGFloat(min(100, max(0, percentage ?? 0))) / 100
            let filled = size.width * percent
            context.fill(Path(CGRect(x: 0, y: 0, width: filled, height: size.height)), with: .color(color))

            if filled < size.width {
                for x in stride(from: max(0, filled + 1), through: size.width, by: 3) {
                    for y in stride(from: CGFloat(1), through: size.height, by: 3) {
                        let offset = Int(y / 3).isMultiple(of: 2) ? 0.0 : 1.5
                        context.fill(Path(ellipseIn: CGRect(x: x + offset, y: y, width: 1, height: 1)), with: .color(color))
                    }
                }
            }
            let separator = color.opacity(0.48)
            for index in 1..<5 {
                let x = size.width * CGFloat(index) / 5
                context.fill(Path(CGRect(x: x, y: 0, width: 0.6, height: size.height)), with: .color(separator))
            }
        }
    }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let appearance: NSAppearance.Name

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.appearance = NSAppearance(named: appearance)
    }
}

private struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { if let window = view.window { configure(window) } }
        return view
    }
    func updateNSView(_ view: NSView, context: Context) {
        DispatchQueue.main.async { if let window = view.window { configure(window) } }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static weak var shared: AppDelegate?
    private weak var window: NSWindow?
    private weak var store: QuotaStore?
    private var configuredWindow = false
    private var updateWindow: NSWindow?
    private let bundleIdentifier = "local.codex.quota-bubble"

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        let currentPID = ProcessInfo.processInfo.processIdentifier
        if let existing = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first(where: { $0.processIdentifier != currentPID }) {
            existing.activate(options: [.activateAllWindows])
            NSApp.terminate(nil)
            return
        }
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        window?.makeKeyAndOrderFront(nil)
        sender.activate(ignoringOtherApps: true)
        return true
    }

    func attach(window: NSWindow, store: QuotaStore) {
        self.window = window
        self.store = store
        guard !configuredWindow else {
            resizeWindow()
            return
        }
        configuredWindow = true
        window.delegate = self
        window.title = "Quota Bubble"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentMinSize = NSSize(width: widgetWidth, height: 234)
        window.contentMaxSize = NSSize(width: widgetWidth, height: 1_000)
        restoreWindowFrame()
        applyPinnedState()
        store.$resetRows.dropFirst().receive(on: RunLoop.main).sink { [weak self] _ in self?.resizeWindow() }.store(in: &cancellables)
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async { [weak self] in self?.resizeWindow(force: true) }
    }

    private var cancellables = Set<AnyCancellable>()

    func applyPinnedState() {
        window?.level = store?.isPinned == true ? .statusBar : .normal
    }

    private func resizeWindow(force: Bool = false) {
        guard let window, let store else { return }
        let desired = store.desiredHeight
        let contentSize = window.contentView?.frame.size ?? .zero
        guard force || abs(contentSize.width - widgetWidth) > 0.5 || abs(contentSize.height - desired) > 0.5 else { return }
        let top = window.frame.maxY
        window.setContentSize(NSSize(width: widgetWidth, height: desired))
        window.setFrameOrigin(NSPoint(x: window.frame.minX, y: top - window.frame.height))
    }

    private func restoreWindowFrame() {
        guard let window else { return }
        if let value = UserDefaults.standard.string(forKey: QuotaStore.savedFrameKey) {
            let saved = NSRectFromString(value)
            window.setContentSize(NSSize(width: widgetWidth, height: store?.desiredHeight ?? 234))
            window.setFrameOrigin(NSPoint(x: saved.minX, y: saved.maxY - window.frame.height))
        } else {
            window.setContentSize(NSSize(width: widgetWidth, height: store?.desiredHeight ?? 234))
            window.center()
        }
    }

    func windowDidMove(_ notification: Notification) { saveFrame() }
    func windowDidResize(_ notification: Notification) { saveFrame() }
    func windowWillClose(_ notification: Notification) { saveFrame() }
    private func saveFrame() {
        if let frame = window?.frame { UserDefaults.standard.set(NSStringFromRect(frame), forKey: QuotaStore.savedFrameKey) }
    }

    func checkForUpdates() {
        let dialogs = localizedDialogCopy(store?.languageCode ?? "en")
        showUpdateStatus(title: store?.copy.update ?? "Update", message: dialogs.checking, final: false)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self,
                  let url = URL(string: "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest"),
                  let data = try? Data(contentsOf: url),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tag = json["tag_name"] as? String,
                  let latest = normalizedVersion(tag),
                  let current = normalizedVersion(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) else {
                Task { @MainActor in self?.showUpdateStatus(title: dialogs.updateFailed, message: "", final: true) }
                return
            }
            guard compareVersions(current, latest) == .orderedAscending else {
                Task { @MainActor in self.showUpdateStatus(title: dialogs.upToDate, message: tag, final: true) }
                return
            }
            let assets = json["assets"] as? [[String: Any]] ?? []
            guard let asset = assets.first(where: { ($0["name"] as? String)?.hasSuffix("macOS-Installer.zip") == true }),
                  let assetURL = asset["browser_download_url"] as? String else {
                Task { @MainActor in self.showUpdateStatus(title: dialogs.updateFailed, message: "Installer not found", final: true) }
                return
            }
            Task { @MainActor in self.showUpdateStatus(title: dialogs.downloading, message: tag, final: false) }
            self.installUpdate(assetURL: assetURL, tag: tag)
        }
    }

    nonisolated private func installUpdate(assetURL: String, tag: String) {
        let command = "set -e; d=$(mktemp -d); curl -L -o \"$d/installer.zip\" \(shellQuote(assetURL)); unzip -q \"$d/installer.zip\" -d \"$d\"; QUOTA_BUBBLE_KEEP_RUNNING=1 QUOTA_BUBBLE_SKIP_LAUNCH=1 /bin/bash \"$d/Install Quota Bubble.app/Contents/Resources/install-packaged.sh\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                if process.terminationStatus == 0 { self?.store?.markUpdateInstalled() }
                let dialogs = localizedDialogCopy(self?.store?.languageCode ?? "en")
                self?.showUpdateStatus(title: process.terminationStatus == 0 ? dialogs.updateComplete : dialogs.updateFailed, message: tag, final: true)
            }
        }
        try? process.run()
    }

    private func showUpdateStatus(title: String, message: String, final: Bool) {
        if updateWindow == nil {
            let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 132), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            panel.level = .floating
            panel.center()
            updateWindow = panel
        }
        guard let content = updateWindow?.contentView else { return }
        content.subviews.forEach { $0.removeFromSuperview() }
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.frame = NSRect(x: 22, y: 75, width: 316, height: 22)
        content.addSubview(titleLabel)
        let info = NSTextField(labelWithString: message)
        info.textColor = .secondaryLabelColor
        info.frame = NSRect(x: 22, y: 47, width: 316, height: 20)
        content.addSubview(info)
        if final {
            let button = NSButton(title: "OK", target: updateWindow, action: #selector(NSWindow.orderOut(_:)))
            button.frame = NSRect(x: 268, y: 12, width: 70, height: 28)
            content.addSubview(button)
        }
        updateWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func confirmUninstall() {
        let dialogs = localizedDialogCopy(store?.languageCode ?? "en")
        let alert = NSAlert()
        alert.messageText = dialogs.uninstallTitle
        alert.informativeText = dialogs.uninstallMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: dialogs.confirmUninstall)
        alert.addButton(withTitle: dialogs.cancel)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let script = NSString(string: "~/.codex/usage-widget/uninstall.sh").expandingTildeInPath
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script]
        try? process.run()
    }
}
