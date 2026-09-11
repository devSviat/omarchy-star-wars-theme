#!/bin/bash
# Capture the two theme-switcher thumbnails from the running desktop:
#
#   ./tools/capture-previews.sh
#
#   preview.png        Star Wars        — Hyprland's own blur
#   preview-glass.png  Star Wars Glass  — the same scene with hyprglass (saber)
#
# Each theme is applied for real in turn, and the same two floating windows —
# fastfetch and this theme's hyprland.lua in Neovim — are opened over the Sith
# wallpaper so that one blade crosses each window's edge. That is where the
# two themes differ most: hyprglass bends and fringes the blade at the glass
# edge, Hyprland's blur just softens it. The figure stays clear between them.
#
# Needs: a monitor showing an empty workspace (8 by default, PREVIEW_WORKSPACE
# to change), and hyprglass loaded for the glass shot. The theme that was
# active before is put back at the end, and the windows are always closed,
# even if a step fails.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO=$PWD
WS=${PREVIEW_WORKSPACE:-8}
TAG=sw-preview
PIN_BG=00-sith-star-wars-lightsaber-dark-background-3840x2160-5554.jpg

TMP=$(mktemp -d)
ORIGINAL_THEME=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)

preview_pids() {
  local pid
  for pid in $(pgrep -x foot); do
    tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null | grep -q "$TAG" && echo "$pid"
  done
  return 0
}

close_windows() {
  local pids
  pids=$(preview_pids)
  [[ -z $pids ]] || kill $pids 2>/dev/null || true
  sleep 1
}

cleanup() {
  close_windows
  local now
  now=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
  if [[ -n $ORIGINAL_THEME && $now != "$ORIGINAL_THEME" ]]; then
    omarchy-theme-set "$ORIGINAL_THEME" >/dev/null 2>&1 || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

hyprctl plugin list 2>/dev/null | grep -q '^Plugin hyprglass' || {
  echo "hyprglass is not loaded, so Star Wars Glass would look plain (see README, Liquid glass)" >&2
  exit 1
}

read -r MONITOR MX MY MW MH SCALE < <(hyprctl monitors -j | python3 -c "
import json, sys
m = next((m for m in json.load(sys.stdin) if m['activeWorkspace']['name'] == '$WS'), None)
print(*(m['name'], m['x'], m['y'], m['width'], m['height'], m['scale']) if m else '')")
[[ -n ${MONITOR:-} ]] || {
  echo "switch a monitor to workspace $WS first" >&2
  exit 1
}
if ! hyprctl clients -j | python3 -c "import json,sys; sys.exit(any(c['workspace']['name']=='$WS' for c in json.load(sys.stdin)))"; then
  echo "workspace $WS is not empty" >&2
  exit 1
fi

# Window geometry in the monitor's logical space, as fractions of its size, so
# the blades land on the edges whatever the screen: both windows sit low (40%
# to 86% of the height), so the head and shoulders stay clear above them and
# each blade crosses the bottom edge of the window on its side. They are wide
# enough (43%) for fastfetch to lay out and print the theme's name in full.
read -r LW LH LX LY RW RH RX RY < <(python3 -c "
w = $MW / $SCALE; h = $MH / $SCALE
print(int(w*0.43), int(h*0.46), int(w*0.02), int(h*0.40),
      int(w*0.42), int(h*0.46), int(w*0.56), int(h*0.40))")

open_window() {
  local w=$1 h=$2 x=$3 y=$4
  shift 4
  # `move` in a window rule is relative to the monitor the window opens on.
  hyprctl dispatch "hl.dsp.exec_cmd(\"[workspace $WS silent; float; size $w $h; move $x $y] uwsm-app -- foot -T $TAG -e $*\")" >/dev/null
  sleep 0.8
}

shoot() {
  local theme=$1 out=$2
  omarchy-theme-set "$theme" >/dev/null
  # The rotation may have moved; the previews are always on the Sith wallpaper.
  omarchy-theme-bg-set "$HOME/.local/state/omarchy/current/theme/backgrounds/$PIN_BG" >/dev/null 2>&1 || true
  sleep 5
  open_window "$LW" "$LH" "$LX" "$LY" "sh -c 'fastfetch; sleep 120'"
  # -n -R: no swap file and read-only, so killing it leaves nothing behind.
  open_window "$RW" "$RH" "$RX" "$RY" "nvim -n -R $REPO/hyprland.lua"
  sleep 4
  hyprctl clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if c['title'] == '$TAG' or c['workspace']['name'] == '$WS':
        print('   window', c['class'], 'at', c['at'], 'size', c['size'], 'floating', c['floating'])"
  grim -o "$MONITOR" "$TMP/$theme.png"
  close_windows
  # 1800x1012, the size the theme switcher thumbnails are drawn from.
  magick "$TMP/$theme.png" -resize 1800x -gravity center -extent 1800x1012 \
    -strip -define png:compression-level=9 "$out"
  echo "$theme -> $out"
}

shoot star-wars preview.png
shoot star-wars-glass preview-glass.png

identify preview.png preview-glass.png
