import AppKit
import Combine
import SwiftUI

private let widgetWidth: CGFloat = 330
private let metricCardWidth: CGFloat = 131
private let metricCardSingleLineHeight: CGFloat = 47
private let metricCardDoubleLineHeight: CGFloat = 59
private let paletteEntrySlotDuration: TimeInterval = 0.25
private let rechargeEntryDuration: TimeInterval = paletteEntrySlotDuration * 4
private let rechargePushDuration: TimeInterval = 2
private let rechargePropulsionEntryDuration: TimeInterval = 0.55
private let rechargePropulsionExitDuration: TimeInterval = 0.5
private let rechargeAnimationDuration = rechargeEntryDuration + rechargePushDuration + rechargePropulsionExitDuration
private let rechargePushEndTime = rechargeEntryDuration + rechargePushDuration
private let paletteDepartureDelay = paletteEntrySlotDuration
private let paletteTravelDuration: TimeInterval = 0.125
private let paletteReturnDelay: TimeInterval = 0.06
private let paletteReturnApproachDuration: TimeInterval = 0.2
private let paletteReturnDuration: TimeInterval = 0.25
private let progressPalette: [Color] = [
    Color(red: 0, green: 0.76, blue: 0.16),
    Color(red: 0, green: 0.64, blue: 0.59),
    Color(red: 0.12, green: 0.52, blue: 1),
    Color(red: 0.62, green: 0.34, blue: 1),
    Color(red: 0.78, green: 0.64, blue: 0.35),
]

private func metricCardHeight(for copy: AppCopy) -> CGFloat {
    let font = NSFont.monospacedSystemFont(ofSize: 9, weight: .medium)
    let availableWidth = metricCardWidth - 8
    let titles = ["\(copy.balance)（$）", "\(copy.availableReset)（\(copy.times)）"]
    let needsTwoLines = titles.contains {
        ceil(($0 as NSString).size(withAttributes: [.font: font]).width) > availableWidth
    }
    return needsTwoLines ? metricCardDoubleLineHeight : metricCardSingleLineHeight
}

@MainActor
private func widgetHeight(for store: QuotaStore) -> CGFloat {
    store.desiredHeight + metricCardHeight(for: store.copy) - metricCardSingleLineHeight
}

private enum UpdateLookupResult: Sendable {
    case failed
    case current(tag: String)
    case available(tag: String, assetURL: String)
}

private final class UpdateDownload: NSObject, URLSessionDownloadDelegate {
    private let destination: URL
    private let progressHandler: (Double) -> Void
    private let completionHandler: (Result<URL, Error>) -> Void
    private var session: URLSession?
    private var completed = false

    init(destination: URL, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
        self.destination = destination
        progressHandler = progress
        completionHandler = completion
    }

    func start(url: URL) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: queue)
        self.session = session
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        request.setValue("Quota-Bubble-Updater", forHTTPHeaderField: "User-Agent")
        session.downloadTask(with: request).resume()
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        progressHandler(min(1, max(0, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite))))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)
            finish(.success(destination))
        } catch {
            finish(.failure(error))
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { finish(.failure(error)) }
    }

    private func finish(_ result: Result<URL, Error>) {
        guard !completed else { return }
        completed = true
        session?.finishTasksAndInvalidate()
        session = nil
        completionHandler(result)
    }
}

private func lookupLatestRelease(currentVersion: String?) async -> UpdateLookupResult {
    guard let current = normalizedVersion(currentVersion) else { return .failed }
    var tag: String?
    var assetURL: String?

    if let apiURL = URL(string: "https://api.github.com/repos/itzhaolei/codex-usage-widget/releases/latest") {
        var request = URLRequest(url: apiURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("Quota-Bubble-Updater", forHTTPHeaderField: "User-Agent")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if let (data, response) = try? await URLSession.shared.data(for: request),
           (response as? HTTPURLResponse)?.statusCode == 200,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            tag = json["tag_name"] as? String
            let assets = json["assets"] as? [[String: Any]] ?? []
            assetURL = assets.first(where: { ($0["name"] as? String)?.hasSuffix("macOS-Installer.zip") == true })?["browser_download_url"] as? String
        }
    }

    if tag == nil, let latestURL = URL(string: "https://github.com/itzhaolei/codex-usage-widget/releases/latest") {
        var request = URLRequest(url: latestURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.httpMethod = "HEAD"
        request.setValue("Quota-Bubble-Updater", forHTTPHeaderField: "User-Agent")
        if let (_, response) = try? await URLSession.shared.data(for: request),
           let finalURL = response.url,
           let rawTag = finalURL.pathComponents.last?.removingPercentEncoding,
           finalURL.path.contains("/releases/tag/") {
            tag = rawTag
        }
    }

    guard let tag, let latest = normalizedVersion(tag) else { return .failed }
    guard compareVersions(current, latest) == .orderedAscending else { return .current(tag: tag) }
    if assetURL == nil {
        assetURL = macOSInstallerDownloadURL(for: tag)
    }
    guard let assetURL else { return .failed }
    return .available(tag: tag, assetURL: assetURL)
}

@MainActor
private final class LanguageMenuState: ObservableObject {
    @Published private(set) var languageCode: String
    @Published private(set) var selectedCode: String?

    init() {
        selectedCode = readLanguageOverride()
        languageCode = effectiveLanguageCode()
    }

    var copy: AppCopy { localizedCopy(languageCode) }

    func select(_ code: String?) {
        writeLanguageOverride(code)
        selectedCode = code
        languageCode = effectiveLanguageCode()
    }
}

@main
struct QuotaBubbleApp: App {
    @StateObject private var languageMenu = LanguageMenuState()
    @StateObject private var store = QuotaStore()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Quota Bubble", id: "main") {
            QuotaBubbleRoot(store: store, appDelegate: appDelegate)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Divider()
                NewQuotaWindowButton(languageMenu: languageMenu)
                Divider()
                Menu(languageMenu.copy.language) {
                    Button {
                        languageMenu.select(nil)
                        appDelegate.selectLanguage(nil)
                    } label: {
                        HStack {
                            Text(languageMenu.copy.followSystem)
                            if languageMenu.selectedCode == nil { Image(systemName: "checkmark") }
                        }
                    }
                    Divider()
                    ForEach(supportedLanguages, id: \.code) { language in
                        Button {
                            languageMenu.select(language.code)
                            appDelegate.selectLanguage(language.code)
                        } label: {
                            HStack {
                                Text(language.name)
                                if languageMenu.selectedCode == language.code { Image(systemName: "checkmark") }
                            }
                        }
                    }
                }
                Button(languageMenu.copy.website) { appDelegate.openWebsite() }
                Button(localizedWebsiteShareLabel(languageMenu.languageCode)) { appDelegate.shareWebsite() }
                Button(languageMenu.copy.update) { appDelegate.checkForUpdates() }
                Divider()
                Button(role: .destructive) { appDelegate.confirmUninstall() } label: { Text(languageMenu.copy.uninstall) }
            }
        }
    }
}

private struct NewQuotaWindowButton: View {
    @ObservedObject var languageMenu: LanguageMenuState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(localizedNewWindowLabel(languageMenu.languageCode)) {
            openWindow(id: "main")
        }
        .keyboardShortcut("n", modifiers: .command)
    }
}

private struct QuotaBubbleRoot: View {
    @ObservedObject var store: QuotaStore
    let appDelegate: AppDelegate
    @StateObject private var windowState = WindowState()

    var body: some View {
        QuotaBubbleView(
            store: store,
            windowState: windowState,
            onPinnedChange: { isPinned in
                appDelegate.applyPinnedState(isPinned, to: windowState.window)
            },
            onClose: {
                appDelegate.close(window: windowState.window)
            }
        )
            .background(WindowAccessor { window in
                windowState.window = window
                appDelegate.attach(window: window, store: store, windowState: windowState)
            })
    }
}

