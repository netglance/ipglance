#!/usr/bin/env python3
"""Sets a custom icon on a macOS app bundle via NSWorkspace (resource fork)."""
import sys
import os

if len(sys.argv) != 3:
    print("Usage: set-app-icon.py <icon.icns> <app-path>")
    sys.exit(1)

icon_path = os.path.abspath(sys.argv[1])
app_path  = os.path.abspath(sys.argv[2])

from AppKit import NSWorkspace, NSImage

icon = NSImage.alloc().initWithContentsOfFile_(icon_path)
if not icon:
    print(f"Failed to load icon: {icon_path}")
    sys.exit(1)

ok = NSWorkspace.sharedWorkspace().setIcon_forFile_options_(icon, app_path, 0)
print("✅ Icon set" if ok else "❌ setIcon failed")
sys.exit(0 if ok else 1)
