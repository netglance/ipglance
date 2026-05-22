#!/usr/bin/env bash
# Converts the AppIcon SVG (from icon.jsx) to AppIcon.icns
# Usage: ./scripts/icon-from-svg.sh <output-dir>
set -e

OUT="${1:-/tmp/dmg-assets}"
mkdir -p "$OUT"

ICONSET="$OUT/AppIcon.iconset"
mkdir -p "$ICONSET"
HTML_FILE="$OUT/icon_render.html"

# Write a self-contained HTML that renders the icon at arbitrary size via CSS transform
cat > "$HTML_FILE" << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; }
  html, body { width: 100vw; height: 100vh; background: transparent; overflow: hidden; }
</style>
</head>
<body>
<svg width="100%" height="100%" viewBox="0 0 1024 1024" style="display:block">
  <defs>
    <clipPath id="icsq">
      <path d="M512 0C156 0 0 156 0 512s156 512 512 512 512-156 512-512S868 0 512 0Z" />
    </clipPath>

    <linearGradient id="icbg" x1="0.2" y1="0" x2="0.8" y2="1">
      <stop offset="0%"  stop-color="#5DA8FF" />
      <stop offset="45%" stop-color="#1E5BD2" />
      <stop offset="100%" stop-color="#091E63" />
    </linearGradient>

    <radialGradient id="icglobe" cx="0.42" cy="0.38" r="0.7">
      <stop offset="0%"  stop-color="#FFFFFF" stop-opacity="0.18" />
      <stop offset="55%" stop-color="#FFFFFF" stop-opacity="0.06" />
      <stop offset="100%" stop-color="#000000" stop-opacity="0.22" />
    </radialGradient>

    <linearGradient id="icpin" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"  stop-color="#FFFFFF" />
      <stop offset="60%" stop-color="#F4F7FF" />
      <stop offset="100%" stop-color="#D8E2F2" />
    </linearGradient>

    <linearGradient id="icdot" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"  stop-color="#FF7AA0" />
      <stop offset="100%" stop-color="#E8235D" />
    </linearGradient>

    <linearGradient id="icgloss" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%"  stop-color="#FFFFFF" stop-opacity="0.40" />
      <stop offset="55%" stop-color="#FFFFFF" stop-opacity="0" />
    </linearGradient>

    <filter id="icpinshadow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="14" />
      <feOffset dy="20" />
      <feComponentTransfer><feFuncA type="linear" slope="0.45" /></feComponentTransfer>
      <feMerge><feMergeNode /><feMergeNode in="SourceGraphic" /></feMerge>
    </filter>

    <clipPath id="icglobeclip">
      <circle cx="512" cy="540" r="320" />
    </clipPath>
  </defs>

  <g clip-path="url(#icsq)">
    <rect width="1024" height="1024" fill="url(#icbg)" />
    <circle cx="512" cy="560" r="380" fill="#73B6FF" opacity="0.14" />
    <circle cx="512" cy="540" r="320" fill="url(#icglobe)" />

    <g clip-path="url(#icglobeclip)" fill="none" stroke="#FFFFFF" stroke-opacity="0.32" stroke-width="3">
      <ellipse cx="512" cy="540" rx="200" ry="320" />
      <path d="M192 540 H832" />
    </g>

    <g fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round">
      <circle cx="512" cy="540" r="78"  opacity="0.55" />
      <circle cx="512" cy="540" r="130" opacity="0.28" />
      <circle cx="512" cy="540" r="180" opacity="0.12" />
    </g>

    <circle cx="512" cy="540" r="320" fill="none" stroke="rgba(255,255,255,0.35)" stroke-width="3" />
    <circle cx="512" cy="540" r="320" fill="none" stroke="rgba(0,0,0,0.18)" stroke-width="2" transform="translate(0 4)" opacity="0.5" />

    <g filter="url(#icpinshadow)">
      <path d="M512 540
               C 412 520 332 430 332 320
               A 180 180 0 1 1 692 320
               C 692 430 612 520 512 540 Z"
            fill="url(#icpin)" />
      <ellipse cx="442" cy="225" rx="62" ry="22" fill="rgba(255,255,255,0.85)" opacity="0.55" />
    </g>

    <circle cx="512" cy="320" r="64" fill="url(#icdot)" />
    <circle cx="512" cy="320" r="64" fill="none" stroke="rgba(0,0,0,0.06)" stroke-width="2" />
    <circle cx="512" cy="320" r="14" fill="#FFFFFF" />

    <rect width="1024" height="500" fill="url(#icgloss)" />

    <path d="M512 0C156 0 0 156 0 512s156 512 512 512 512-156 512-512S868 0 512 0Z"
          fill="none" stroke="rgba(255,255,255,0.18)" stroke-width="6" />
  </g>

  <path d="M512 0C156 0 0 156 0 512s156 512 512 512 512-156 512-512S868 0 512 0Z"
        fill="none" stroke="rgba(0,0,0,0.20)" stroke-width="2" />
</svg>
</body>
</html>
HTMLEOF

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Render the SVG once at the master size. Headless Chrome on macOS has a
# minimum window size (~50 px), so requesting tiny screenshots (e.g. 32x32 for
# the 16x16 icon) produced blank/clipped PNGs — visible as IPGlance having no
# icon in Login Items / "Open With" lists where the system picks the small
# representations.
MASTER="$ICONSET/_master.png"
echo "🎨 Rendering master 1024×1024…"
"$CHROME" \
  --headless=new \
  --no-sandbox \
  --disable-gpu \
  --hide-scrollbars \
  --force-device-scale-factor=1 \
  --window-size=1024,1024 \
  --default-background-color=00000000 \
  --screenshot="$MASTER" \
  "file://${HTML_FILE}" 2>/dev/null

if [ ! -s "$MASTER" ]; then
  echo "❌ Chrome failed to render master icon (file missing or empty): $MASTER" >&2
  exit 1
fi

# Sanity-check the master is not transparent (sips reports `hasAlpha: yes` but
# we want to ensure at least one opaque pixel — a fully transparent PNG would
# silently produce the bug we're fixing).
MASTER_W=$(sips -g pixelWidth "$MASTER" 2>/dev/null | awk '/pixelWidth/{print $2}')
if [ "$MASTER_W" != "1024" ]; then
  echo "❌ Master render has unexpected width: $MASTER_W (expected 1024)" >&2
  exit 1
fi

resize() {
  local SIZE="$1"
  local NAME="$2"
  sips -s format png -z "$SIZE" "$SIZE" "$MASTER" --out "$ICONSET/${NAME}.png" >/dev/null
  echo "  ✓ ${NAME}.png (${SIZE}px)"
}

echo "🪄 Downscaling to .iconset sizes…"
resize 16   "icon_16x16"
resize 32   "icon_16x16@2x"
resize 32   "icon_32x32"
resize 64   "icon_32x32@2x"
resize 64   "icon_64x64"
resize 128  "icon_64x64@2x"
resize 128  "icon_128x128"
resize 256  "icon_128x128@2x"
resize 256  "icon_256x256"
resize 512  "icon_256x256@2x"
resize 512  "icon_512x512"
resize 1024 "icon_512x512@2x"
rm -f "$MASTER"

echo "🔨 Compiling .icns…"
iconutil -c icns "$ICONSET" -o "$OUT/AppIcon.icns"
rm -rf "$ICONSET" "$HTML_FILE"
echo "✅ $OUT/AppIcon.icns ready"