private struct QuotaBubbleView: View {
    @ObservedObject var store: QuotaStore
    @ObservedObject var windowState: WindowState
    let onPinnedChange: (Bool) -> Void
    let onClose: () -> Void

    private var primary: Color { windowState.isLightMode ? .black : .white }
    private var secondary: Color { primary.opacity(0.68) }
    private var glassTint: Color {
        windowState.isLightMode ? Color.white.opacity(0.12) : Color.black.opacity(0.38)
    }
    private var liquidGlassTint: Color {
        windowState.isLightMode ? Color.white.opacity(0.05) : Color.black.opacity(0.30)
    }
    private var windowStroke: Color { windowState.isLightMode ? Color.white.opacity(0.56) : primary.opacity(0.14) }

    var body: some View {
        ZStack {
            windowBackground

            VStack(alignment: .leading, spacing: 0) {
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
        }
        .frame(width: widgetWidth, height: widgetHeight(for: store))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(windowStroke, lineWidth: 1))
        .environment(\.colorScheme, windowState.isLightMode ? .light : .dark)
        .onAppear { store.start() }
    }

    @ViewBuilder
    private var windowBackground: some View {
#if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            if windowState.isLightMode {
                Color.clear
                    .glassEffect(
                        .clear.tint(liquidGlassTint).interactive(),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            } else {
                Color.clear
                    .glassEffect(
                        .regular.tint(liquidGlassTint).interactive(),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
        } else {
            VisualEffectView(material: .hudWindow, appearance: windowState.isLightMode ? .vibrantLight : .vibrantDark)
            glassTint
        }
#else
        VisualEffectView(material: .hudWindow, appearance: windowState.isLightMode ? .vibrantLight : .vibrantDark)
        glassTint
#endif
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
            capsuleButton(windowState.isLightMode ? "moon.fill" : "sun.max.fill", help: windowState.isLightMode ? store.copy.switchToDark : store.copy.switchToLight) {
                windowState.toggleTheme()
            }
            divider
            capsuleButton(
                windowState.isPinned ? "pin.fill" : "pin.slash.fill",
                help: windowState.isPinned ? store.copy.unpin : store.copy.pin,
                isActive: windowState.isPinned
            ) {
                windowState.togglePinned()
                onPinnedChange(windowState.isPinned)
            }
            divider
            capsuleButton("xmark", help: store.copy.close, action: onClose)
        }
        .frame(width: 111, height: 28)
        .background(primary.opacity(0.04))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(primary.opacity(0.16), lineWidth: 1))
    }

    private var divider: some View {
        Rectangle().fill(primary.opacity(0.16)).frame(width: 1, height: 16)
    }

    private func capsuleButton(_ symbol: String, help: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? Color.green : primary.opacity(0.76))
                .frame(width: 36, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .animation(.easeOut(duration: 0.16), value: isActive)
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
                QuotaProgressBar(
                    percentage: store.remainingPercentage,
                    emphasizeSparkles: windowState.progressColorIndex == 0,
                    selectedColorIndex: windowState.progressColorIndex,
                    rechargeEvent: store.rechargeAnimationEvent
                )
                    .frame(width: 231, height: 35)
                AnimatedPercentageText(
                    percentage: store.remainingPercentage,
                    rechargeEvent: store.rechargeAnimationEvent
                )
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(primary)
                    .frame(width: 38, alignment: .leading)
            }
            colorPalette
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
        let height = metricCardHeight(for: store.copy)
        return HStack(spacing: 10) {
            MetricCard(title: "\(store.copy.balance)（$）", value: store.balanceText, height: height, lightMode: windowState.isLightMode, secondary: secondary)
            MetricCard(title: "\(store.copy.availableReset)（\(store.copy.times)）", value: store.resetCountText, height: height, lightMode: windowState.isLightMode, secondary: secondary)
        }
        .frame(width: 272, height: height, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var identityRows: some View {
        VStack(spacing: 1) {
            InfoRow(symbol: "person.circle.fill", value: store.accountText, color: secondary)
            InfoRow(symbol: "calendar.badge.clock", value: store.subscriptionText, color: secondary)
        }
    }

    private var colorPalette: some View {
        ColorPaletteView(
            selectedIndex: windowState.progressColorIndex,
            primary: primary,
            rechargeEvent: store.rechargeAnimationEvent,
            onSelect: windowState.selectProgressColor
        )
    }

    private var version: some View {
        HStack(spacing: 4) {
            if store.hasUpdate { Circle().fill(Color.red).frame(width: 4, height: 4) }
            Text(store.versionText)
                .font(.system(size: 9, weight: .light, design: .monospaced))
                .foregroundStyle(secondary)
        }
        .position(x: widgetWidth - 29, y: widgetHeight(for: store) - 15)
    }

}

private struct ColorPaletteView: View {
    let selectedIndex: Int
    let primary: Color
    let rechargeEvent: QuotaRechargeAnimationEvent?
    let onSelect: (Int) -> Void

    @State private var animationStart: Date?

