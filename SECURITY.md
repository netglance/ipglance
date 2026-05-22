# Security Policy

## Supported versions

Only the latest released version of IPGlance receives security fixes.

## Reporting a vulnerability

If you believe you've found a security issue in IPGlance — for example, a way for the app to leak data beyond what the [Privacy](README.md#privacy) section describes, an issue in the LaunchAgent install script, or a problem with how the App Group cache handles untrusted input — please report it privately.

**Do not open a public GitHub issue for security reports.**

Instead, please use GitHub's [private vulnerability reporting](https://github.com/vladp/ipglance/security/advisories/new) for this repository. If that's unavailable, email the maintainer directly (the address listed on the maintainer's GitHub profile).

When reporting, please include:

- A description of the issue and its impact
- Steps to reproduce, if possible
- The version of IPGlance and macOS you're running
- Any proof-of-concept code

You can expect an initial response within a week. If the issue is confirmed, a fix will be prioritized for the next release, and we'll credit you in the release notes unless you prefer otherwise.

## Out of scope

- Behavior of the third-party geolocation APIs IPGlance queries (`ipapi.co`, `ipinfo.io`, `ipwhois.app`) — please report those to the upstream providers.
- The fact that the public DMG is currently signed with an ad-hoc identity rather than a Developer ID. This is a known limitation, not a vulnerability.
