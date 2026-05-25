# CLAUDE.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project

**IPGlance** — macOS menu bar app that shows current public IP, country, ASN, and geo info. SwiftUI / Swift 6 / macOS 14+. The repo directory is still named `ip-info-app` for historical reasons; the product itself is **IPGlance**, bundle id `com.ipglance.app`. The legacy name "IPInfo" / "IPInfoApp" was retired because `IPinfo` is taken in the Mac App Store by ipinfo.io. Do not reintroduce it.

**Naming exception:** `Sources/IPGlanceCore/Providers/IPInfoProvider.swift` and `struct IPInfoProvider` are named after the third-party API at https://ipinfo.io/json (one of three geolocation providers). They are **not** legacy and must not be renamed.

## Common commands

All build/run/test flows go through the `Makefile`. The project is generated from `project.yml` by **XcodeGen** — never hand-edit `IPGlanceApp.xcodeproj/`.

```bash
make build       # Release xcodebuild via the generated .xcodeproj
make run         # build + relaunch (kills running IPGlanceApp first)
make stop        # killall IPGlanceApp
make test        # swift test (runs IPGlanceCoreTests via SwiftPM, no Xcode needed)
make clean       # rm -rf build && swift package clean
make xcode       # xcodegen generate && open IPGlanceApp.xcodeproj
make dmg         # build + assemble IPGlance-X.Y.Z.dmg (uses create-dmg)
```

Autostart at login is wired into the app itself via `SMAppService.mainApp` — the "Launch at Login" toggle in Settings calls `register()`/`unregister()` and syncs with the system state in `AppSettings.init()`. There is no LaunchAgent install path.

Single test target / single test:

```bash
swift test --filter CountryInfoTests                       # one test class
swift test --filter CountryInfoTests/testFlagEmojiRU       # one test method
```

`swift test` only sees `IPGlanceCore` + `IPGlanceCoreTests` (defined in `Package.swift`). The app target and widget extension are Xcode-only — they require `make build` / `xcodebuild`.

After changing `project.yml`, regenerate the Xcode project with `make xcode` (or `xcodegen generate`).

## Architecture

Three Swift modules, all under `Sources/`:

- **`IPGlanceCore`** — SwiftPM library. Pure logic, no UI, no AppKit. Public API:
  - `CountryInfo` — Codable result struct.
  - `IPGeolocationProvider` protocol + `IPGeolocationService` — multi-provider façade that tries providers in order and returns the first success (`ipapi.co` → `ipinfo.io` → `ipwhois.app`). Adding a provider = new file under `Providers/` + entry in the `providers` array in `IPGeolocationService.init`.
  - `SharedStore` — UserDefaults wrapper keyed to the App Group `group.com.ipglance.app`, used to hand off cached `CountryInfo` from app to widget.
  - `HTTPSession` protocol — `URLSession` conforms by default; tests pass mocks.
- **`IPGlanceApp`** — main `.app` target. SwiftUI `MenuBarExtra` (`.window` style) plus two `Window` scenes (`settings`, `about`) opened via `openWindow(id:)`. State lives in `IPViewModel` (`@Observable`); user preferences in `AppSettings`. `BundleModule.swift` exists only because non-SPM builds need a `Bundle.module` shim.
- **`IPGlanceWidget`** — WidgetKit app extension (`.appex`) embedded inside `IPGlanceApp.app`. Reads from `SharedStore` (re-exported via `@_exported import IPGlanceCore`). Three families: Small / Medium / Large, plus a `WidgetBundle` entry point.

**Data flow:** `IPViewModel` (app) calls `IPGeolocationService.fetchCountryInfo()` → writes the result through `SharedStore.write(_:)` → `WidgetCenter.shared.reloadAllTimelines()` → `WidgetProvider.getTimeline` reads via `SharedStore.read()`. The App Group `group.com.ipglance.app` is the only IPC channel between the two binaries; both entitlements files in `SupportingFiles/` must list it.

**Network sense:** `IPViewModel` keeps an `NWPathMonitor` on queue `com.ipglance.netmon` and triggers refreshes on connectivity changes.

## Project conventions

- **`project.yml` is the source of truth** for the Xcode project. Bundle IDs (`com.ipglance.app`, `com.ipglance.app.widget`), Info.plist paths, entitlements paths, scheme names — all live there. The `.xcodeproj/` is gitignored and regenerated.
- **`Package.swift` ships only `IPGlanceCore`** so `swift test` works on CI without Xcode. The app and widget Swift sources are *not* declared as SwiftPM targets; they're compiled by Xcode via `project.yml`.
- **Localization** uses an `.xcstrings` catalog at `Sources/IPGlanceApp/Resources/Localizable.xcstrings`. A pre-build script in `project.yml` (`Compile xcstrings`) compiles it into the bundle. Supported locales: `en`, `ru`, `pl`, `uk`.
- **Code signing:** builds are currently `adhoc` / linker-signed (`CODE_SIGNING_ALLOWED=NO` in the Makefile). Developer ID signing and notarization are not wired up — relevant if/when distributing the DMG outside dev machines.

## AI artifacts location

All AI-tooling output (Superpowers plans/specs, brainstorm scratch, agent state) goes under `.ai/`, which is gitignored. Use `.ai/superpowers/specs/` and `.ai/superpowers/plans/` instead of the Superpowers defaults of `docs/superpowers/*`. There is intentionally no `docs/` directory in this repo.

## Commit authorship

**Never add `Co-Authored-By` trailers for AI assistants or codegen tools to commits.** Do not mention AI assistants or codegen tools in commit messages, PR descriptions, or release notes. Commits are authored solely by the human committer.
