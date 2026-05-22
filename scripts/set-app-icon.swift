#!/usr/bin/env swift
import AppKit

guard CommandLine.arguments.count == 3 else {
    print("Usage: set-app-icon.swift <icon.icns> <app-path>")
    exit(1)
}

let iconPath = CommandLine.arguments[1]
let appPath  = CommandLine.arguments[2]

guard let icon = NSImage(contentsOfFile: iconPath) else {
    print("Failed to load icon: \(iconPath)")
    exit(1)
}

let ok = NSWorkspace.shared.setIcon(icon, forFile: appPath, options: [])
print(ok ? "✅ Icon set on \(appPath)" : "❌ setIcon failed")
exit(ok ? 0 : 1)
