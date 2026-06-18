import Cocoa

struct LauncherLanguage {
    let notInstalled: String
    let installHint: String
    let launchFailed: String
}

func launcherLanguage() -> LauncherLanguage {
    let code = Locale.preferredLanguages.first?.lowercased() ?? "en"
    if code.hasPrefix("zh") { return LauncherLanguage(notInstalled: "Codex Usage Widget 尚未安装", installHint: "请先在插件目录执行 bash scripts/install.sh。", launchFailed: "启动失败") }
    if code.hasPrefix("ja") { return LauncherLanguage(notInstalled: "Codex Usage Widget は未インストールです", installHint: "先にプラグインディレクトリで bash scripts/install.sh を実行してください。", launchFailed: "起動に失敗しました") }
    if code.hasPrefix("ko") { return LauncherLanguage(notInstalled: "Codex Usage Widget가 설치되지 않았습니다", installHint: "먼저 플러그인 디렉터리에서 bash scripts/install.sh 를 실행하세요.", launchFailed: "시작 실패") }
    if code.hasPrefix("de") { return LauncherLanguage(notInstalled: "Codex Usage Widget ist nicht installiert", installHint: "Führen Sie zuerst bash scripts/install.sh im Plugin-Ordner aus.", launchFailed: "Start fehlgeschlagen") }
    if code.hasPrefix("fr") { return LauncherLanguage(notInstalled: "Codex Usage Widget n’est pas installé", installHint: "Exécutez d’abord bash scripts/install.sh dans le dossier du plugin.", launchFailed: "Échec du lancement") }
    if code.hasPrefix("es") { return LauncherLanguage(notInstalled: "Codex Usage Widget no está instalado", installHint: "Ejecuta primero bash scripts/install.sh en la carpeta del plugin.", launchFailed: "Error al iniciar") }
    if code.hasPrefix("pt") { return LauncherLanguage(notInstalled: "Codex Usage Widget não está instalado", installHint: "Execute primeiro bash scripts/install.sh na pasta do plugin.", launchFailed: "Falha ao iniciar") }
    if code.hasPrefix("it") { return LauncherLanguage(notInstalled: "Codex Usage Widget non è installato", installHint: "Esegui prima bash scripts/install.sh nella cartella del plugin.", launchFailed: "Avvio non riuscito") }
    if code.hasPrefix("nl") { return LauncherLanguage(notInstalled: "Codex Usage Widget is niet geïnstalleerd", installHint: "Voer eerst bash scripts/install.sh uit in de pluginmap.", launchFailed: "Starten mislukt") }
    return LauncherLanguage(notInstalled: "Codex Usage Widget is not installed", installHint: "Run bash scripts/install.sh in the plugin directory first.", launchFailed: "Launch failed")
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let installDir = NSString(string: "~/.codex/usage-widget").expandingTildeInPath
    private let widgetExecutablePattern = "UsageWidget.app/Contents/MacOS/UsageWidget"
    private let launcherBundleIdentifier = "local.codex.usage-widget.launcher"
    private let widgetBundleIdentifier = "local.codex.usage-widget"
    private let language = launcherLanguage()
    private var monitorTimer: Timer?
    private var isStartingWidget = false
    private var hasObservedWidget = false
    private var startGraceUntil = Date.distantPast
    private var isExitingAfterWidgetClosed = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let previouslyActiveApp = NSWorkspace.shared.frontmostApplication
        if activateExistingLauncherIfNeeded() {
            isExitingAfterWidgetClosed = true
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.regular)
        startWidget()
        startMonitoringWidget()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            previouslyActiveApp?.activate(options: [])
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        startWidget()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitorTimer?.invalidate()
        if !isExitingAfterWidgetClosed {
            closeWidgetFromLauncher()
        }
    }

    private func startWidget() {
        isStartingWidget = true
        startGraceUntil = Date().addingTimeInterval(10.0)
        let markerPath = "\(installDir)/.closed-by-user"
        try? FileManager.default.removeItem(atPath: markerPath)

        let ensurePath = "\(installDir)/ensure-usage-widget.sh"
        let scriptPath = ensurePath
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            isStartingWidget = false
            showAlert(message: language.notInstalled, info: language.installHint)
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                self.isStartingWidget = false
            }
        } catch {
            isStartingWidget = false
            showAlert(message: language.launchFailed, info: error.localizedDescription)
        }
    }

    private func activateExistingLauncherIfNeeded() -> Bool {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let existingApps = NSRunningApplication
            .runningApplications(withBundleIdentifier: launcherBundleIdentifier)
            .filter { $0.processIdentifier != currentPID }

        guard let existingApp = existingApps.first else { return false }
        existingApp.activate()
        return true
    }

    private func startMonitoringWidget() {
        monitorTimer?.invalidate()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            if self.widgetIsRunning() {
                self.hasObservedWidget = true
                self.isStartingWidget = false
                return
            }
            if self.isStartingWidget || Date() < self.startGraceUntil { return }
            if self.hasObservedWidget {
                self.isExitingAfterWidgetClosed = true
                NSApp.terminate(nil)
            }
        }
    }

    private func widgetIsRunning() -> Bool {
        if !NSRunningApplication.runningApplications(withBundleIdentifier: widgetBundleIdentifier).isEmpty {
            return true
        }
        return processExists(matching: widgetExecutablePattern)
    }

    private func closeWidgetFromLauncher() {
        let markerPath = "\(installDir)/.closed-by-user"
        FileManager.default.createFile(atPath: markerPath, contents: Data(), attributes: nil)

        for app in NSRunningApplication.runningApplications(withBundleIdentifier: widgetBundleIdentifier) {
            app.terminate()
        }
        terminateWidgetByPath(force: false)

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
            for app in NSRunningApplication.runningApplications(withBundleIdentifier: self.widgetBundleIdentifier) {
                app.forceTerminate()
            }
            self.terminateWidgetByPath(force: true)
        }
    }

    private func processExists(matching pattern: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-f", pattern]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func terminateWidgetByPath(force: Bool) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
        process.arguments = force ? ["-9", "-f", widgetExecutablePattern] : ["-f", widgetExecutablePattern]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
    }

    private func showAlert(message: String, info: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = info
        alert.alertStyle = .warning
        alert.runModal()
    }
}

@main
enum LauncherMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
