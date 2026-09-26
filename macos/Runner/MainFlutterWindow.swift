import Cocoa
import FlutterMacOS
import SwiftUI

private let windowCornerRadius: CGFloat = 12

// Flutter owns all widget content. This host supplies the same OS glass surface
// as the original macOS app, which cannot be sampled by a Flutter backdrop blur.
private struct DesktopGlass: View {
  let light: Bool
  var body: some View {
    Group {
#if compiler(>=6.2)
      if #available(macOS 26.0, *) {
        if light {
          Color.clear.glassEffect(.clear.tint(Color.white.opacity(0.05)).interactive(), in: RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous))
        } else {
          Color.clear.glassEffect(.regular.tint(Color.black.opacity(0.30)).interactive(), in: RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous))
        }
      } else {
        LegacyGlass(light: light)
          .overlay(light ? Color.white.opacity(0.12) : Color.black.opacity(0.38))
          .clipShape(RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous))
      }
#else
      LegacyGlass(light: light)
        .overlay(light ? Color.white.opacity(0.12) : Color.black.opacity(0.38))
        .clipShape(RoundedRectangle(cornerRadius: windowCornerRadius, style: .continuous))
#endif
    }.environment(\.colorScheme, light ? .light : .dark)
  }
}

private struct LegacyGlass: NSViewRepresentable {
  let light: Bool
  func makeNSView(context: Context) -> NSVisualEffectView { NSVisualEffectView() }
  func updateNSView(_ view: NSVisualEffectView, context: Context) {
    view.material = .hudWindow
    view.blendingMode = .behindWindow
    view.state = .active
    view.appearance = NSAppearance(named: light ? .vibrantLight : .vibrantDark)
  }
}

class MainFlutterWindow: NSWindow {
  private var glass: NSHostingView<DesktopGlass>?
  private var desktopChannel: FlutterMethodChannel?
  private var visibilityObservers: [NSObjectProtocol] = []
  private var lastVisible: Bool?

  override var canBecomeKey: Bool { true }
  override var canBecomeMain: Bool { true }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    flutterViewController.backgroundColor = .clear
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    RegisterGeneratedPlugins(registry: flutterViewController)
    super.awakeFromNib()

    isOpaque = false
    backgroundColor = .clear
    // AppKit's wide window shadow darkens the transparent corner quadrants.
    // The rounded glass and its contour retain depth without those artifacts.
    hasShadow = false
    title = "Quota Bubble"
    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask = [.borderless, .fullSizeContentView]
    isMovableByWindowBackground = true

    if let contentView = contentView {
      let backdrop = NSHostingView(rootView: DesktopGlass(light: false))
      backdrop.frame = contentView.bounds
      backdrop.autoresizingMask = [.width, .height]
      contentView.addSubview(backdrop, positioned: .below, relativeTo: flutterViewController.view)
      glass = backdrop
    }

    let channel = FlutterMethodChannel(name: "quota_bubble/desktop", binaryMessenger: flutterViewController.engine.binaryMessenger)
    desktopChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setAppearance" {
        let light = (call.arguments as? [String: Any])?["light"] as? Bool ?? false
        self?.glass?.rootView = DesktopGlass(light: light)
        result(nil)
      } else if call.method == "setPinned" {
        let pinned = (call.arguments as? [String: Any])?["pinned"] as? Bool ?? false
        self?.level = pinned ? .statusBar : .normal
        self?.collectionBehavior = [.managed]
        result(nil)
      } else if call.method == "legacySettings" {
        result(self?.legacySettings())
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    for name in [NSWindow.didChangeOcclusionStateNotification, NSWindow.didMiniaturizeNotification,
                 NSWindow.didDeminiaturizeNotification, NSApplication.didHideNotification,
                 NSApplication.didUnhideNotification] {
      visibilityObservers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
        self?.publishVisibility()
      })
    }
    DispatchQueue.main.async { [weak self] in
      self?.publishVisibility()
    }
  }

  func revealFromDock() {
    orderFrontRegardless()
    makeKey()
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      orderFrontRegardless()
      makeKey()
      publishVisibility()
    }
  }

  private func legacySettings() -> [String: Any] {
    let defaults = UserDefaults.standard
    let frame = Self.legacyFrame(defaults.string(forKey: "NSWindow Frame main"))
    let suffix = Self.closestPreferenceSuffix(defaults: defaults, frame: frame)
    func value(_ base: String) -> Any? {
      if let suffix, let exact = defaults.object(forKey: base + suffix) { return exact }
      return defaults.object(forKey: base)
    }
    var settings: [String: Any] = [:]
    if let light = value("CodexUsageWidget.isLightMode") as? Bool { settings["light"] = light }
    if let pinned = value("CodexUsageWidget.isPinned") as? Bool { settings["pinned"] = pinned }
    if let color = value("CodexUsageWidget.progressColorIndex") as? NSNumber {
      settings["progressColorIndex"] = color.intValue
    }
    if let frame {
      settings["left"] = frame.origin.x
      settings["top"] = NSScreen.screens[0].frame.height - frame.maxY
    }
    return settings
  }

  private static func legacyFrame(_ value: String?) -> NSRect? {
    guard let value else { return nil }
    let numbers = value.split(whereSeparator: { !$0.isNumber && $0 != "." && $0 != "-" })
      .prefix(4).compactMap { Double($0) }
    guard numbers.count == 4 else { return nil }
    return NSRect(x: numbers[0], y: numbers[1], width: numbers[2], height: numbers[3])
  }

  private static func closestPreferenceSuffix(defaults: UserDefaults, frame: NSRect?) -> String? {
    let prefix = "CodexUsageWidget.savedFrame"
    let candidates = defaults.dictionaryRepresentation().compactMap { key, value -> (String, CGFloat)? in
      guard key.hasPrefix(prefix), let stored = value as? String else { return nil }
      let parsed = NSRectFromString(stored)
      let distance: CGFloat
      if let frame {
        let horizontal = abs(parsed.origin.x - frame.origin.x)
        let vertical = abs(parsed.origin.y - frame.origin.y)
        let width = abs(parsed.width - frame.width)
        let height = abs(parsed.height - frame.height)
        distance = horizontal + vertical + width + height
      } else {
        distance = 0
      }
      return (String(key.dropFirst(prefix.count)), distance)
    }
    return candidates.min(by: { $0.1 < $1.1 })?.0
  }

  private func publishVisibility() {
    let visible = !NSApp.isHidden && isVisible && !isMiniaturized && occlusionState.contains(.visible)
    guard visible != lastVisible else { return }
    lastVisible = visible
    desktopChannel?.invokeMethod("visibilityChanged", arguments: visible)
  }
}
