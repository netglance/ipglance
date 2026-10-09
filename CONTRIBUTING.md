# Contributing to IPGlance

Contributions are welcome. By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## Setup

Prerequisites: macOS 14+, Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
make xcode    # once: generates IPGlanceApp.xcodeproj and opens Xcode
make build    # Release build via xcodebuild
make test     # unit tests via SwiftPM (no Xcode needed)
```

The Xcode project is generated from `project.yml` and gitignored; never edit it by hand. After changing `project.yml`, run `make xcode` again.

## Before opening a PR

1. `make test` passes.
2. `make build` succeeds (Release configuration).
3. New user-visible strings are added to `Sources/IPGlanceApp/Resources/Localizable.xcstrings` (app) or `Sources/IPGlanceWidget/Localizable.xcstrings` (widget) with `en`, `ru`, `pl` and `uk` values.
4. User-visible changes get an entry under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md).
5. No new third-party network endpoints without updating the Privacy section of the README.

PRs target `main` and need green CI: `swift test`, the `xcodebuild` Release build, and the gitleaks secret scan.

## Security issues

Do not open a public issue. Follow [SECURITY.md](SECURITY.md) and report privately.

## Releases

Maintainers cut releases: `make release` tags the version, and GitHub Actions builds, signs and publishes it.

## Bugs and ideas

Use [Issues](https://github.com/netglance/ipglance/issues).
