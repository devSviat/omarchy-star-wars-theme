#!/bin/bash
# Capture the three theme-switcher thumbnails from the running desktop:
#
#   ./tools/capture-previews.sh
#
#   preview.png        Star Wars as `omarchy theme install` leaves it
#   preview-full.png   Star Wars from install-themes.sh — Hyprland's own blur
#   preview-glass.png  Star Wars Glass  — the same scene with hyprglass (saber)
#
# Each theme is applied for real in turn, and the same two floating windows —
# Files on the theme's wallpapers and a theme file in Neovim — are opened over
# the Sith wallpaper so that one blade crosses each window's edge. That is where the looks differ
# most: hyprglass bends and fringes the blade at the glass edge, Hyprland's
# blur just softens it, and the cloned theme has opaque windows. The figure
# stays clear between them.
#
# Needs: both themes installed by install-themes.sh, a monitor showing an
# empty workspace (8 by default, PREVIEW_WORKSPACE to change), Files not
# running (it is single-instance, and a window opened into a running one
# ignores the placement rule), and hyprglass loaded for the glass shot. The theme that was active before is put back at
# the end, the install is rebuilt, and the windows are always closed, even if
# a step fails.
set -euo pipefail

cd "$(dirname "$0")/.."
REPO=$PWD
THEMES=$HOME/.config/omarchy/themes
MARKER=.star-wars-links
# The theme path is spliced into a Hyprland exec string; allow only plain path
# characters so a space or a quote in it cannot break or extend that command.
[[ $THEMES =~ ^[A-Za-z0-9._/+-]+$ ]] || {
  echo "the themes directory has a space or a quote in its path: $THEMES" >&2
  exit 1
}
[[ -f $THEMES/star-wars/$MARKER && -f $THEMES/star-wars-glass/$MARKER ]] || {
  echo "run ./tools/install-themes.sh first" >&2
  exit 1
}
WS=${PREVIEW_WORKSPACE:-8}
TAG=sw-preview
PIN_BG=00-sith-star-wars-lightsaber-dark-background-3840x2160-5554.jpg

pgrep -x nautilus >/dev/null && {
  echo "close Files first" >&2
  exit 1
}

TMP=$(mktemp -d)
ORIGINAL_ZOOM=$(gsettings get org.gnome.nautilus.icon-view default-zoom-level)
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
  nautilus -q 2>/dev/null || true
  sleep 1
}

