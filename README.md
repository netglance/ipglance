# IPGlance

A macOS menu bar utility that shows your current public IP, country, ASN, and geolocation at a glance — with a matching widget.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift 6](https://img.shields.io/badge/Swift-6-orange) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

<!-- TODO: add screenshot here -->

## Features

- Lives in the menu bar; one-glance read of your public IP and country flag
- Click for a popover with detailed geo info (city, region, ASN, ISP, timezone)
- WidgetKit widget in three sizes (Small / Medium / Large)
- Auto-refreshes on network changes (sleep, Wi-Fi switch, VPN connect)
- Multi-provider fallback: tries three geolocation services in order so a single outage doesn't blank the menu bar
- Optional country kill switch: blocks outgoing traffic via pf when your IP leaves the countries you allow (asks for the admin password once)
- Native tabbed Settings (General, Kill switch, About) that apply instantly
- Localized: English, Russian, Polish, Ukrainian
- Light and dark theme support
- No telemetry, no analytics, no account

## Installation

### Download

Prebuilt `.dmg` files are published on the [Releases page](https://github.com/netglance/ipglance/releases).

Builds are not yet code-signed with a Developer ID, so on first launch you may need to right-click the app and choose **Open** to bypass Gatekeeper, or allow it in **System Settings → Privacy & Security**.

### From source

Requirements: macOS 14+, Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
git clone https://github.com/netglance/ipglance.git
cd ipglance
make xcode    # generates IPGlanceApp.xcodeproj
make run      # builds and launches
```

## Usage

```bash
make build    # release build via xcodebuild
make run      # build + relaunch
make stop     # quit the running app
make test     # run unit tests via SwiftPM (no Xcode needed)
make dmg      # produce IPGlance-X.Y.Z.dmg
```

To run a single test:

```bash
swift test --filter CountryInfoTests/testFlagEmojiRU
```

## Kill switch

When enabled, IPGlance blocks outgoing traffic with a `pf` rule set (anchor `com.apple/ipglance`) as soon as your public IP's country is not in the list you allow, and lifts the block when it is again. "Unblock and pause" in the menu lifts it manually and pauses the kill switch until you're back in an allowed country, so a dropped VPN can reconnect. Local networks, DNS and the geolocation APIs stay reachable.

It is reactive: the country is checked every 8–20 s, so some traffic may leak before the block applies. After a reboot it is inactive until IPGlance starts.

Enabling it asks for the admin password once and installs two files: `/etc/pf.anchors/ipglance` and `/etc/sudoers.d/ipglance`, which grants only fixed `pfctl` commands for the anchor `com.apple/ipglance`.

If you get stuck blocked: reboot, or run `sudo pfctl -a com.apple/ipglance -F all`.

To remove: Settings → "Remove system rules…". Deleting the app alone leaves those two files behind.

## Privacy

IPGlance needs to know your public IP, and to do that it has to ask a server about you. There is **no first-party server** — IPGlance does not send anything to any infrastructure operated by the author. Instead it queries three independent public geolocation APIs in order, stopping at the first success:

1. [`ipapi.co/json/`](https://ipapi.co) — primary
2. [`ipinfo.io/json`](https://ipinfo.io) — secondary
3. [`ipwhois.app/json/`](https://ipwhois.app) — fallback

Each of these services will see your IP address (they have to — that's how the lookup works) and is governed by its own privacy policy.

The app makes no other network requests, stores no logs, and has no analytics, telemetry, or crash reporting. Cached results live only in your local user defaults (App Group `group.com.ipglance.app`).

## Architecture

Three Swift modules:

- **`IPGlanceCore`** — pure logic (SwiftPM library). Provider protocol, fallback service, App Group cache, country/flag formatting.
- **`IPGlanceApp`** — the `.app` target. SwiftUI `MenuBarExtra` and Settings / About windows.
- **`IPGlanceWidget`** — WidgetKit extension embedded in the app. Reads cached data from the App Group.

The Xcode project is generated from `project.yml` by XcodeGen and is gitignored. See [`CLAUDE.md`](CLAUDE.md) for the detailed contributor-facing architecture notes.

## Acknowledgments

This app would not exist without the free public APIs from **[ipapi.co](https://ipapi.co)**, **[ipinfo.io](https://ipinfo.io)**, and **[ipwhois.app](https://ipwhois.app)**. If you build something on top of one of these, consider thanking (or paying) them.

## Contributing

Contributions are welcome. Before opening a PR:

1. `make test` passes.
2. `make build` succeeds (Release configuration).
3. New user-visible strings are added to `Sources/IPGlanceApp/Resources/Localizable.xcstrings` with at least an English value.

Bug reports and feature requests go in [Issues](https://github.com/netglance/ipglance/issues).

If IPGlance is useful to you, you can [buy me a coffee](https://buymeacoffee.com/vpotar).

## License

[MIT](LICENSE) © 2026 Vlad P