    private let paletteWidth: CGFloat = 231
    private let paletteHeight: CGFloat = 15
    private let progressHeight: CGFloat = 35
    private let progressGap: CGFloat = 4
    private var trackSegmentLength: CGFloat {
        let trackWidth = paletteWidth - 2
        let trackHeight = progressHeight - 2
        return 2 * (trackWidth + trackHeight) / 8
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: animationStart == nil)) { timeline in
            let elapsed = animationStart.map { max(0, timeline.date.timeIntervalSince($0)) }
            ZStack(alignment: .topLeading) {
                staticPalette(isAnimating: elapsed != nil)

                if let elapsed {
                    ForEach(Array(participatingIndices.enumerated()), id: \.element) { queueIndex, colorIndex in
                        let state = segmentState(colorIndex: colorIndex, queueIndex: queueIndex, elapsed: elapsed)
                        if state.trackPhase != nil {
                            Color.clear.frame(width: 1, height: 1)
                        } else if let assemblyProgress = state.assemblyProgress,
                                  let assemblyPhase = state.assemblyPhase {
                            particleAssembly(
                                colorIndex: colorIndex,
                                home: CGPoint(x: 7.5 + CGFloat(colorIndex) * 19, y: paletteHeight / 2),
                                trackPhase: assemblyPhase,
                                progress: assemblyProgress,
                                returning: state.isReturningAssembly
                            )
                        } else {
                            RoundedRectangle(cornerRadius: state.cornerRadius, style: .continuous)
                                .fill(progressPalette[colorIndex])
                                .frame(width: state.width, height: state.height)
                                .shadow(color: progressPalette[colorIndex].opacity(0.5), radius: state.height <= 2 ? 2 : 3)
                                .rotationEffect(.degrees(state.angle))
                                .position(state.position)
                        }
                    }
                }
            }
        }
        .frame(width: paletteWidth, height: paletteHeight, alignment: .leading)
        .task(id: rechargeEvent?.id) { runPaletteAnimation() }
    }

    private var participatingIndices: [Int] {
        progressPalette.indices.filter { $0 != selectedIndex }
    }

    private func staticPalette(isAnimating: Bool) -> some View {
        HStack(spacing: 4) {
            ForEach(progressPalette.indices, id: \.self) { index in
                Button { onSelect(index) } label: {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(progressPalette[index])
                        .frame(width: 12, height: 12)
                        .overlay {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(
                                    selectedIndex == index ? primary.opacity(0.95) : Color.white.opacity(0.18),
                                    lineWidth: selectedIndex == index ? 1.5 : 0.6
                                )
                        }
                        .shadow(
                            color: selectedIndex == index ? progressPalette[index].opacity(0.55) : .clear,
                            radius: 3
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: 15, height: 15)
                .opacity(isAnimating && index != selectedIndex ? 0 : 1)
            }
        }
        .allowsHitTesting(!isAnimating)
    }

    private func runPaletteAnimation() {
        guard let rechargeEvent else { return }
        animationStart = Date()
        let eventID = rechargeEvent.id
        let total = rechargePushEndTime
            + paletteReturnApproachDuration
            + Double(max(0, participatingIndices.count - 1)) * paletteReturnDelay
            + paletteReturnDuration
            + 0.05
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(total * 1_000_000_000))
            guard self.rechargeEvent?.id == eventID else { return }
            animationStart = nil
        }
    }

    private func segmentState(colorIndex: Int, queueIndex: Int, elapsed: TimeInterval) -> PaletteSegmentState {
        let home = CGPoint(x: 7.5 + CGFloat(colorIndex) * 19, y: paletteHeight / 2)
        let departAt = Double(queueIndex) * paletteDepartureDelay
        let arriveAt = departAt + paletteTravelDuration
        let returnAt = rechargePushEndTime
        let exitAt = returnAt
            + paletteReturnApproachDuration
            + Double(queueIndex) * paletteReturnDelay
        let pathAtCurrentTime = perimeterState(
            phase: orbitPhase(colorIndex: colorIndex, queueIndex: queueIndex, at: elapsed)
        )

        if elapsed < departAt {
            return PaletteSegmentState(position: home, width: 12, height: 12, cornerRadius: 3, angle: 0, trackPhase: nil)
        }

        if elapsed < arriveAt {
            let progress = smooth((elapsed - departAt) / paletteTravelDuration)
            return PaletteSegmentState(
                position: interpolate(home, pathAtCurrentTime.position, progress),
                width: interpolate(12, trackSegmentLength, progress),
                height: interpolate(12, 2, progress),
                cornerRadius: interpolate(3, 1, progress),
                angle: pathAtCurrentTime.angle * progress,
                trackPhase: nil,
                assemblyProgress: progress,
                assemblyPhase: homeTrackPhase(colorIndex: colorIndex)
            )
        }

        if elapsed < returnAt {
            return PaletteSegmentState(
                position: pathAtCurrentTime.position,
                width: trackSegmentLength,
                height: 2,
                cornerRadius: 1,
                angle: pathAtCurrentTime.angle,
                trackPhase: orbitPhase(colorIndex: colorIndex, queueIndex: queueIndex, at: elapsed)
            )
        }

        if elapsed < exitAt {
            return PaletteSegmentState(
                position: pathAtCurrentTime.position,
                width: trackSegmentLength,
                height: 2,
                cornerRadius: 1,
                angle: pathAtCurrentTime.angle,
                trackPhase: returnPhase(colorIndex: colorIndex, queueIndex: queueIndex, elapsed: elapsed)
            )
        }

        let returnProgress = smooth((elapsed - exitAt) / paletteReturnDuration)
        let departureState = perimeterState(phase: homeTrackPhase(colorIndex: colorIndex))
        return PaletteSegmentState(
            position: interpolate(departureState.position, home, returnProgress),
            width: interpolate(trackSegmentLength, 12, returnProgress),
            height: interpolate(2, 12, returnProgress),
            cornerRadius: interpolate(1, 3, returnProgress),
            angle: departureState.angle * (1 - returnProgress),
            trackPhase: nil,
            assemblyProgress: returnProgress,
            assemblyPhase: homeTrackPhase(colorIndex: colorIndex),
            isReturningAssembly: true
        )
    }

    private func particleAssembly(
        colorIndex: Int,
        home: CGPoint,
        trackPhase: Double,
        progress: CGFloat,
        returning: Bool
    ) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<36, id: \.self) { index in
                let row = index / 6
                let column = index % 6
                let homePoint = CGPoint(
                    x: home.x - 5 + CGFloat(column) * 2,
                    y: home.y - 5 + CGFloat(row) * 2
                )
                let lineUnit = CGFloat(index) / 35
                let lineOffset = Double((1 - lineUnit) / 8)
                let lane: CGFloat = row.isMultiple(of: 2) ? -0.38 : 0.38
                let snakeIndex = row.isMultiple(of: 2) ? row * 6 + column : row * 6 + (5 - column)
                let rank = CGFloat(snakeIndex) / 35
                let delayed = returning
                    ? smoothParticle(progress, delay: (1 - rank) * 0.22)
                    : smoothParticle(progress, delay: rank * 0.22)
                let journey = returning ? 1 - delayed : delayed
                let position = snakeParticlePosition(
                    home: homePoint,
                    entryPhase: trackPhase,
                    lineOffset: lineOffset,
                    lane: lane,
                    progress: journey,
                    index: index
                )

                RoundedRectangle(cornerRadius: 0.45, style: .continuous)
                    .fill(progressPalette[colorIndex])
                    .frame(width: interpolate(1.85, 1.35, journey), height: 1.65)
                    .shadow(color: progressPalette[colorIndex].opacity(0.42), radius: 0.8)
                    .position(position)
            }
        }
    }

    private func snakeParticlePosition(
        home: CGPoint,
        entryPhase: Double,
        lineOffset: Double,
        lane: CGFloat,
        progress: CGFloat,
        index: Int
    ) -> CGPoint {
        let entryState = perimeterState(phase: entryPhase)
        let ingressEnd: CGFloat = 0.68

        if progress < ingressEnd {
            let raw = progress / ingressEnd
            let eased = raw * raw * (3 - 2 * raw)
            let base = interpolate(home, entryState.position, eased)
            let arc = sin(eased * .pi) * (1.2 + CGFloat((index * 7) % 4) * 0.24)
            return CGPoint(x: base.x, y: base.y - arc)
        }

        let raw = (progress - ingressEnd) / (1 - ingressEnd)
        let eased = raw * raw * (3 - 2 * raw)
        let state = perimeterState(phase: entryPhase - lineOffset * Double(eased))
        let angle = CGFloat(state.angle) * .pi / 180
        return CGPoint(
            x: state.position.x - sin(angle) * lane,
            y: state.position.y + cos(angle) * lane
        )
    }

    private func smoothParticle(_ value: CGFloat, delay: CGFloat) -> CGFloat {
        let available = max(0.001, 1 - delay)
        let local = min(1, max(0, (value - delay) / available))
        return local * local * (3 - 2 * local)
    }

    private func orbitPhase(colorIndex: Int, queueIndex: Int, at elapsed: TimeInterval) -> Double {
        let departAt = Double(queueIndex) * paletteDepartureDelay
        let arriveAt = departAt + paletteTravelDuration
        let positionedAt = departAt + paletteEntrySlotDuration
        let preparedPhase = distributedTrackPhase(queueIndex: queueIndex)
        guard elapsed < rechargeEntryDuration else {
            return preparedPhase + (elapsed - rechargeEntryDuration) * 1.45
        }
        guard elapsed < positionedAt else { return preparedPhase }

        let raw = min(1, max(0, (elapsed - arriveAt) / max(0.001, positionedAt - arriveAt)))
        return counterClockwisePhase(
            from: homeTrackPhase(colorIndex: colorIndex),
            to: preparedPhase,
            progress: smooth(raw)
        )
    }

    private func distributedTrackPhase(queueIndex: Int) -> Double {
        0.125 + Double(queueIndex) * 0.25
    }

    private func counterClockwisePhase(from start: Double, to target: Double, progress: CGFloat) -> Double {
        var delta = normalizedPhase(target) - normalizedPhase(start)
        if delta > 0 { delta -= 1 }
        return start + delta * Double(progress)
    }

    private func returnPhase(colorIndex: Int, queueIndex: Int, elapsed: TimeInterval) -> Double {
        let returnAt = rechargePushEndTime
        let start = normalizedPhase(
            orbitPhase(colorIndex: colorIndex, queueIndex: queueIndex, at: returnAt)
        )
        let target = homeTrackPhase(colorIndex: colorIndex)
        var delta = target - start
        if delta > 0.5 { delta -= 1 }
        if delta < -0.5 { delta += 1 }
        let progress = smooth((elapsed - returnAt) / paletteReturnApproachDuration)
        return start + delta * Double(progress)
    }

    private func homeTrackPhase(colorIndex: Int) -> Double {
        let homeX = min(paletteWidth - 1, max(1, 7.5 + CGFloat(colorIndex) * 19))
        return trackPhase(forX: homeX)
    }

    private func trackPhase(forX x: CGFloat) -> Double {
        let width = paletteWidth - 2
        let height = progressHeight - 2
        let perimeter = 2 * (width + height)
        let distance = width + height + (paletteWidth - 1 - x)
        return Double(distance / perimeter)
    }

    private func normalizedPhase(_ phase: Double) -> Double {
        phase - floor(phase)
    }

    private func perimeterState(phase: Double) -> PalettePathState {
        let top = -(progressHeight + progressGap) + 1
        let bottom = -progressGap - 1
        let left: CGFloat = 1
        let right = paletteWidth - 1
        let width = right - left
        let height = bottom - top
        let perimeter = 2 * (width + height)
        let normalized = phase - floor(phase)
        let distance = CGFloat(normalized) * perimeter

        if distance <= width {
            return PalettePathState(position: CGPoint(x: left + distance, y: top), angle: 0)
        }
        if distance <= width + height {
            return PalettePathState(position: CGPoint(x: right, y: top + distance - width), angle: 90)
        }
        if distance <= width * 2 + height {
            return PalettePathState(position: CGPoint(x: right - (distance - width - height), y: bottom), angle: 180)
        }
        return PalettePathState(position: CGPoint(x: left, y: bottom - (distance - width * 2 - height)), angle: 270)
    }

    private func smooth(_ value: Double) -> CGFloat {
        let clamped = CGFloat(min(1, max(0, value)))
        return clamped * clamped * (3 - 2 * clamped)
    }

    private func interpolate(_ from: CGFloat, _ to: CGFloat, _ progress: CGFloat) -> CGFloat {
        from + (to - from) * progress
    }

    private func interpolate(_ from: CGPoint, _ to: CGPoint, _ progress: CGFloat) -> CGPoint {
        CGPoint(
            x: interpolate(from.x, to.x, progress),
            y: interpolate(from.y, to.y, progress)
        )
    }
}

