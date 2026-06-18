import Cocoa

let outputPath = CommandLine.arguments.dropFirst().first ?? "assets/icon.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let background = NSBezierPath(roundedRect: rect.insetBy(dx: 42, dy: 42), xRadius: 220, yRadius: 220)
NSColor(calibratedWhite: 0.05, alpha: 1).setFill()
background.fill()

let glass = NSBezierPath(roundedRect: rect.insetBy(dx: 92, dy: 92), xRadius: 170, yRadius: 170)
NSColor(calibratedWhite: 1, alpha: 0.08).setFill()
glass.fill()

let green = NSColor(calibratedRed: 0.12, green: 0.86, blue: 0.35, alpha: 1)
let dimGreen = NSColor(calibratedRed: 0.12, green: 0.86, blue: 0.35, alpha: 0.28)

func drawBar(y: CGFloat, fillWidth: CGFloat) {
    let x: CGFloat = 208
    let fullWidth: CGFloat = 608
    let height: CGFloat = 92
    let track = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: fullWidth, height: height), xRadius: 46, yRadius: 46)
    dimGreen.setFill()
    track.fill()

    let fill = NSBezierPath(roundedRect: NSRect(x: x, y: y, width: fillWidth, height: height), xRadius: 46, yRadius: 46)
    green.setFill()
    fill.fill()
}

drawBar(y: 352, fillWidth: 456)
drawBar(y: 504, fillWidth: 320)

let title = "Codex"
let attrs: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: 150, weight: .bold),
    .foregroundColor: NSColor.white
]
let titleSize = title.size(withAttributes: attrs)
title.draw(at: NSPoint(x: (1024 - titleSize.width) / 2, y: 648), withAttributes: attrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to render icon")
}

try FileManager.default.createDirectory(atPath: NSString(string: outputPath).deletingLastPathComponent,
                                        withIntermediateDirectories: true)
try png.write(to: URL(fileURLWithPath: outputPath))
