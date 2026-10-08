# Changelog

All notable changes to IPGlance are documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] — 2026-10-08

### Added
- Country kill switch: blocks outgoing traffic via pf when the public IP's country is not in the allowed list; auto-unblocks when it is

## [1.0.0] — 2026-05-17

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
- LaunchAgent install script (`make install`)

[Unreleased]: https://github.com/haric655/ipglance/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/haric655/ipglance/releases/tag/v1.0.0