private struct PaletteSegmentState {
    let position: CGPoint
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let angle: Double
    let trackPhase: Double?
    let assemblyProgress: CGFloat?
    let assemblyPhase: Double?
    let isReturningAssembly: Bool

    init(
        position: CGPoint,
        width: CGFloat,
        height: CGFloat,
        cornerRadius: CGFloat,
        angle: Double,
        trackPhase: Double?,
        assemblyProgress: CGFloat? = nil,
        assemblyPhase: Double? = nil,
        isReturningAssembly: Bool = false
    ) {
        self.position = position
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.angle = angle
        self.trackPhase = trackPhase
        self.assemblyProgress = assemblyProgress
        self.assemblyPhase = assemblyPhase
        self.isReturningAssembly = isReturningAssembly
    }
}

private struct PalettePathState {
    let position: CGPoint
    let angle: Double
}

private struct PaletteTrackSegment: View {
    let phase: Double
    let color: Color
    let paletteWidth: CGFloat
    let progressHeight: CGFloat

    var body: some View {
        Canvas { context, _ in
            let left: CGFloat = 1
            let right = paletteWidth - 1
            let top: CGFloat = 1
            let bottom = progressHeight - 1
            let width = right - left
            let height = bottom - top
            let perimeter = 2 * (width + height)
            let headDistance = CGFloat(phase - floor(phase)) * perimeter
            let segmentLength = perimeter / 8
            let sampleCount = 14

            var path = Path()
            for sample in 0...sampleCount {
                let offset = segmentLength * CGFloat(sampleCount - sample) / CGFloat(sampleCount)
                let point = point(
                    at: headDistance - offset,
                    perimeter: perimeter,
                    left: left,
                    right: right,
                    top: top,
                    bottom: bottom
                )
                if sample == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }

            context.addFilter(.shadow(color: color.opacity(0.55), radius: 2))
            context.stroke(
                path,
                with: .color(color),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
        }
        .allowsHitTesting(false)
    }

    private func point(
        at rawDistance: CGFloat,
        perimeter: CGFloat,
        left: CGFloat,
        right: CGFloat,
        top: CGFloat,
        bottom: CGFloat
    ) -> CGPoint {
        let width = right - left
        let height = bottom - top
        var distance = rawDistance.truncatingRemainder(dividingBy: perimeter)
        if distance < 0 { distance += perimeter }

        if distance <= width { return CGPoint(x: left + distance, y: top) }
        if distance <= width + height { return CGPoint(x: right, y: top + distance - width) }
        if distance <= width * 2 + height {
            return CGPoint(x: right - (distance - width - height), y: bottom)
        }
        return CGPoint(x: left, y: bottom - (distance - width * 2 - height))
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let height: CGFloat
    let lightMode: Bool
    let secondary: Color

    private var titleAreaHeight: CGFloat {
        height > metricCardSingleLineHeight ? 22 : 11
    }

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: metricCardWidth - 8, height: titleAreaHeight, alignment: .top)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(lightMode ? Color.black : Color.white)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .padding(.top, 7)
        .padding(.bottom, 5)
        .frame(width: metricCardWidth, height: height)
        .background {
#if compiler(>=6.2)
            if #available(macOS 26.0, *), lightMode {
                Color.clear
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            } else {
                lightMode ? Color.white.opacity(0.12) : Color.white.opacity(0.07)
            }
#else
            lightMode ? Color.white.opacity(0.12) : Color.white.opacity(0.07)
#endif
        }
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(lightMode ? 0.34 : 0.12)))
        .shadow(color: .black.opacity(lightMode ? 0.07 : 0.22), radius: 10, x: 3, y: 3)
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
    let emphasizeSparkles: Bool
    let selectedColorIndex: Int
    let rechargeEvent: QuotaRechargeAnimationEvent?

    @State private var restingPercentage: CGFloat = 0
    @State private var animationStart: Date?
    @State private var animationFrom: CGFloat = 0
    @State private var animationTo: CGFloat = 0

    private let animationDuration = rechargeAnimationDuration

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: animationStart == nil)) { timeline in
            let frame = rechargeFrame(at: timeline.date)
            let frameColor: Color = frame.percentage <= 20 ? .red : progressPalette[selectedColorIndex]
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    QuotaProgressCanvas(percentage: frame.percentage, color: frameColor)
                    if frame.percentage > 0 {
                        ProgressSparkleField(emphasized: emphasizeSparkles && frame.percentage > 20)
                            .frame(
                                width: geometry.size.width * frame.percentage / 100,
                                height: geometry.size.height,
                                alignment: .leading
                            )
                            .clipped()
                    }
                    if frame.isActive {
                        GoldPropulsionTrail(
                            progress: frame.progress,
                            startFraction: animationFrom / 100,
                            frontFraction: frame.percentage / 100
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                    }
                    ProgressTrackOrbit(
                        selectedIndex: selectedColorIndex,
                        rechargeEvent: rechargeEvent
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .onAppear { restingPercentage = CGFloat(percentage ?? 0) }
        .onChange(of: percentage) { newValue in
            guard animationStart == nil else { return }
            restingPercentage = CGFloat(newValue ?? 0)
        }
        .task(id: rechargeEvent?.id) { runRechargeAnimation() }
    }

    private func runRechargeAnimation() {
        guard let rechargeEvent else { return }
        animationFrom = CGFloat(rechargeEvent.fromPercentage)
        animationTo = CGFloat(rechargeEvent.toPercentage)
        animationStart = Date()
        let animationID = rechargeEvent.id
        let duration = animationDuration
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.05) * 1_000_000_000))
            guard self.rechargeEvent?.id == animationID else { return }
            restingPercentage = animationTo
            animationStart = nil
        }
    }

    private func rechargeFrame(at date: Date) -> RechargeVisualFrame {
        guard let animationStart else {
            return RechargeVisualFrame(percentage: restingPercentage, progress: 1, isActive: false)
        }
        let raw = CGFloat(min(1, max(0, date.timeIntervalSince(animationStart) / animationDuration)))
        let eased = CGFloat(rechargePushProgress(Double(raw)))
        return RechargeVisualFrame(
            percentage: animationFrom + (animationTo - animationFrom) * eased,
            progress: raw,
            isActive: raw < 1
        )
    }
}

