#!/usr/bin/env bash
# scripts/install-launch-agent.sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Building release binary..."
swift build -c release --target IPInfoApp

BINARY="$REPO_DIR/.build/release/IPInfoApp"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/com.ipinfoapp.plist"

mkdir -p "$PLIST_DIR"
sed "s|BINARY_PATH_PLACEHOLDER|$BINARY|" "$REPO_DIR/com.ipinfoapp.plist" > "$PLIST_PATH"

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"
echo "IPInfoApp установлен и запущен как LaunchAgent"
