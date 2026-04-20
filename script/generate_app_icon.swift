import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("usage: generate_app_icon.swift <source-png> <output-icns>\n", stderr)
    exit(2)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let iconsetURL = outputURL.deletingPathExtension().appendingPathExtension("iconset")
let fileManager = FileManager.default

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fputs("failed to load source image at \(sourceURL.path)\n", stderr)
    exit(1)
}

try? fileManager.removeItem(at: iconsetURL)
try fileManager.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let tealStroke = NSColor(calibratedRed: 0.184, green: 0.682, blue: 0.675, alpha: 0.22)
let iconSizes = [16, 32, 128, 256, 512]

func renderIcon(pixelSize: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
    image.lockFocus()

    let canvas = NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    NSColor.clear.setFill()
    canvas.fill()

    let tileInset = pixelSize * 0.04
    let tileRect = canvas.insetBy(dx: tileInset, dy: tileInset)
    let tilePath = NSBezierPath(
        roundedRect: tileRect,
        xRadius: pixelSize * 0.24,
        yRadius: pixelSize * 0.24
    )

    NSColor.white.setFill()
    tilePath.fill()
    tealStroke.setStroke()
    tilePath.lineWidth = max(1, pixelSize * 0.02)
    tilePath.stroke()

    let logoInset = pixelSize * 0.16
    let logoRect = tileRect.insetBy(dx: logoInset, dy: logoInset)
    sourceImage.draw(
        in: logoRect,
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL) throws {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "markiiup.icon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
    }

    try data.write(to: url)
}

for baseSize in iconSizes {
    for scale in [1, 2] {
        let fileName = scale == 1
            ? "icon_\(baseSize)x\(baseSize).png"
            : "icon_\(baseSize)x\(baseSize)@2x.png"
        let iconURL = iconsetURL.appendingPathComponent(fileName)
        let image = renderIcon(pixelSize: CGFloat(baseSize * scale))
        try writePNG(image, to: iconURL)
    }
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    fputs("iconutil failed with status \(iconutil.terminationStatus)\n", stderr)
    exit(iconutil.terminationStatus)
}

try? fileManager.removeItem(at: iconsetURL)