private struct ProgressTrackOrbit: View {
    let selectedIndex: Int
    let rechargeEvent: QuotaRechargeAnimationEvent?

    @State private var animationStart: Date?

    private var participatingIndices: [Int] {
        progressPalette.indices.filter { $0 != selectedIndex }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: animationStart == nil)) { timeline in
            let elapsed = animationStart.map { max(0, timeline.date.timeIntervalSince($0)) }
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    if let elapsed {
                        ForEach(Array(participatingIndices.enumerated()), id: \.element) { queueIndex, colorIndex in
                            let arriveAt = Double(queueIndex) * paletteDepartureDelay + paletteTravelDuration
                            let returnAt = rechargePushEndTime
                            let exitAt = returnAt
                                + paletteReturnApproachDuration
                                + Double(queueIndex) * paletteReturnDelay
                            if elapsed >= arriveAt, elapsed < exitAt {
                                PaletteTrackSegment(
                                    phase: trackPhase(
                                        colorIndex: colorIndex,
                                        queueIndex: queueIndex,
                                        elapsed: elapsed,
                                        width: geometry.size.width,
                                        height: geometry.size.height
                                    ),
                                    color: progressPalette[colorIndex],
                                    paletteWidth: geometry.size.width,
                                    progressHeight: geometry.size.height
                                )
                                .frame(width: geometry.size.width, height: geometry.size.height)
                            }
                        }
                    }
                }
            }
        }
        .task(id: rechargeEvent?.id) { runOrbitAnimation() }
        .allowsHitTesting(false)
    }

    private func orbitPhase(
        colorIndex: Int,
        queueIndex: Int,
        elapsed: TimeInterval,
        width: CGFloat,
        height: CGFloat
    ) -> Double {
        let departAt = Double(queueIndex) * paletteDepartureDelay
        let arriveAt = departAt + paletteTravelDuration
        let positionedAt = departAt + paletteEntrySlotDuration
        let preparedPhase = distributedTrackPhase(queueIndex: queueIndex)
        guard elapsed < rechargeEntryDuration else {
            return preparedPhase + (elapsed - rechargeEntryDuration) * 1.45
        }
        guard elapsed < positionedAt else { return preparedPhase }

        let startPhase = homeTrackPhase(colorIndex: colorIndex, width: width, height: height)
        let raw = min(1, max(0, (elapsed - arriveAt) / max(0.001, positionedAt - arriveAt)))
        let eased = raw * raw * (3 - 2 * raw)
        return counterClockwisePhase(from: startPhase, to: preparedPhase, progress: eased)
    }

    private func distributedTrackPhase(queueIndex: Int) -> Double {
        0.125 + Double(queueIndex) * 0.25
    }

    private func counterClockwisePhase(from start: Double, to target: Double, progress: Double) -> Double {
        var delta = normalizedPhase(target) - normalizedPhase(start)
        if delta > 0 { delta -= 1 }
        return start + delta * progress
    }

    private func trackPhase(
        colorIndex: Int,
        queueIndex: Int,
        elapsed: TimeInterval,
        width: CGFloat,
        height: CGFloat
    ) -> Double {
        let returnAt = rechargePushEndTime
        guard elapsed >= returnAt else {
            return orbitPhase(
                colorIndex: colorIndex,
                queueIndex: queueIndex,
                elapsed: elapsed,
                width: width,
                height: height
            )
        }

        let start = normalizedPhase(
            orbitPhase(
                colorIndex: colorIndex,
                queueIndex: queueIndex,
                elapsed: returnAt,
                width: width,
                height: height
            )
        )
        let target = homeTrackPhase(colorIndex: colorIndex, width: width, height: height)
        var delta = target - start
        if delta > 0.5 { delta -= 1 }
        if delta < -0.5 { delta += 1 }
        let raw = min(1, max(0, (elapsed - returnAt) / paletteReturnApproachDuration))
        let eased = raw * raw * (3 - 2 * raw)
        return start + delta * eased
    }

    private func homeTrackPhase(colorIndex: Int, width: CGFloat, height: CGFloat) -> Double {
        let left: CGFloat = 1
        let right = width - 1
        let homeX = min(right, max(left, 7.5 + CGFloat(colorIndex) * 19))
        return trackPhase(forX: homeX, width: width, height: height)
    }

    private func trackPhase(forX x: CGFloat, width: CGFloat, height: CGFloat) -> Double {
        let left: CGFloat = 1
        let right = width - 1
        let trackWidth = right - left
        let trackHeight = height - 2
        let perimeter = 2 * (trackWidth + trackHeight)
        guard perimeter > 0 else { return 0 }
        let distance = trackWidth + trackHeight + (right - x)
        return Double(distance / perimeter)
    }

    private func normalizedPhase(_ phase: Double) -> Double {
        phase - floor(phase)
    }

    private func runOrbitAnimation() {
        guard let rechargeEvent else { return }
        animationStart = Date()
        let eventID = rechargeEvent.id
        let total = rechargePushEndTime
            + paletteReturnApproachDuration
            + Double(max(0, participatingIndices.count - 1)) * paletteReturnDelay
            + 0.05
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(total * 1_000_000_000))
            guard self.rechargeEvent?.id == eventID else { return }
            animationStart = nil
        }
    }
}

private struct ProgressSparkleField: View {
    let emphasized: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1 / 15)) { timeline in
            Canvas { context, size in
                guard size.width > 0, size.height > 0 else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate

                for index in 0..<(emphasized ? 58 : 46) {
                    let speed = 0.006 + pseudoRandom(index * 17 + 3) * 0.014
                    let xUnit = positiveRemainder(pseudoRandom(index * 19 + 5) + time * speed, divisor: 1)
                    let baseY = 0.12 + pseudoRandom(index * 23 + 7) * 0.76
                    let drift = sin(time * (0.7 + pseudoRandom(index * 29 + 11)) + Double(index)) * 1.2
                    let y = size.height * baseY + CGFloat(drift)
                    let pulse = (sin(time * (1.4 + pseudoRandom(index * 31 + 13) * 2.2) + Double(index) * 1.7) + 1) / 2
                    let opacity = (emphasized ? 0.16 : 0.08) + pow(pulse, 3) * (emphasized ? 0.78 : 0.62)
                    let diameter = (emphasized ? 0.75 : 0.55) + pseudoRandom(index * 37 + 17) * (emphasized ? 1.35 : 1.15)
                    let rect = CGRect(
                        x: size.width * xUnit - diameter / 2,
                        y: y - diameter / 2,
                        width: diameter,
                        height: diameter
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
                }

                for index in 0..<(emphasized ? 11 : 8) {
                    let speed = 0.004 + pseudoRandom(index * 41 + 19) * 0.008
                    let xUnit = positiveRemainder(pseudoRandom(index * 43 + 23) + time * speed, divisor: 1)
                    let y = size.height * (0.2 + pseudoRandom(index * 47 + 29) * 0.6)
                    let pulse = (sin(time * (1.1 + pseudoRandom(index * 53 + 31) * 1.5) + Double(index) * 2.3) + 1) / 2
                    let radius = CGFloat(1.2 + pulse * 1.25)
                    let center = CGPoint(x: size.width * xUnit, y: y)
                    var star = Path()
                    star.move(to: CGPoint(x: center.x - radius, y: center.y))
                    star.addLine(to: CGPoint(x: center.x + radius, y: center.y))
                    star.move(to: CGPoint(x: center.x, y: center.y - radius))
                    star.addLine(to: CGPoint(x: center.x, y: center.y + radius))
                    let opacity = (emphasized ? 0.2 : 0.12) + pulse * (emphasized ? 0.72 : 0.58)
                    context.stroke(star, with: .color(.white.opacity(opacity)), lineWidth: emphasized ? 0.7 : 0.55)
                }
            }
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    private func positiveRemainder(_ value: Double, divisor: Double) -> CGFloat {
        CGFloat(value - floor(value / divisor) * divisor)
    }

    private func pseudoRandom(_ seed: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898) * 43_758.5453
        return CGFloat(value - floor(value))
    }
}

