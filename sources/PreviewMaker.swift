import Cocoa

let outputPath = CommandLine.arguments.dropFirst().first ?? "assets/preview.png"
let size = NSSize(width: 1400, height: 900)
let image = NSImage(size: size)

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawText(_ text: String, at point: NSPoint, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color
    ]
    text.draw(at: point, withAttributes: attrs)
}

func drawMono(_ text: String, at point: NSPoint, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: size, weight: weight),
        .foregroundColor: color
    ]
    text.draw(at: point, withAttributes: attrs)
}

func drawBar(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, percent: CGFloat, color: NSColor) {
    let track = roundedRect(NSRect(x: x, y: y, width: width, height: height), radius: height / 2)
    NSColor(calibratedWhite: 1, alpha: 0.12).setFill()
    track.fill()

    let fill = roundedRect(NSRect(x: x, y: y, width: width * percent, height: height), radius: height / 2)
    color.setFill()
    fill.fill()
}

image.lockFocus()

NSColor(calibratedRed: 0.05, green: 0.06, blue: 0.07, alpha: 1).setFill()
NSRect(origin: .zero, size: size).fill()

let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.08, alpha: 1),
    NSColor(calibratedRed: 0.02, green: 0.02, blue: 0.03, alpha: 1)
])
background?.draw(in: NSRect(origin: .zero, size: size), angle: 28)

let glow = NSBezierPath(ovalIn: NSRect(x: 180, y: 120, width: 1040, height: 620))
NSColor(calibratedRed: 0.06, green: 0.85, blue: 0.33, alpha: 0.16).setFill()
glow.fill()

let widgetRect = NSRect(x: 355, y: 255, width: 690, height: 390)
NSColor(calibratedWhite: 0, alpha: 0.52).setFill()
roundedRect(widgetRect.offsetBy(dx: 0, dy: -18), radius: 32).fill()
NSColor(calibratedWhite: 1, alpha: 0.10).setFill()
roundedRect(widgetRect, radius: 32).fill()
NSColor(calibratedWhite: 0.02, alpha: 0.78).setFill()
roundedRect(widgetRect.insetBy(dx: 2, dy: 2), radius: 30).fill()

drawText("Codex 额度", at: NSPoint(x: 410, y: 570), size: 34, weight: .bold, color: .white)

let capsule = NSRect(x: 838, y: 560, width: 150, height: 46)
NSColor(calibratedWhite: 1, alpha: 0.08).setFill()
roundedRect(capsule, radius: 23).fill()
drawText("◐", at: NSPoint(x: 868, y: 571), size: 21, weight: .semibold, color: NSColor(calibratedWhite: 1, alpha: 0.72))
drawText("⌖", at: NSPoint(x: 913, y: 571), size: 20, weight: .semibold, color: NSColor(calibratedWhite: 1, alpha: 0.72))
drawText("×", at: NSPoint(x: 956, y: 568), size: 26, weight: .semibold, color: NSColor(calibratedWhite: 1, alpha: 0.72))

let secondary = NSColor(calibratedWhite: 1, alpha: 0.72)
let green = NSColor(calibratedRed: 0.05, green: 0.86, blue: 0.34, alpha: 1)
let red = NSColor(calibratedRed: 1, green: 0.22, blue: 0.18, alpha: 1)

drawMono("5h", at: NSPoint(x: 410, y: 500), size: 28, weight: .bold, color: .white)
drawMono("┃", at: NSPoint(x: 468, y: 503), size: 18, weight: .bold, color: secondary)
drawMono("重置 3小时 21分钟 45秒后", at: NSPoint(x: 496, y: 503), size: 20, weight: .regular, color: secondary)
drawBar(x: 410, y: 452, width: 470, height: 34, percent: 0.66, color: green)
drawMono("66%", at: NSPoint(x: 906, y: 456), size: 22, weight: .regular, color: .white)

drawMono("周", at: NSPoint(x: 410, y: 372), size: 28, weight: .bold, color: .white)
drawMono("┃", at: NSPoint(x: 468, y: 375), size: 18, weight: .bold, color: secondary)
drawMono("重置 6天 8小时后", at: NSPoint(x: 496, y: 375), size: 20, weight: .regular, color: secondary)
drawBar(x: 410, y: 324, width: 470, height: 34, percent: 0.18, color: red)
drawMono("18%", at: NSPoint(x: 906, y: 328), size: 22, weight: .regular, color: .white)

drawMono("可用重置 1 次", at: NSPoint(x: 410, y: 282), size: 22, weight: .semibold, color: green)

drawText("Floating quota HUD for Codex", at: NSPoint(x: 410, y: 166), size: 30, weight: .semibold, color: .white)
drawText("Pinned, theme-aware, and refreshed locally.", at: NSPoint(x: 410, y: 122), size: 22, weight: .regular, color: NSColor(calibratedWhite: 1, alpha: 0.68))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render preview")
}

try FileManager.default.createDirectory(atPath: NSString(string: outputPath).deletingLastPathComponent,
                                        withIntermediateDirectories: true)
try png.write(to: URL(fileURLWithPath: outputPath))
