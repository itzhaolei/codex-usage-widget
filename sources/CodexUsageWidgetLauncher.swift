import Cocoa

let supportedLanguages: [(code: String, name: String)] = [
    ("en", "English"),
    ("zh", "中文"),
    ("ja", "日本語"),
    ("ko", "한국어"),
    ("de", "Deutsch"),
    ("fr", "Français"),
    ("es", "Español"),
    ("pt", "Português"),
    ("it", "Italiano"),
    ("nl", "Nederlands")
]

struct LauncherLanguage {
    let notInstalled: String
    let installHint: String
    let launchFailed: String
    let update: String
    let uninstall: String
    let language: String
    let followSystem: String
    let updateStarted: String
    let updateStartedInfo: String
    let updateFailed: String
    let uninstallTitle: String
    let uninstallMessage: String
    let cancel: String
    let confirmUninstall: String
}

func languagePreferencePath() -> String {
    NSString(string: "~/.codex/usage-widget/language.txt").expandingTildeInPath
}

func readLanguageOverride() -> String? {
    guard let raw = try? String(contentsOfFile: languagePreferencePath(), encoding: .utf8) else { return nil }
    let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return supportedLanguages.contains(where: { $0.code == value }) ? value : nil
}

func writeLanguageOverride(_ code: String?) {
    let path = languagePreferencePath()
    let directory = NSString(string: path).deletingLastPathComponent
    try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)

    guard let code else {
        try? FileManager.default.removeItem(atPath: path)
        return
    }
    try? "\(code)\n".write(toFile: path, atomically: true, encoding: .utf8)
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

