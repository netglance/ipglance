# Changelog

All notable changes to IPGlance are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Kill switch errors are now localized
- macOS account names with capital letters or digits are accepted by the kill switch
- Kill switch rules are reinstalled when an update changes them
- Cancelling "Remove system rules…" no longer turns the kill switch off
- The widget's "updated" time reflects when the IP was fetched

### Changed
- Widget legibility tweaks: larger, higher-contrast secondary text

## [1.1.1] - 2026-10-09

### Fixed
- The interface showed untranslated keys in 1.1.0 builds; string catalogs are now compiled into the app
- The widget was not loaded by macOS; it is now sandboxed and signed with its entitlements
- The widget showed Russian text in every language; it is now localized in English, Russian, Polish and Ukrainian
- `make build` no longer reports success when compilation fails

## [1.1.0] - 2026-10-08

### Added
- Country kill switch: blocks outgoing traffic via pf when the public IP's country is not in the allowed list; auto-unblocks when it is
- The kill switch asks for the administrator password once; its system rules can be removed any time in Settings → "Remove system rules…"
- Status line in the menu showing the kill switch state
- Unblocking from the menu pauses the kill switch until you're back in an allowed country, so a dropped VPN can reconnect
- Buy Me a Coffee link in the menu and in Settings → About

### Changed
- Settings moved to a native tabbed window (General, Kill switch, About); changes apply immediately
- Menu reorganised: provider, ASN and timezone on one line, Copy IP / Refresh as buttons with working ⌘C / ⌘R, collapsible recent IPs
- The About window is now a Settings tab
- The IP no longer flickers to "…" during background refreshes

### Fixed
- The menu now shows the real app version

## 1.0.0 - 2026-05-17

Initial public release.

### Added
- Menu bar app showing current public IP and country flag at a glance
- Popover with detailed geolocation (city, region, ASN, ISP, timezone, lat/lon)
- WidgetKit widget in Small, Medium, and Large sizes
- Multi-provider geolocation service (ipapi.co → ipinfo.io → ipwhois.app fallback)
- Network change detection — auto-refresh on Wi-Fi switch, sleep/wake, VPN connect
- Settings window: refresh interval, theme override, "launch at login"
- Localization for English, Russian, Polish, Ukrainian
- Light and dark theme support

[Unreleased]: https://github.com/netglance/ipglance/compare/v1.1.1...HEAD
[1.1.1]: https://github.com/netglance/ipglance/releases/tag/v1.1.1
[1.1.0]: https://github.com/netglance/ipglance/releases/tag/v1.1.0
