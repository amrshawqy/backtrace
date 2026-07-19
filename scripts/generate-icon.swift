#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("Usage: generate-icon.swift <master-png> <iconset-directory>\n".utf8))
    exit(2)
}
let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)

guard let source = NSImage(contentsOf: sourceURL) else {
    FileHandle.standardError.write(Data("Could not read master app icon at \(sourceURL.path)\n".utf8))
    exit(2)
}

try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let variants: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

func drawIcon(pixels: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { throw CocoaError(.fileWriteUnknown) }

    NSGraphicsContext.saveGraphicsState()
    defer { NSGraphicsContext.restoreGraphicsState() }
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSGraphicsContext.current?.imageInterpolation = .high

    let scale = CGFloat(pixels)
    let canvas = NSRect(x: 0, y: 0, width: scale, height: scale)
    NSColor.clear.setFill()
    canvas.fill()

    let destination = canvas.insetBy(dx: scale * 0.045, dy: scale * 0.045)
    NSBezierPath(
        roundedRect: destination,
        xRadius: destination.width * 0.215,
        yRadius: destination.height * 0.215
    ).addClip()

    let crop = min(source.size.width, source.size.height) * 0.041
    let sourceRect = NSRect(
        x: crop,
        y: crop,
        width: source.size.width - (crop * 2),
        height: source.size.height - (crop * 2)
    )
    source.draw(
        in: destination,
        from: sourceRect,
        operation: .copy,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

for (name, pixels) in variants {
    try drawIcon(pixels: pixels).write(to: output.appendingPathComponent(name), options: .atomic)
}