private struct RechargeVisualFrame {
    let percentage: CGFloat
    let progress: CGFloat
    let isActive: Bool
}

private func rechargePushProgress(_ rawProgress: Double) -> Double {
    let entryFraction = rechargeEntryDuration / rechargeAnimationDuration
    let pushFraction = rechargePushDuration / rechargeAnimationDuration
    let push = min(1, max(0, (rawProgress - entryFraction) / pushFraction))
    return push * push * (3 - 2 * push)
}

private struct GoldPropulsionTrail: View {
    let progress: CGFloat
    let startFraction: CGFloat
    let frontFraction: CGFloat

    private let gold = Color(red: 1, green: 0.58, blue: 0.02)

    var body: some View {
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else { return }
            let centerY = size.height / 2
            let trailLength = min(145, size.width * 0.62)
            let headX = propulsionHeadX(in: size.width, trailLength: trailLength)
            let tailStart = headX - trailLength
            let drawStart = max(0, tailStart)
            let drawEnd = min(size.width, headX)
            guard drawEnd > drawStart else { return }

            for index in 0..<8 {
                let depth = CGFloat(index) / 7
                let amplitude = 2.2 + pseudoRandom(index * 17 + 3) * 7
                let cycles = 0.7 + pseudoRandom(index * 19 + 5) * 1.25
                let speed = 0.55 + pseudoRandom(index * 23 + 7) * 1.5
                let phase = progress * speed * 2 * .pi + pseudoRandom(index * 29 + 11) * 2 * .pi
                let baseOffset = (pseudoRandom(index * 31 + 13) - 0.5) * size.height * 0.42
                let lineWidth = 0.45 + (1 - depth) * 0.75

                var previous: CGPoint?
                for x in stride(from: drawStart, through: drawEnd, by: 3) {
                    let unit = min(1, max(0, (x - tailStart) / trailLength))
                    let convergence = pow(max(0, 1 - unit), 0.72)
                    let primaryAngle = Double(unit * cycles * 2 * .pi + phase)
                    let secondaryCycles = cycles * 0.47
                    let secondaryAngle = Double(unit * secondaryCycles * 2 * .pi - phase * 0.42)
                    let wave = CGFloat(sin(primaryAngle))
                    let secondary = CGFloat(sin(secondaryAngle)) * 0.34
                    let y = centerY + (baseOffset + (wave + secondary) * amplitude) * convergence
                    let point = CGPoint(x: x, y: y)
                    if let previous {
                        var segment = Path()
                        segment.move(to: previous)
                        segment.addLine(to: point)
                        let tail = pow(unit, 1.45)
                        let opacity = (0.08 + tail * 0.72) * (0.48 + (1 - depth) * 0.52)
                        context.stroke(segment, with: .color(gold.opacity(opacity)), lineWidth: lineWidth)
                    }
                    previous = point
                }
            }

            for index in 0..<52 {
                let velocity = 0.06 + pseudoRandom(index * 41 + 19) * 0.16
                let shifted = pseudoRandom(index * 37 + 17) + progress * velocity
                let unit = shifted - floor(shifted)
                let x = tailStart + unit * trailLength
                guard x >= 0, x <= size.width else { continue }
                let y = pseudoRandom(index * 43 + 23) * size.height
                let diameter = 0.45 + pseudoRandom(index * 47 + 29) * 1.05
                let opacity = 0.05 + pow(unit, 1.8) * 0.55
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                    with: .color(gold.opacity(opacity))
                )
            }

            let glowWidth = min(11, trailLength)
            let glowRect = CGRect(
                x: headX - glowWidth,
                y: centerY - size.height * 0.38,
                width: glowWidth,
                height: size.height * 0.76
            )
            context.fill(
                Path(roundedRect: glowRect, cornerRadius: size.height * 0.38),
                with: .linearGradient(
                    Gradient(colors: [.clear, gold.opacity(0.08), gold.opacity(0.42)]),
                    startPoint: CGPoint(x: glowRect.minX, y: centerY),
                    endPoint: CGPoint(x: glowRect.maxX, y: centerY)
                )
            )

            let coreWidth = min(3.6, trailLength)
            let coreRect = CGRect(
                x: headX - coreWidth,
                y: centerY - size.height * 0.2,
                width: coreWidth,
                height: size.height * 0.4
            )
            context.fill(
                Path(roundedRect: coreRect, cornerRadius: size.height * 0.2),
                with: .linearGradient(
                    Gradient(colors: [gold.opacity(0.16), gold.opacity(0.95)]),
                    startPoint: CGPoint(x: coreRect.minX, y: centerY),
                    endPoint: CGPoint(x: coreRect.maxX, y: centerY)
                )
            )
        }
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    private func propulsionHeadX(in width: CGFloat, trailLength: CGFloat) -> CGFloat {
        let entryStartFraction = CGFloat(
            (rechargeEntryDuration - rechargePropulsionEntryDuration) / rechargeAnimationDuration
        )
        let entryFraction = CGFloat(rechargeEntryDuration / rechargeAnimationDuration)
        let pushEndFraction = CGFloat(rechargePushEndTime / rechargeAnimationDuration)
        let exitFraction = max(0.001, 1 - pushEndFraction)

        if progress < entryStartFraction {
            return -trailLength * 0.08
        }
        if progress < entryFraction {
            let raw = max(0, (progress - entryStartFraction) / max(0.001, entryFraction - entryStartFraction))
            let eased = raw * raw * (3 - 2 * raw)
            return -trailLength * 0.08 + (width * startFraction + trailLength * 0.08) * eased
        }
        if progress <= pushEndFraction {
            return width * frontFraction
        }
        let raw = min(1, max(0, (progress - pushEndFraction) / exitFraction))
        let eased = raw * raw * (3 - 2 * raw)
        return width + trailLength * eased
    }

    private func pseudoRandom(_ seed: Int) -> CGFloat {
        let value = sin(Double(seed) * 12.9898) * 43_758.5453
        return CGFloat(value - floor(value))
    }
}

private struct QuotaProgressCanvas: View {
    let percentage: CGFloat
    let color: Color

    var body: some View {
        Canvas { context, size in
            let percent = min(100, max(0, percentage)) / 100
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

private struct AnimatedPercentageText: View {
    let percentage: Int?
    let rechargeEvent: QuotaRechargeAnimationEvent?

    @State private var restingPercentage: Double = 0
    @State private var animationStart: Date?
    @State private var animationFrom: Double = 0
    @State private var animationTo: Double = 0

    private let animationDuration = rechargeAnimationDuration

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: animationStart == nil)) { timeline in
            Group {
                if percentage == nil {
                    Text("—")
                } else {
                    Text("\(Int(displayedPercentage(at: timeline.date).rounded()))%")
                }
            }
        }
        .onAppear { restingPercentage = Double(percentage ?? 0) }
        .onChange(of: percentage) { newValue in
            guard animationStart == nil else { return }
            restingPercentage = Double(newValue ?? 0)
        }
        .task(id: rechargeEvent?.id) { runRechargeAnimation() }
    }

