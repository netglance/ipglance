SCHEME    := IPGlanceApp
BUILD_DIR := build
APP       := $(BUILD_DIR)/Build/Products/Release/IPGlanceApp.app
VERSION   := $(shell cat VERSION)
DMG_NAME  := IPGlance-$(VERSION).dmg
DMG_TMP   := /tmp/dmg-staging
DMG_ASSETS := /tmp/dmg-assets

XCODE_FLAGS := \
	-project IPGlanceApp.xcodeproj \
	-scheme "$(SCHEME)" \
	-configuration Release \
	-derivedDataPath $(BUILD_DIR) \
	CODE_SIGN_IDENTITY="" \
	CODE_SIGNING_REQUIRED=NO \
	CODE_SIGNING_ALLOWED=NO

.PHONY: build run stop clean test xcode dmg

build:
	xcodebuild $(XCODE_FLAGS) build | grep -E "^(error:|warning:|Build succeeded|FAILED|.*\.swift.*error)"

run: build
	@pkill -9 -x IPGlanceApp 2>/dev/null; sleep 0.5; true
	@/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
		-f "$(APP)" 2>/dev/null || true
	@open -n "$(APP)"
	@echo "✅ IPGlance launched"

stop:
	@killall IPGlanceApp 2>/dev/null && echo "✅ Stopped" || echo "Not running"

test:
	swift test

clean:
	rm -rf $(BUILD_DIR)
	swift package clean

xcode:
	xcodegen generate
	open IPGlanceApp.xcodeproj

dmg: build
	@echo "🎨 Generating DMG assets…"
	@bash scripts/icon-from-svg.sh "$(DMG_ASSETS)"
	@swift scripts/generate-dmg-assets.swift "$(DMG_ASSETS)"
	@echo "🖼️  Injecting app icon…"
	@cp "$(DMG_ASSETS)/AppIcon.icns" "$(APP)/Contents/Resources/AppIcon.icns"
	@swift scripts/set-app-icon.swift "$(DMG_ASSETS)/AppIcon.icns" "$(APP)"
	@echo "📦 Building $(DMG_NAME)…"
	@rm -f "$(DMG_NAME)"
	@rm -rf "$(DMG_TMP)" && mkdir -p "$(DMG_TMP)"
	@cp -r "$(APP)" "$(DMG_TMP)/IPGlance.app"
	@cp "$(DMG_ASSETS)/AppIcon.icns" "$(DMG_TMP)/.VolumeIcon.icns" 2>/dev/null || true
	@create-dmg \
		--volname "IPGlance" \
		--volicon "$(DMG_ASSETS)/AppIcon.icns" \
		--background "$(DMG_ASSETS)/background.png" \
		--window-pos 200 150 \
		--window-size 660 400 \
		--icon-size 120 \
		--icon "IPGlance.app" 165 185 \
		--app-drop-link 495 185 \
		--hide-extension "IPGlance.app" \
		--no-internet-enable \
		"$(DMG_NAME)" \
		"$(DMG_TMP)"
	@rm -rf "$(DMG_TMP)" "$(DMG_ASSETS)"
	@echo "✅ $(DMG_NAME) ready"
