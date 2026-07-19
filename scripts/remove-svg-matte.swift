#!/usr/bin/env swift

import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    FileHandle.standardError.write(Data("Usage: remove-svg-matte.swift <thumbnail-directory> <output-directory>\n".utf8))
    exit(2)
}

let inputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let files = try FileManager.default.contentsOfDirectory(
    at: inputDirectory,
    includingPropertiesForKeys: nil,
    options: [.skipsHiddenFiles]
).filter { $0.lastPathComponent.hasSuffix(".svg.png") }

try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for file in files {
    let sourceData = try Data(contentsOf: file)
    guard
        let source = NSBitmapImageRep(data: sourceData),
        let sourceImage = source.cgImage
    else {
        throw CocoaError(.fileReadCorruptFile)
    }

    let width = sourceImage.width
    let height = sourceImage.height
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

    guard let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    context.draw(sourceImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    for index in stride(from: 0, to: pixels.count, by: 4) {
        let lightestChannelFloor = min(pixels[index], pixels[index + 1], pixels[index + 2])
        guard lightestChannelFloor >= 250 else { continue }

        let retainedAlpha = UInt32(255 - lightestChannelFloor) * 51
        pixels[index + 3] = UInt8((UInt32(pixels[index + 3]) * retainedAlpha) / 255)
    }

    guard let outputImage = context.makeImage() else {
        throw CocoaError(.fileWriteUnknown)
    }

    let output = NSBitmapImageRep(cgImage: outputImage)
    guard let data = output.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown)
    }

    let outputName = file.deletingPathExtension().deletingPathExtension().lastPathComponent + ".png"
    try data.write(
        to: outputDirectory.appendingPathComponent(outputName),
        options: Data.WritingOptions.atomic
    )
}