    private func displayedPercentage(at date: Date) -> Double {
        guard let animationStart else { return restingPercentage }
        let raw = min(1, max(0, date.timeIntervalSince(animationStart) / animationDuration))
        let eased = rechargePushProgress(raw)
        return animationFrom + (animationTo - animationFrom) * eased
    }

    private func runRechargeAnimation() {
        guard let rechargeEvent else { return }
        animationFrom = Double(rechargeEvent.fromPercentage)
        animationTo = Double(rechargeEvent.toPercentage)
        animationStart = Date()
        let animationID = rechargeEvent.id
        let duration = animationDuration
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64((duration + 0.05) * 1_000_000_000))
            guard self.rechargeEvent?.id == animationID else { return }
            restingPercentage = animationTo
            animationStart = nil
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
        view.appearance = NSAppearance(named: appearance)
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.appearance = NSAppearance(named: appearance)
        view.isEmphasized = true
    }
}

@MainActor
private final class WindowState: ObservableObject {
    weak var window: NSWindow?
    @Published private(set) var isLightMode = UserDefaults.standard.bool(forKey: QuotaStore.lightModeKey)
    @Published private(set) var isPinned = UserDefaults.standard.object(forKey: QuotaStore.pinnedKey) as? Bool ?? true
    @Published private(set) var progressColorIndex = min(4, max(0, UserDefaults.standard.integer(forKey: QuotaStore.progressColorKey)))

    private var lightModeKey: String?
    private var pinnedKey: String?
    private var progressColorKey: String?

    func configure(preferenceIndex: Int) {
        guard lightModeKey == nil else { return }
        let suffix = preferenceIndex == 0 ? "" : ".\(preferenceIndex)"
        lightModeKey = QuotaStore.lightModeKey + suffix
        pinnedKey = QuotaStore.pinnedKey + suffix
        progressColorKey = QuotaStore.progressColorKey + suffix

        let defaults = UserDefaults.standard
        if let lightModeKey, defaults.object(forKey: lightModeKey) != nil {
            isLightMode = defaults.bool(forKey: lightModeKey)
        }
        if let pinnedKey, let saved = defaults.object(forKey: pinnedKey) as? Bool {
            isPinned = saved
        }
        if let progressColorKey, defaults.object(forKey: progressColorKey) != nil {
            progressColorIndex = min(4, max(0, defaults.integer(forKey: progressColorKey)))
        }
    }

    func toggleTheme() {
        isLightMode.toggle()
        if let lightModeKey { UserDefaults.standard.set(isLightMode, forKey: lightModeKey) }
    }

    func togglePinned() {
        isPinned.toggle()
        if let pinnedKey { UserDefaults.standard.set(isPinned, forKey: pinnedKey) }
    }

    func selectProgressColor(_ index: Int) {
        guard (0..<progressPalette.count).contains(index) else { return }
        progressColorIndex = index
        if let progressColorKey { UserDefaults.standard.set(index, forKey: progressColorKey) }
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
    private var windows: [ObjectIdentifier: NSWindow] = [:]
    private var windowFrameKeys: [ObjectIdentifier: String] = [:]
    private var windowPreferenceIndexes: [ObjectIdentifier: Int] = [:]
    private weak var activeWindow: NSWindow?
    private weak var store: QuotaStore?
    private var storeCancellables = Set<AnyCancellable>()
    private var updateWindow: NSWindow?
    private var updateDownload: UpdateDownload?
    private weak var updateProgressIndicator: NSProgressIndicator?
    private weak var updateProgressLabel: NSTextField?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        (activeWindow ?? windows.values.first)?.makeKeyAndOrderFront(nil)
        sender.activate(ignoringOtherApps: true)
        return true
    }

    func selectLanguage(_ code: String?) {
        store?.selectLanguage(code)
    }

    func openWebsite() {
        guard let url = URL(string: officialWebsiteURLString) else { return }
        NSWorkspace.shared.open(url)
    }

    func shareWebsite() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(officialWebsiteURLString, forType: .string)

        let code = store?.languageCode ?? effectiveLanguageCode()
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = localizedWebsiteCopiedMessage(code)
        alert.informativeText = officialWebsiteURLString
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    fileprivate func attach(window: NSWindow, store: QuotaStore, windowState: WindowState) {
        observeStoreIfNeeded(store)
        let identifier = ObjectIdentifier(window)
        guard windows[identifier] == nil else {
            resizeWindow(window, store: store)
            return
        }
        let cascadeSource = activeWindow ?? NSApp.keyWindow
        let usedIndexes = Set(windowPreferenceIndexes.values)
        let windowIndex = (0...).first { !usedIndexes.contains($0) } ?? 0
        windowState.configure(preferenceIndex: windowIndex)
        windows[identifier] = window
        windowPreferenceIndexes[identifier] = windowIndex
        windowFrameKeys[identifier] = windowIndex == 0 ? QuotaStore.savedFrameKey : "\(QuotaStore.savedFrameKey).\(windowIndex)"
        window.delegate = self
        window.title = "Quota Bubble"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.styleMask = [.borderless, .fullSizeContentView]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.isMovableByWindowBackground = true
        window.contentMinSize = NSSize(width: widgetWidth, height: 234)
        window.contentMaxSize = NSSize(width: widgetWidth, height: 1_000)
        restoreWindowFrame(window, store: store, cascadeFrom: cascadeSource)
        activeWindow = window
        applyPinnedState(windowState.isPinned, to: window)
        window.makeKeyAndOrderFront(nil)
        DispatchQueue.main.async { [weak self, weak window] in
            guard let self, let window else { return }
            self.resizeWindow(window, store: store, force: true)
            self.applyPinnedState(windowState.isPinned, to: window)
        }
    }

    private func observeStoreIfNeeded(_ store: QuotaStore) {
        guard self.store !== store else { return }
        self.store = store
        storeCancellables.removeAll()
        store.$resetRows.dropFirst().receive(on: RunLoop.main).sink { [weak self] _ in self?.resizeAllWindows() }.store(in: &storeCancellables)
        store.$languageCode.dropFirst().receive(on: RunLoop.main).sink { [weak self] _ in self?.resizeAllWindows() }.store(in: &storeCancellables)
    }

    func applyPinnedState(_ isPinned: Bool, to window: NSWindow?) {
        window?.level = isPinned ? .statusBar : .normal
        window?.collectionBehavior = [.managed]
    }

    func close(window: NSWindow?) {
        guard let target = window ?? NSApp.keyWindow ?? activeWindow else { return }
        let visibleWindows = windows.values.filter(\.isVisible)
        if visibleWindows.count <= 1 {
            NSApp.terminate(nil)
            return
        }
        saveFrame(target)
        target.orderOut(nil)
        unregisterWindow(target)
    }

    func windowDidBecomeKey(_ notification: Notification) {
        activeWindow = notification.object as? NSWindow
    }

    func windowDidBecomeMain(_ notification: Notification) {
        activeWindow = notification.object as? NSWindow
    }

    private func resizeAllWindows() {
        guard let store else { return }
        for window in windows.values { resizeWindow(window, store: store) }
    }

    private func resizeWindow(_ window: NSWindow, store: QuotaStore, force: Bool = false) {
        let desired = widgetHeight(for: store)
        let contentSize = window.contentView?.frame.size ?? .zero
        guard force || abs(contentSize.width - widgetWidth) > 0.5 || abs(contentSize.height - desired) > 0.5 else { return }
        let top = window.frame.maxY
        window.setContentSize(NSSize(width: widgetWidth, height: desired))
        window.setFrameOrigin(NSPoint(x: window.frame.minX, y: top - window.frame.height))
    }

