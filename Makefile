SCHEME    := IPGlanceApp
BUILD_DIR := build
APP       := $(BUILD_DIR)/Build/Products/Release/IPGlanceApp.app
VERSION   := $(shell cat VERSION)
REPO_URL  := https://github.com/netglance/ipglance
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

.PHONY: build run stop clean test xcode dmg release-keys notes appcast release

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

# Path to Sparkle's binaries (SPM binary artifact). Resolved lazily so it works
# after the first `make build` has populated build/SourcePackages.
SPARKLE_BIN = $(shell dirname "$$(find $(BUILD_DIR)/SourcePackages -name generate_appcast -type f -print -quit 2>/dev/null)" 2>/dev/null | grep -vx '\.')

# ponytail: the appcast is regenerated from what is in this dir; `make clean`
# drops older items, which is fine because Sparkle only needs the newest one.
# Upgrade: keep the dir outside build/ or download the previous appcast.xml first.
RELEASES_DIR := $(BUILD_DIR)/release
NOTES := $(RELEASES_DIR)/IPGlance-$(VERSION).md

# One-time: generate the EdDSA keypair. The private key is stored in macOS
# Keychain (see Sparkle docs). The public key is printed to stdout — paste it
# into SupportingFiles/IPGlanceApp-Info.plist under SUPublicEDKey.
release-keys:
	@if [ -z "$(SPARKLE_BIN)" ]; then \
		echo "❌ Sparkle binaries not found. Run 'make build' first."; exit 1; \
	fi
	"$(SPARKLE_BIN)/generate_keys"

# Extract the body of the `## [VERSION]` section of CHANGELOG.md into
# $(NOTES), named like the DMG so generate_appcast picks it up.
notes:
	@mkdir -p $(RELEASES_DIR)
	@awk -v h='## [$(VERSION)]' 'index($$0,h)==1{f=1;next} /^## \[/||/^\[[^]]*\]: /{f=0} f' CHANGELOG.md \
		| awk 'NF{p=1} p{b[++n]=$$0} NF{l=n} END{for(i=1;i<=l;i++)print b[i]}' > $(NOTES)
	@if [ ! -s "$(NOTES)" ]; then \
		echo "❌ CHANGELOG.md has no (or an empty) '## [$(VERSION)]' section — write release notes first."; \
		rm -f "$(NOTES)"; exit 1; \
	fi

# Regenerate $(RELEASES_DIR)/appcast.xml from every .dmg in it, signed with the
# EdDSA private key from the Keychain. Local manual fallback only: CI signs in
# the isolated `publish` job of release.yml with pinned Sparkle tools.
# The IPGlance-X.Y.Z.md next to each dmg is embedded as release notes, and
# enclosure URLs point at this version's GitHub Release assets.
appcast:
	@if [ -z "$(SPARKLE_BIN)" ]; then \
		echo "❌ Sparkle binaries not found. Run 'make build' first."; exit 1; \
	fi
	@mkdir -p $(RELEASES_DIR)
	"$(SPARKLE_BIN)/generate_appcast" --embed-release-notes \
		--download-url-prefix $(REPO_URL)/releases/download/v$(VERSION)/ \
		$(RELEASES_DIR)

# Maintainer: after bumping VERSION and writing the CHANGELOG.md section, tag
# and push. The tag (must be on main) triggers the Release workflow, which builds
# the DMG, then signs and publishes the GitHub Release in a separate job.
release: notes
	@git diff --quiet && git diff --cached --quiet || { echo "❌ Working tree is not clean."; exit 1; }
	@[ "$$(git rev-parse --abbrev-ref HEAD)" = main ] || { echo "❌ Not on main."; exit 1; }
	@! git rev-parse -q --verify refs/tags/v$(VERSION) >/dev/null || { echo "❌ Tag v$(VERSION) exists locally."; exit 1; }
	@[ -z "$$(git ls-remote --tags origin refs/tags/v$(VERSION))" ] || { echo "❌ Tag v$(VERSION) exists on origin."; exit 1; }
	git tag -a v$(VERSION) -m "v$(VERSION)"
	git push origin v$(VERSION)
	@echo "✅ Pushed v$(VERSION). Watch: $(REPO_URL)/actions/workflows/release.yml"
