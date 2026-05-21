#!/bin/bash
# Batch render social-asset HTML → PNG via Chrome headless.
# Usage: ./export-to-png.sh
# Output: ./png/<filename>.png

set -e
cd "$(dirname "$0")"
mkdir -p png

CHROME=""
for candidate in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "/Applications/Google Chrome 2.app/Contents/MacOS/Google Chrome" \
  "/Applications/Chromium.app/Contents/MacOS/Chromium" \
  "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" \
  "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge"; do
  if [ -x "$candidate" ]; then
    CHROME="$candidate"
    break
  fi
done
if [ -z "$CHROME" ]; then
  echo "Chrome/Chromium not found. Install Chrome or edit CHROME path."
  exit 1
fi
echo "Using browser: $CHROME"

render() {
  local file="$1"
  local width="$2"
  local height="$3"
  local out="png/${file%.html}.png"
  echo "→ $file ($width x $height)"
  "$CHROME" \
    --headless=new \
    --disable-gpu \
    --hide-scrollbars \
    --no-sandbox \
    --default-background-color=00000000 \
    --window-size="$width,$height" \
    --screenshot="$PWD/$out" \
    "file://$PWD/$file" >/dev/null 2>&1
}

# 1200x630 (OG / horizontal)
for f in og-image-1200x630.html og-launch-v1-1200x630.html og-launch-v101-1200x630.html; do
  [ -f "$f" ] && render "$f" 1200 630
done

# 1200x675 (16:9 horizontal — stats / comparison)
for f in stats-card-1200x675.html stats-launch-day-1200x675.html stats-launch-retro-1200x675.html comparison-tldr-vs-feynman-1200x675.html comparison-v1-vs-v101-1200x675.html; do
  [ -f "$f" ] && render "$f" 1200 675
done

# 1080x1080 (square — quote / feature)
for f in quote-card-1080x1080.html quote-graveyard-1080x1080.html quote-no-api-key-1080x1080.html quote-invisible-ux-1080x1080.html feature-flow-1080x1080.html; do
  [ -f "$f" ] && render "$f" 1080 1080
done

echo ""
echo "✓ Done. PNGs in ./png/"
ls -la png/
