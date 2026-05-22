# Pre-release manual smoke test

Run before every `make release`. Updater verification cannot be fully
automated because Sparkle's installer logic needs a real bundle.

## Setup

1. Have a clean machine or VM available (any non-dev Mac running macOS 14+).
2. Make sure the previous release's DMG (e.g. v0.9.9) is downloadable from
   GitHub Releases so you can install it as the "old" version.

## End-to-end: upgrade from previous release

1. On the test machine, download and install the *previous* version's
   `IPGlance-X.Y.Z.dmg`.
2. Launch IPGlance. Confirm the menu bar icon appears.
3. Open About. Confirm the version line shows the *previous* version.
4. Click **Check for Updates**.
5. Sparkle's update sheet appears, listing the new version and release
   notes from `releases/<new-version>.html`.
6. Click **Install Update**. Sparkle downloads the DMG (progress sheet),
   verifies the EdDSA signature, mounts the DMG, replaces the .app, and
   restarts IPGlance.
7. After restart, open About again. Version line now shows the *new*
   version.

## Negative path 1 — no network

1. Disable Wi-Fi on the test machine.
2. Open About → click **Check for Updates**.
3. Within ~10s, the status line should change to "Couldn't check — try
   again later". The button stays enabled.

## Negative path 2 — bad signature

1. After producing `IPGlance-X.Y.Z.dmg`, corrupt one byte:
   `printf '\x00' | dd of=releases/IPGlance-X.Y.Z.dmg bs=1 seek=512 count=1 conv=notrunc`
2. Re-run `make appcast` to refresh signatures. *Now manually* edit
   `releases/appcast.xml` to point the `<enclosure>` at the corrupted file
   without re-signing — this simulates a tampered download.
3. Publish the malformed release to a *staging* tag (do not use the real
   release tag).
4. Repeat the end-to-end flow. Sparkle must refuse to install; the About
   status line must show "Update signature invalid".
5. Undo the corruption, restore the real release tag.
