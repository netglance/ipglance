SCHEME    := IPGlanceApp
BUILD_DIR := build
APP       := $(BUILD_DIR)/Build/Products/Release/IPGlanceApp.app
VERSION   := $(shell cat VERSION)
DMG_NAME  := IPGlance-$(VERSION).dmg
DMG_TMP   := /tmp/dmg-staging

XCODE_FLAGS := \
	-project IPGlanceApp.xcodeproj \
	-scheme "$(SCHEME)" \
	-configuration Release \
	-derivedDataPath $(BUILD_DIR) \
	CODE_SIGN_IDENTITY="" \
	CODE_SIGNING_REQUIRED=NO \
	CODE_SIGNING_ALLOWED=NO \
	MARKETING_VERSION=$(VERSION) \
	CURRENT_PROJECT_VERSION=$(VERSION)

.PHONY: build run stop clean test xcode dmg release-keys appcast release

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
	@echo "📦 Building $(DMG_NAME)…"
	@rm -f "$(DMG_NAME)"
	@rm -rf "$(DMG_TMP)" && mkdir -p "$(DMG_TMP)"
	@cp -r "$(APP)" "$(DMG_TMP)/IPGlance.app"
	@cp SupportingFiles/AppIcon.icns "$(DMG_TMP)/.VolumeIcon.icns" 2>/dev/null || true
	@create-dmg \
		--volname "IPGlance" \
		--volicon SupportingFiles/AppIcon.icns \
		--background SupportingFiles/dmg-background.png \
		--window-pos 200 150 \
		--window-size 660 400 \
		--icon-size 120 \
		--icon "IPGlance.app" 165 185 \
		--app-drop-link 495 185 \
		--hide-extension "IPGlance.app" \
		--no-internet-enable \
		"$(DMG_NAME)" \
		"$(DMG_TMP)"
	@rm -rf "$(DMG_TMP)"
	@echo "✅ $(DMG_NAME) ready"

# ─── Sparkle release pipeline ────────────────────────────────────────────

# Path to Sparkle's SPM-checkout binaries. Resolved lazily so it works after
# the first `make build` has populated build/SourcePackages.
SPARKLE_BIN = $(shell find $(BUILD_DIR)/SourcePackages -path '*Sparkle*/bin' -type d -print -quit)

RELEASES_DIR := releases

# One-time: generate the EdDSA keypair. The private key is stored in macOS
# Keychain (see Sparkle docs). The public key is printed to stdout — paste it
# into SupportingFiles/IPGlanceApp-Info.plist under SUPublicEDKey.
release-keys:
	@if [ -z "$(SPARKLE_BIN)" ]; then \
		echo "❌ Sparkle binaries not found. Run 'make build' first."; exit 1; \
	fi
	"$(SPARKLE_BIN)/generate_keys"

# Regenerate releases/appcast.xml from every .dmg in releases/. Sparkle
# signs each one with the EdDSA private key from Keychain. The .html note
# next to each dmg (e.g. releases/1.0.1.html) is embedded as release notes.
appcast:
	@if [ -z "$(SPARKLE_BIN)" ]; then \
		echo "❌ Sparkle binaries not found. Run 'make build' first."; exit 1; \
	fi
	@mkdir -p $(RELEASES_DIR)
	"$(SPARKLE_BIN)/generate_appcast" $(RELEASES_DIR)

# Cut a release: build DMG, copy it into releases/, regenerate appcast,
# publish to GitHub Releases. Assumes the current VERSION is the one being
# released and a matching releases/$(VERSION).html exists.
release: dmg
	@if [ ! -f "$(RELEASES_DIR)/$(VERSION).html" ]; then \
		echo "❌ Missing $(RELEASES_DIR)/$(VERSION).html — write release notes first."; exit 1; \
	fi
	@mkdir -p $(RELEASES_DIR)
	cp $(DMG_NAME) $(RELEASES_DIR)/IPGlance-$(VERSION).dmg
	@$(MAKE) --no-print-directory appcast
	gh release create v$(VERSION) \
		$(RELEASES_DIR)/IPGlance-$(VERSION).dmg \
		$(RELEASES_DIR)/appcast.xml \
		--target $(shell git rev-parse HEAD) \
		--title "v$(VERSION)" \
		--notes-file $(RELEASES_DIR)/$(VERSION).html
	@echo "✅ Released v$(VERSION)"
