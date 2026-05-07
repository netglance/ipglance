#!/usr/bin/env bash
# scripts/install-launch-agent.sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Building release binary..."
swift build -c release --target IPInfoApp

BINARY="$REPO_DIR/.build/release/IPInfoApp"
test -x "$BINARY" || { echo "Error: binary not found at $BINARY"; exit 1; }

PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/com.ipinfoapp.plist"

mkdir -p "$PLIST_DIR"
python3 -c "
import sys
content = open(sys.argv[1]).read()
print(content.replace('BINARY_PATH_PLACEHOLDER', sys.argv[2]), end='')
" "$REPO_DIR/com.ipinfoapp.plist" "$BINARY" > "$PLIST_PATH"

launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"
echo "IPInfoApp установлен и запущен как LaunchAgent"
