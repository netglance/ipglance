BINARY_PATH := $(shell swift build -c release --show-bin-path 2>/dev/null)/IPInfoApp
APP_BUNDLE  := /tmp/IPInfoApp.app

.PHONY: build run test clean install uninstall

build:
	swift build -c release --target IPInfoApp

test:
	swift test

run: build
	@killall IPInfoApp 2>/dev/null || true
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@cp "$(BINARY_PATH)" "$(APP_BUNDLE)/Contents/MacOS/IPInfoApp"
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n\
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n\
<plist version="1.0"><dict>\n\
  <key>CFBundleIdentifier</key><string>com.ipinfoapp</string>\n\
  <key>CFBundleName</key><string>IP Info</string>\n\
  <key>CFBundleExecutable</key><string>IPInfoApp</string>\n\
  <key>CFBundlePackageType</key><string>APPL</string>\n\
  <key>LSUIElement</key><true/>\n\
  <key>NSPrincipalClass</key><string>NSApplication</string>\n\
</dict></plist>\n' > "$(APP_BUNDLE)/Contents/Info.plist"
	@open -n "$(APP_BUNDLE)"
	@echo "✅ IP Info launched"

stop:
	@killall IPInfoApp 2>/dev/null && echo "✅ Stopped" || echo "Not running"

clean:
	swift package clean

install:
	bash scripts/install-launch-agent.sh