func launcherLanguage() -> LauncherLanguage {
    switch effectiveLanguageCode() {
    case "zh":
        return LauncherLanguage(notInstalled: "Codex Usage Widget 尚未安装", installHint: "请先安装或重新运行安装器。", launchFailed: "启动失败",
            update: "版本更新", uninstall: "卸载", language: "语言", followSystem: "跟随系统",
            updateStarted: "正在更新", updateStartedInfo: "正在下载并安装最新版本。", updateFailed: "更新失败",
            uninstallTitle: "卸载 Codex Usage Widget？", uninstallMessage: "这会关闭窗口并移除启动器、后台任务和本地安装文件。", cancel: "取消", confirmUninstall: "卸载")
    case "ja":
        return LauncherLanguage(notInstalled: "Codex Usage Widget は未インストールです", installHint: "インストーラーを再実行してください。", launchFailed: "起動に失敗しました",
            update: "アップデート", uninstall: "アンインストール", language: "言語", followSystem: "システムに合わせる",
            updateStarted: "更新中", updateStartedInfo: "最新バージョンをダウンロードしてインストールしています。", updateFailed: "更新に失敗しました",
            uninstallTitle: "Codex Usage Widget をアンインストールしますか？", uninstallMessage: "ウィンドウ、ランチャー、バックグラウンドタスク、ローカルファイルを削除します。", cancel: "キャンセル", confirmUninstall: "アンインストール")
    case "ko":
        return LauncherLanguage(notInstalled: "Codex Usage Widget가 설치되지 않았습니다", installHint: "설치 프로그램을 다시 실행하세요.", launchFailed: "시작 실패",
            update: "버전 업데이트", uninstall: "제거", language: "언어", followSystem: "시스템 따르기",
            updateStarted: "업데이트 중", updateStartedInfo: "최신 버전을 다운로드하고 설치하는 중입니다.", updateFailed: "업데이트 실패",
            uninstallTitle: "Codex Usage Widget을 제거할까요?", uninstallMessage: "창, 런처, 백그라운드 작업 및 로컬 설치 파일을 제거합니다.", cancel: "취소", confirmUninstall: "제거")
    case "de":
        return LauncherLanguage(notInstalled: "Codex Usage Widget ist nicht installiert", installHint: "Führen Sie den Installer erneut aus.", launchFailed: "Start fehlgeschlagen",
            update: "Update", uninstall: "Deinstallieren", language: "Sprache", followSystem: "System folgen",
            updateStarted: "Update läuft", updateStartedInfo: "Die neueste Version wird heruntergeladen und installiert.", updateFailed: "Update fehlgeschlagen",
            uninstallTitle: "Codex Usage Widget deinstallieren?", uninstallMessage: "Fenster, Launcher, Hintergrundaufgabe und lokale Dateien werden entfernt.", cancel: "Abbrechen", confirmUninstall: "Deinstallieren")
    case "fr":
        return LauncherLanguage(notInstalled: "Codex Usage Widget n’est pas installé", installHint: "Relancez l’installateur.", launchFailed: "Échec du lancement",
            update: "Mettre à jour", uninstall: "Désinstaller", language: "Langue", followSystem: "Suivre le système",
            updateStarted: "Mise à jour", updateStartedInfo: "Téléchargement et installation de la dernière version.", updateFailed: "Échec de la mise à jour",
            uninstallTitle: "Désinstaller Codex Usage Widget ?", uninstallMessage: "La fenêtre, le lanceur, la tâche d’arrière-plan et les fichiers locaux seront supprimés.", cancel: "Annuler", confirmUninstall: "Désinstaller")
    case "es":
        return LauncherLanguage(notInstalled: "Codex Usage Widget no está instalado", installHint: "Vuelve a ejecutar el instalador.", launchFailed: "Error al iniciar",
            update: "Actualizar versión", uninstall: "Desinstalar", language: "Idioma", followSystem: "Seguir sistema",
            updateStarted: "Actualizando", updateStartedInfo: "Descargando e instalando la versión más reciente.", updateFailed: "Error al actualizar",
            uninstallTitle: "¿Desinstalar Codex Usage Widget?", uninstallMessage: "Se eliminarán la ventana, el lanzador, la tarea en segundo plano y los archivos locales.", cancel: "Cancelar", confirmUninstall: "Desinstalar")
    case "pt":
        return LauncherLanguage(notInstalled: "Codex Usage Widget não está instalado", installHint: "Execute o instalador novamente.", launchFailed: "Falha ao iniciar",
            update: "Atualizar versão", uninstall: "Desinstalar", language: "Idioma", followSystem: "Seguir sistema",
            updateStarted: "Atualizando", updateStartedInfo: "Baixando e instalando a versão mais recente.", updateFailed: "Falha na atualização",
            uninstallTitle: "Desinstalar Codex Usage Widget?", uninstallMessage: "A janela, o lançador, a tarefa em segundo plano e os arquivos locais serão removidos.", cancel: "Cancelar", confirmUninstall: "Desinstalar")
    case "it":
        return LauncherLanguage(notInstalled: "Codex Usage Widget non è installato", installHint: "Esegui di nuovo l’installer.", launchFailed: "Avvio non riuscito",
            update: "Aggiorna versione", uninstall: "Disinstalla", language: "Lingua", followSystem: "Segui sistema",
            updateStarted: "Aggiornamento", updateStartedInfo: "Download e installazione dell’ultima versione.", updateFailed: "Aggiornamento non riuscito",
            uninstallTitle: "Disinstallare Codex Usage Widget?", uninstallMessage: "La finestra, il launcher, l’attività in background e i file locali saranno rimossi.", cancel: "Annulla", confirmUninstall: "Disinstalla")
    case "nl":
        return LauncherLanguage(notInstalled: "Codex Usage Widget is niet geïnstalleerd", installHint: "Voer de installer opnieuw uit.", launchFailed: "Starten mislukt",
            update: "Versie bijwerken", uninstall: "Verwijderen", language: "Taal", followSystem: "Systeem volgen",
            updateStarted: "Bijwerken", updateStartedInfo: "De nieuwste versie wordt gedownload en geïnstalleerd.", updateFailed: "Bijwerken mislukt",
            uninstallTitle: "Codex Usage Widget verwijderen?", uninstallMessage: "Het venster, de launcher, achtergrondtaak en lokale bestanden worden verwijderd.", cancel: "Annuleren", confirmUninstall: "Verwijderen")
    default:
        return LauncherLanguage(notInstalled: "Codex Usage Widget is not installed", installHint: "Run the installer again.", launchFailed: "Launch failed",
            update: "Check for Updates", uninstall: "Uninstall", language: "Language", followSystem: "Follow System",
            updateStarted: "Updating", updateStartedInfo: "Downloading and installing the latest version.", updateFailed: "Update failed",
            uninstallTitle: "Uninstall Codex Usage Widget?", uninstallMessage: "This will close the widget and remove the launcher, background task, and local install files.", cancel: "Cancel", confirmUninstall: "Uninstall")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let installDir = NSString(string: "~/.codex/usage-widget").expandingTildeInPath
    private let widgetExecutablePattern = "UsageWidget.app/Contents/MacOS/UsageWidget"
    private let launcherBundleIdentifier = "local.codex.usage-widget.launcher"
    private let widgetBundleIdentifier = "local.codex.usage-widget"
    private var language = launcherLanguage()
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
        rebuildMenu()
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

    private func rebuildMenu() {
        language = launcherLanguage()

        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "Codex Usage Widget")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        appMenu.addItem(NSMenuItem(title: language.update, action: #selector(updateToLatestVersion), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem(title: language.uninstall, action: #selector(confirmUninstall), keyEquivalent: ""))
        appMenu.addItem(.separator())

        let languageItem = NSMenuItem(title: language.language, action: nil, keyEquivalent: "")
        let languageMenu = NSMenu(title: language.language)
        languageItem.submenu = languageMenu
        appMenu.addItem(languageItem)

        let systemItem = NSMenuItem(title: language.followSystem, action: #selector(selectLanguage(_:)), keyEquivalent: "")
        systemItem.representedObject = "system"
        systemItem.state = readLanguageOverride() == nil ? .on : .off
        languageMenu.addItem(systemItem)
        languageMenu.addItem(.separator())

        let selected = readLanguageOverride()
        for entry in supportedLanguages {
            let item = NSMenuItem(title: entry.name, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.representedObject = entry.code
            item.state = selected == entry.code ? .on : .off
            languageMenu.addItem(item)
        }

        NSApp.mainMenu = mainMenu
    }

    @objc private func selectLanguage(_ sender: NSMenuItem) {
        let code = sender.representedObject as? String
        writeLanguageOverride(code == "system" ? nil : code)
        rebuildMenu()
        startWidget()
    }

    @objc private func updateToLatestVersion() {
        runDetachedShell("""
        set -e
        TMP_DIR="$(mktemp -d)"
        API_URL="https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest"
        ASSET_URL="$(/usr/bin/python3 -c 'import json,sys,urllib.request; data=json.load(urllib.request.urlopen(sys.argv[1])); assets=data.get("assets", []); matches=[a.get("browser_download_url") for a in assets if str(a.get("name", "")).endswith("Installer.zip")]; print(matches[0] if matches else "")' "$API_URL")"
        if [ -z "$ASSET_URL" ]; then
            exit 2
        fi
        /usr/bin/curl -L -o "$TMP_DIR/installer.zip" "$ASSET_URL"
        /usr/bin/unzip -q "$TMP_DIR/installer.zip" -d "$TMP_DIR"
        /bin/bash "$TMP_DIR/Install Codex Usage Widget.app/Contents/Resources/install-packaged.sh"
        """)
        showAlert(message: language.updateStarted, info: language.updateStartedInfo)
    }

    @objc private func confirmUninstall() {
        let alert = NSAlert()
        alert.messageText = language.uninstallTitle
        alert.informativeText = language.uninstallMessage
        alert.alertStyle = .warning
        alert.addButton(withTitle: language.confirmUninstall)
        alert.addButton(withTitle: language.cancel)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        runDetachedShell("""
        CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
        INSTALL_DIR="$CODEX_HOME/usage-widget"
        LAUNCHER_APP="$HOME/Applications/Codex Usage Widget.app"
        LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.codex.usage-widget.autostart.plist"
        launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" >/dev/null 2>&1 || true
        pkill -f "UsageWidget.app/Contents/MacOS/UsageWidget" >/dev/null 2>&1 || true
        pkill -f "Codex Usage Widget.app/Contents/MacOS/Codex Usage Widget" >/dev/null 2>&1 || true
        rm -rf "$INSTALL_DIR" "$CODEX_HOME/scripts/codex-usage-snapshot.mjs" "$LAUNCHER_APP" "$LAUNCH_AGENT"
        /usr/bin/python3 -c 'import plistlib,subprocess; from pathlib import Path; from urllib.parse import unquote,urlparse; from urllib.request import url2pathname; p=Path.home()/"Library/Preferences/com.apple.dock.plist"; data=plistlib.load(p.open("rb")) if p.exists() else {}; apps=data.get("persistent-apps", []); conv=lambda u: (url2pathname(unquote(urlparse(u).path)).rstrip("/") if isinstance(u,str) and urlparse(u).scheme=="file" else (unquote(u).replace("file://","").rstrip("/") if isinstance(u,str) else "")); new=[x for x in apps if not conv(x.get("tile-data",{}).get("file-data",{}).get("_CFURLString")).endswith("/Codex Usage Widget.app")]; changed=new!=apps; data["persistent-apps"]=new if changed else apps; plistlib.dump(data,p.open("wb")) if changed else None; subprocess.run(["killall","Dock"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL) if changed else None'
        """)
    }

    private func runDetachedShell(_ command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
    }

    private func startWidget() {
        isStartingWidget = true
        startGraceUntil = Date().addingTimeInterval(10.0)
        let markerPath = "\(installDir)/.closed-by-user"
        try? FileManager.default.removeItem(atPath: markerPath)

        let scriptPath = "\(installDir)/ensure-usage-widget.sh"
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
        alert.alertStyle = .informational
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
