import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let installDir = NSString(string: "~/.codex/usage-widget").expandingTildeInPath
    private let launcherBundleIdentifier = "local.codex.usage-widget.launcher"
    private let widgetBundleIdentifier = "local.codex.usage-widget"
    private var monitorTimer: Timer?
    private var isStartingWidget = false
    private var isExitingAfterWidgetClosed = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        if activateExistingLauncherIfNeeded() {
            isExitingAfterWidgetClosed = true
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.regular)
        startWidget()
        startMonitoringWidget()
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
        let markerPath = "\(installDir)/.closed-by-user"
        try? FileManager.default.removeItem(atPath: markerPath)

        let scriptPath = "\(installDir)/ensure-usage-widget.sh"
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            isStartingWidget = false
            showAlert(message: "Codex Usage Widget 尚未安装",
                      info: "请先在插件目录执行 bash scripts/install.sh。")
            return
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [scriptPath]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isStartingWidget = false
            }
        } catch {
            isStartingWidget = false
            showAlert(message: "启动失败", info: error.localizedDescription)
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
            if self.isStartingWidget { return }
            if !self.widgetIsRunning() {
                self.isExitingAfterWidgetClosed = true
                NSApp.terminate(nil)
            }
        }
    }

    private func widgetIsRunning() -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: widgetBundleIdentifier).isEmpty
    }

    private func closeWidgetFromLauncher() {
        let markerPath = "\(installDir)/.closed-by-user"
        FileManager.default.createFile(atPath: markerPath, contents: Data(), attributes: nil)

        for app in NSRunningApplication.runningApplications(withBundleIdentifier: widgetBundleIdentifier) {
            app.terminate()
        }

        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.5) {
            for app in NSRunningApplication.runningApplications(withBundleIdentifier: self.widgetBundleIdentifier) {
                app.forceTerminate()
            }
        }
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
