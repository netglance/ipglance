#!/usr/bin/env swift
// Generates DMG assets: app icon (.icns) and background image (.png)

import AppKit
import Foundation

// MARK: - Icon

func renderEmoji(_ emoji: String, size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size * 0.85)
    ]
    let str = NSAttributedString(string: emoji, attributes: attrs)
    let strSize = str.size()
    let origin = NSPoint(x: (size - strSize.width) / 2, y: (size - strSize.height) / 2)
    str.draw(at: origin)

    image.unlockFocus()
    return image
}

func makePNG(from image: NSImage, size: CGFloat) -> Data? {
    let bmp = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size),
        pixelsHigh: Int(size),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bmp)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()
    return bmp.representation(using: .png, properties: [:])
}

func generateIconset(outputDir: String) {
    let iconsetPath = "\(outputDir)/AppIcon.iconset"
    try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

    let sizes: [(name: String, size: CGFloat, scale: Int)] = [
        ("icon_16x16", 16, 1),
        ("icon_16x16@2x", 16, 2),
        ("icon_32x32", 32, 1),
        ("icon_32x32@2x", 32, 2),
        ("icon_64x64", 64, 1),
        ("icon_64x64@2x", 64, 2),
        ("icon_128x128", 128, 1),
        ("icon_128x128@2x", 128, 2),
        ("icon_256x256", 256, 1),
        ("icon_256x256@2x", 256, 2),
        ("icon_512x512", 512, 1),
        ("icon_512x512@2x", 512, 2),
    ]

    for entry in sizes {
        let px = entry.size * CGFloat(entry.scale)
        let img = renderEmoji("🌐", size: px)
        if let data = makePNG(from: img, size: px) {
            let path = "\(iconsetPath)/\(entry.name).png"
            try? data.write(to: URL(fileURLWithPath: path))
            print("  ✓ \(entry.name).png (\(Int(px))px)")
        }
    }

    let result = shell("iconutil -c icns '\(iconsetPath)' -o '\(outputDir)/AppIcon.icns'")
    if result == 0 {
        print("  ✓ AppIcon.icns")
        try? FileManager.default.removeItem(atPath: iconsetPath)
    } else {
        print("  ✗ iconutil failed")
        exit(1)
    }
}

// MARK: - Background

func generateBackground(outputDir: String) {
    let w: CGFloat = 660
    let h: CGFloat = 400

    let bmp = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(w),
        pixelsHigh: Int(h),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bmp)

    let ctx = NSGraphicsContext.current!.cgContext

    // Light blue-white gradient background (icon labels will be readable)
    let colors = [
        NSColor(red: 0.88, green: 0.93, blue: 1.00, alpha: 1).cgColor,
        NSColor(red: 0.76, green: 0.86, blue: 0.98, alpha: 1).cgColor,
    ]
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(gradient,
        start: CGPoint(x: w / 2, y: h),
        end: CGPoint(x: w / 2, y: 0),
        options: [])

    NSGraphicsContext.restoreGraphicsState()

    // App name centered
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bmp)

    let titleAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: 22),
        .foregroundColor: NSColor(red: 0.12, green: 0.24, blue: 0.52, alpha: 1)
    ]
    let titleStr = NSAttributedString(string: "IP Info", attributes: titleAttrs)
    let titleSize = titleStr.size()
    titleStr.draw(at: NSPoint(x: (w - titleSize.width) / 2, y: h - 48))

    // Arrow hint
    let arrowAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 30),
        .foregroundColor: NSColor(red: 0.30, green: 0.50, blue: 0.85, alpha: 0.50)
    ]
    let arrowStr = NSAttributedString(string: "→", attributes: arrowAttrs)
    let arrowSize = arrowStr.size()
    arrowStr.draw(at: NSPoint(x: (w - arrowSize.width) / 2, y: h / 2 - arrowSize.height / 2))

    NSGraphicsContext.restoreGraphicsState()

    if let data = bmp.representation(using: .png, properties: [:]) {
        let path = "\(outputDir)/background.png"
        try? data.write(to: URL(fileURLWithPath: path))
        print("  ✓ background.png (\(Int(w))×\(Int(h)))")
    }
}

// MARK: - Helpers

@discardableResult
func shell(_ cmd: String) -> Int32 {
    let proc = Process()
    proc.launchPath = "/bin/bash"
    proc.arguments = ["-c", cmd]
    proc.launch()
    proc.waitUntilExit()
    return proc.terminationStatus
}

// MARK: - Main

guard CommandLine.arguments.count == 2 else {
    print("Usage: generate-dmg-assets.swift <output-dir>")
    exit(1)
}

let outputDir = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let icnsExists = FileManager.default.fileExists(atPath: "\(outputDir)/AppIcon.icns")
if !icnsExists {
    print("🎨 Generating icon…")
    generateIconset(outputDir: outputDir)
}

print("🖼️  Generating background…")
generateBackground(outputDir: outputDir)

print("✅ Assets written to \(outputDir)")