    private func restoreWindowFrame(_ window: NSWindow, store: QuotaStore, cascadeFrom source: NSWindow?) {
        let identifier = ObjectIdentifier(window)
        let frameKey = windowFrameKeys[identifier] ?? QuotaStore.savedFrameKey
        window.setContentSize(NSSize(width: widgetWidth, height: widgetHeight(for: store)))
        if let value = UserDefaults.standard.string(forKey: frameKey) {
            let saved = NSRectFromString(value)
            window.setFrameOrigin(NSPoint(x: saved.minX, y: saved.maxY - window.frame.height))
        } else if let source, source !== window {
            window.setFrameOrigin(NSPoint(x: source.frame.minX + 24, y: source.frame.minY - 24))
        } else {
            window.center()
        }
    }

    func windowDidMove(_ notification: Notification) {
        if let window = notification.object as? NSWindow { saveFrame(window) }
    }

    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow { saveFrame(window) }
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        saveFrame(window)
        unregisterWindow(window)
    }

    private func unregisterWindow(_ window: NSWindow) {
        let identifier = ObjectIdentifier(window)
        windows.removeValue(forKey: identifier)
        windowFrameKeys.removeValue(forKey: identifier)
        windowPreferenceIndexes.removeValue(forKey: identifier)
        if activeWindow === window { activeWindow = windows.values.first }
    }

    private func saveFrame(_ window: NSWindow) {
        let identifier = ObjectIdentifier(window)
        guard let key = windowFrameKeys[identifier] else { return }
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: key)
    }

    func checkForUpdates() {
        let dialogs = localizedDialogCopy(store?.languageCode ?? "en")
        showUpdateStatus(title: store?.copy.update ?? "Update", message: dialogs.checking, final: false)
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        Task { [weak self] in
            let result = await lookupLatestRelease(currentVersion: currentVersion)
            guard let self else { return }
            switch result {
            case .failed:
                self.showUpdateStatus(title: dialogs.updateFailed, message: "", final: true)
            case let .current(tag):
                self.showUpdateStatus(title: dialogs.upToDate, message: tag, final: true)
            case let .available(tag, assetURL):
                self.showUpdateStatus(title: dialogs.downloading, message: tag, final: false, progress: 0)
                self.installUpdate(assetURL: assetURL, tag: tag)
            }
        }
    }

    private func installUpdate(assetURL: String, tag: String) {
        guard let url = URL(string: assetURL) else {
            showUpdateStatus(title: localizedDialogCopy(store?.languageCode ?? "en").updateFailed, message: "", final: true)
            return
        }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("quota-bubble-update-\(UUID().uuidString)", isDirectory: true)
        do { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) } catch {
            showUpdateStatus(title: localizedDialogCopy(store?.languageCode ?? "en").updateFailed, message: error.localizedDescription, final: true)
            return
        }
        let archive = directory.appendingPathComponent("installer.zip")
        let download = UpdateDownload(destination: archive, progress: { [weak self] value in
            DispatchQueue.main.async { self?.updateDownloadProgress(value) }
        }, completion: { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                self.updateDownload = nil
                switch result {
                case let .success(archive): self.installDownloadedUpdate(archive: archive, directory: directory, tag: tag)
                case let .failure(error):
                    try? FileManager.default.removeItem(at: directory)
                    self.showUpdateStatus(title: localizedDialogCopy(self.store?.languageCode ?? "en").updateFailed, message: error.localizedDescription, final: true)
                }
            }
        })
        updateDownload = download
        download.start(url: url)
    }

    private func installDownloadedUpdate(archive: URL, directory: URL, tag: String) {
        let command = "set -euo pipefail; /usr/bin/ditto -x -k \(shellQuote(archive.path)) \(shellQuote(directory.path)); installer=\(shellQuote(directory.appendingPathComponent("Install Quota Bubble.app/Contents/Resources/install-packaged.sh").path)); test -f \"$installer\"; /usr/bin/env QUOTA_BUBBLE_KEEP_RUNNING=1 QUOTA_BUBBLE_SKIP_LAUNCH=1 QUOTA_BUBBLE_SKIP_DOCK=1 /bin/bash \"$installer\""
        let completion: @MainActor @Sendable (Int32, String) -> Void = { [weak self] status, detail in
            guard let self else { return }
            try? FileManager.default.removeItem(at: directory)
            let dialogs = localizedDialogCopy(self.store?.languageCode ?? "en")
            let message = status == 0 || detail.isEmpty ? tag : detail
            if status == 0 {
                self.store?.markUpdateInstalled()
                self.showUpdateStatus(title: dialogs.updateComplete, message: message, final: false, progress: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in self?.restartAfterUpdate() }
            } else {
                self.showUpdateStatus(title: dialogs.updateFailed, message: message, final: true)
            }
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]
        process.standardOutput = FileHandle.nullDevice
        let errorPipe = Pipe()
        process.standardError = errorPipe
        process.terminationHandler = { process in
            let status = process.terminationStatus
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let detail = String(raw.suffix(240))
            Task { @MainActor in completion(status, detail) }
        }
        do {
            try process.run()
        } catch {
            Task { @MainActor in completion(-1, error.localizedDescription) }
        }
    }

    private func restartAfterUpdate() {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let installedApp = "/Applications/Quota Bubble.app"
        let command = "while /bin/kill -0 \(currentPID) >/dev/null 2>&1; do /bin/sleep 0.1; done; /usr/bin/open -g \(shellQuote(installedApp))"
        let helper = Process()
        helper.executableURL = URL(fileURLWithPath: "/bin/zsh")
        helper.arguments = ["-lc", command]
        helper.standardOutput = FileHandle.nullDevice
        helper.standardError = FileHandle.nullDevice
        do {
            try helper.run()
            NSApp.terminate(nil)
        } catch {
            let dialogs = localizedDialogCopy(store?.languageCode ?? "en")
            showUpdateStatus(title: dialogs.updateFailed, message: error.localizedDescription, final: true)
        }
    }

    private func showUpdateStatus(title: String, message: String, final: Bool, progress: Double? = nil) {
        if updateWindow == nil {
            let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 360, height: 132), styleMask: [.titled, .closable], backing: .buffered, defer: false)
            panel.level = .floating
            panel.center()
            updateWindow = panel
        }
        guard let content = updateWindow?.contentView else { return }
        content.subviews.forEach { $0.removeFromSuperview() }
        updateProgressIndicator = nil
        updateProgressLabel = nil
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = .boldSystemFont(ofSize: 15)
        titleLabel.frame = NSRect(x: 22, y: 75, width: 316, height: 22)
        content.addSubview(titleLabel)
        let info = NSTextField(labelWithString: message)
        info.textColor = .secondaryLabelColor
        info.lineBreakMode = .byWordWrapping
        info.maximumNumberOfLines = 2
        info.frame = NSRect(x: 22, y: progress == nil ? 38 : 48, width: 316, height: progress == nil ? 36 : 22)
        content.addSubview(info)
        if let progress {
            let indicator = NSProgressIndicator(frame: NSRect(x: 22, y: 27, width: 316, height: 10))
            indicator.style = .bar
            indicator.isIndeterminate = false
            indicator.minValue = 0
            indicator.maxValue = 1
            indicator.doubleValue = progress
            content.addSubview(indicator)
            updateProgressIndicator = indicator

            let percentage = NSTextField(labelWithString: "\(Int((progress * 100).rounded()))%")
            percentage.alignment = .right
            percentage.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
            percentage.textColor = .secondaryLabelColor
            percentage.frame = NSRect(x: 278, y: 8, width: 60, height: 16)
            content.addSubview(percentage)
            updateProgressLabel = percentage
        }
        if final {
            let button = NSButton(title: "OK", target: updateWindow, action: #selector(NSWindow.orderOut(_:)))
            button.frame = NSRect(x: 268, y: 12, width: 70, height: 28)
            content.addSubview(button)
        }
        updateWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func updateDownloadProgress(_ value: Double) {
        let progress = min(1, max(0, value))
        updateProgressIndicator?.doubleValue = progress
        updateProgressLabel?.stringValue = "\(Int((progress * 100).rounded()))%"
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