cleanup() {
  close_windows
  gsettings set org.gnome.nautilus.icon-view default-zoom-level "$ORIGINAL_ZOOM" || true
  local now
  now=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null || true)
  if [[ -n $ORIGINAL_THEME && $now != "$ORIGINAL_THEME" ]]; then
    omarchy-theme-set "$ORIGINAL_THEME" >/dev/null 2>&1 || true
  fi
  [[ ! -d $THEMES/star-wars/.git ]] || "$REPO/tools/install-themes.sh" >/dev/null || true
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
# each blade crosses the bottom edge of the window on its side.
# The scene was composed on a 2048-wide logical screen at foot's 9 pt. The
# font scales with the screen, so the editor shows the same text on a smaller
# one.
read -r LW LH LX LY RW RH RX RY FONT_SIZE PX PY < <(python3 -c "
w = $MW / $SCALE; h = $MH / $SCALE
print(int(w*0.43), int(h*0.46), int(w*0.02), int(h*0.40),
      int(w*0.42), int(h*0.46), int(w*0.56), int(h*0.40),
      round(9 * w / 2048, 1), int($MX + w) - 1, int($MY + h) - 1)")

# The pointer shows up in the shot when it rests on this workspace. Parked on
# the last pixel of the monitor, the arrow is drawn off-screen.
park_pointer() {
  hyprctl dispatch "hl.dsp.cursor.move({ x = $PX, y = $PY })" >/dev/null 2>&1 || true
}

# `move` in a window rule is relative to the monitor the window opens on.
open_window() {
  local w=$1 h=$2 x=$3 y=$4
  shift 4
  hyprctl dispatch "hl.dsp.exec_cmd(\"[workspace $WS silent; float; size $w $h; move $x $y] $*\")" >/dev/null
  sleep 0.8
}

# Turn the installed star-wars into what `omarchy theme install` would leave
# there: a copy of the checkout holding a `.git`, which is the whole of the
# test omarchy-theme-set applies before it filters a theme. The marker lets
# install-themes.sh replace the copy afterwards.
stage_cloned_install() {
  local dir=$THEMES/star-wars
  rm -rf "$dir"
  mkdir -p "$dir/.git"
  touch "$dir/$MARKER"
  cp -r "$REPO"/* "$dir/"
}

shoot() {
  local theme=$1 out=$2 file=$3
  # stderr carries the list of files Omarchy dropped from the cloned copy.
  omarchy-theme-set "$theme" >/dev/null 2>&1
  # The rotation may have moved; the previews are always on the Sith wallpaper.
  omarchy-theme-bg-set "$HOME/.local/state/omarchy/current/theme/backgrounds/$PIN_BG" >/dev/null 2>&1 || true
  sleep 5
  # -n -R: no swap file and read-only, so killing it leaves nothing behind.
  open_window "$RW" "$RH" "$RX" "$RY" "uwsm-app -- foot -T $TAG -f monospace:size=$FONT_SIZE -e nvim -n -R $THEMES/$theme/$file"
  open_window "$LW" "$LH" "$LX" "$LY" "nautilus --new-window $THEMES/$theme/backgrounds"
  # Long enough for lua_ls to finish loading (its progress line sits in the
  # status bar until then) and for Files to draw its thumbnails.
  sleep 9
  hyprctl clients -j | python3 -c "
import json, sys
for c in json.load(sys.stdin):
    if c['title'] == '$TAG' or c['workspace']['name'] == '$WS':
        print('   window', c['class'], 'at', c['at'], 'size', c['size'], 'floating', c['floating'])"
  # omarchy-theme-set hands focus to a window it retints some seconds after it
  # returns, on whatever workspace that window is; come back before shooting.
  hyprctl dispatch "hl.dsp.focus({ workspace = \"$WS\" })" >/dev/null 2>&1 || true
  sleep 1
  # Shoot only if the monitor is on the workspace we set up: a shot taken
  # anywhere else is a picture of whatever the user had open.
  local now_ws
  now_ws=$(hyprctl monitors -j | python3 -c "import json,sys; print(next(m['activeWorkspace']['name'] for m in json.load(sys.stdin) if m['name'] == '$MONITOR'))")
  if [[ $now_ws != "$WS" ]]; then
    echo "workspace moved to $now_ws during the shot of $theme; nothing captured." >&2
    exit 1
  fi
  park_pointer
  grim -o "$MONITOR" "$TMP/shot.png"
  close_windows
  # 1800x1012, the size the theme switcher thumbnails are drawn from. Cut from
  # the top, so a 16:10 panel loses its bottom edge and keeps the bar.
  magick "$TMP/shot.png" -resize 1800x -gravity north -extent 1800x1012 \
    -strip -define png:compression-level=9 "$out"
  echo "$theme -> $out"
}

# Four wallpapers to a row: big enough to read as pictures, small enough for
# three rows.
gsettings set org.gnome.nautilus.icon-view default-zoom-level small-plus

shoot star-wars preview-full.png hyprland.lua

# Straight after the full star-wars, whose hyprland.lua switched hyprglass off:
# the cloned copy has no Lua to do that, and the plugin keeps its last setting.
stage_cloned_install
shoot star-wars preview.png colors.toml
"$REPO/tools/install-themes.sh" >/dev/null

shoot star-wars-glass preview-glass.png hyprland.lua

identify preview.png preview-full.png preview-glass.png
