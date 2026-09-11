#!/usr/bin/env bash
# Render tools/preview.html to preview.png at 1800x1012 with headless Chromium.
#
#   ./tools/generate-preview.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

BROWSER=$(command -v chromium || command -v google-chrome-stable || command -v google-chrome)
PROFILE=$(mktemp -d)
trap 'rm -rf "$PROFILE"' EXIT

"$BROWSER" \
  --headless \
  --hide-scrollbars \
  --force-device-scale-factor=1 \
  --allow-file-access-from-files \
  --user-data-dir="$PROFILE" \
  --window-size=1800,1012 \
  --virtual-time-budget=3000 \
  --screenshot="$PWD/preview.png" \
  "file://$PWD/tools/preview.html" >/dev/null 2>&1

# Chromium writes a full-colour PNG; quantising keeps the thumbnail small
# without visible banding at switcher size.
magick preview.png -strip -define png:compression-level=9 preview.png
identify preview.png
