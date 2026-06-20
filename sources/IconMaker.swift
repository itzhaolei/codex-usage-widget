import Cocoa

let outputPath = CommandLine.arguments.dropFirst().first ?? "assets/icon.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let shell = NSBezierPath(roundedRect: rect.insetBy(dx: 46, dy: 46), xRadius: 232, yRadius: 232)
NSColor(calibratedRed: 0.035, green: 0.075, blue: 0.105, alpha: 1).setFill()
shell.fill()

let bubble = NSBezierPath(roundedRect: rect.insetBy(dx: 108, dy: 122), xRadius: 190, yRadius: 190)
NSColor(calibratedRed: 0.075, green: 0.155, blue: 0.205, alpha: 1).setFill()
bubble.fill()

let glow = NSGradient(colors: [
    NSColor(calibratedRed: 0.18, green: 0.92, blue: 0.32, alpha: 0.38),
    NSColor(calibratedRed: 0.18, green: 0.92, blue: 0.32, alpha: 0.0)
])
glow?.draw(in: NSBezierPath(ovalIn: NSRect(x: 150, y: 110, width: 724, height: 724)), angle: 90)

let green = NSColor(calibratedRed: 0.05, green: 1.0, blue: 0.14, alpha: 1)
let track = NSColor(calibratedRed: 0.05, green: 1.0, blue: 0.14, alpha: 0.18)

func drawBar(y: CGFloat, fillWidth: CGFloat) {
    let x: CGFloat = 220
    let fullWidth: CGFloat = 584
    let height: CGFloat = 76
    let trackPath = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: fullWidth, height: height), xRadius: 28, yRadius: 28)
    track.setFill()
    trackPath.fill()

    let fillPath = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: fillWidth, height: height), xRadius: 28, yRadius: 28)
    green.setFill()
    fillPath.fill()
}

drawBar(y: 332, fillWidth: 420)
drawBar(y: 454, fillWidth: 292)

let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 172, weight: .black),
    .foregroundColor: NSColor.white
]
let mark = "QB"
let markSize = mark.size(withAttributes: attrs)
mark.draw(at: NSPoint(x: (1024 - markSize.width) / 2, y: 626), withAttributes: attrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render icon")
}

try FileManager.default.createDirectory(atPath: NSString(string: outputPath).deletingLastPathComponent,
                                        withIntermediateDirectories: true)
try png.write(to: URL(fileURLWithPath: outputPath))
