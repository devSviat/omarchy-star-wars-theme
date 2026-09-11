#!/usr/bin/env bash
# Build everything drawn from the Ahsoka orrery, exactly as the DevSviat
# theme draws it.
#
#   ./tools/generate-orrery.sh <path-to-star-wars-ahsoka-3840x2160-12833.jpg>
#
#   unlock.png                                     the Plymouth / SDDM logo
#   preview-unlock.png                             its picker thumbnail
#   backgrounds/star-wars-ahsoka-orrery-3840x2160  the wallpaper
#
# Adapted from the DevSviat theme's generator. The source is the untouched
# star-wars-ahsoka wallpaper — navy line art on a near-black field — and it
# is deliberately not in this repo; pass its path to rebuild. Outputs are
# byte-for-byte reproducible, so a rerun on the same file is a no-op in git.
#
# The ink is DevSviat's own: navy-grey orbits up to near-white stars, over
# that theme's #1a1a1a. unlock.png and the wallpaper therefore come out
# byte-for-byte identical to the ones in ~/Projects/omarchy-devsviat-theme,
# so the boot splash matches the Ahsoka wallpaper. Only preview-unlock.png
# differs: it shows the logo over THIS theme's `background`, because that is
# the flat fill Plymouth draws behind it when this theme is picked.
#
# unlock.png is not a wallpaper. omarchy-plymouth-set publishes it as
# logo.png, the Plymouth script draws it centred at native size over a flat
# `background`, and puts the password entry 40 px under it. So it is
# transparent everywhere the background should show, and 720 px tall so the
# entry stays on a 1920x1080 screen (180 + 720 + 40 + 48 = 988).
set -euo pipefail

SRC=${1:?usage: tools/generate-orrery.sh <path-to-star-wars-ahsoka-3840x2160-12833.jpg>}
SRC=$(realpath -e -- "$SRC")

cd "$(dirname "$0")/.."

WALLPAPER=backgrounds/star-wars-ahsoka-orrery-3840x2160.png
OMARCHY=${OMARCHY_PATH:-/usr/share/omarchy}
ASSETS=$OMARCHY/default/plymouth

BACKGROUND="#0d0e15"     # colors.toml background — Plymouth's fill
FOREGROUND="#dcd6e6"     # colors.toml foreground — entry, lock, bullets
WALLPAPER_BG="#1a1a1a"   # DevSviat's background, kept so the wallpaper matches it
INK_LOW="#5b8fa0"        # DevSviat: its accent, darkened — the faintest orbits
INK_HIGH="#eaf2f6"       # DevSviat: just above its light_foreground — the stars

# The lit part of the frame, from `magick "$SRC" -fuzz 8% -trim`.
CROP=1961x1966+940+98
SIZE=720

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Greyscale first: the drawing is monochrome navy, so luminance carries every
# line without the JPEG's colour noise. The 2% black point drops that noise;
# the 42% white point pushes the brightest stars to solid. Colour and coverage
# both come from that greyscale, so a line's weight and brightness agree.
# Gamma 1.3 on the mask keeps the thinnest orbits alive on a dim boot panel.
# -strip everywhere: otherwise ImageMagick writes timestamps and a rerun
# dirties git without a pixel moving.
ink() {
  local src=$1 out=$2
  shift 2
  magick "$src" "$@" -colorspace Gray -level 2%,42% "$TMP/gray.png"
  magick "$TMP/gray.png" +level-colors "$INK_LOW","$INK_HIGH" "$TMP/rgb.png"
  magick "$TMP/gray.png" -gamma 1.3 "$TMP/mask.png"
  magick "$TMP/rgb.png" "$TMP/mask.png" \
    -alpha off -compose CopyOpacity -composite \
    -strip -define png:compression-level=9 PNG32:"$out"
}

# --- unlock.png --------------------------------------------------------
ink "$SRC" unlock.png -crop "$CROP" +repage -resize ${SIZE}x${SIZE}

# --- the wallpaper -----------------------------------------------------
# Same ink over DevSviat's flat fill, full frame. PNG: line art on a
# near-flat field rings badly as JPEG.
ink "$SRC" "$TMP/wallpaper.png"
magick -size 3840x2160 xc:"$WALLPAPER_BG" "$TMP/wallpaper.png" -composite \
  -depth 8 -strip -define png:compression-level=9 "$WALLPAPER"

# --- preview-unlock.png ------------------------------------------------
# Mirrors default/plymouth/omarchy.script: logo centred, entry 40 px below
# it, lock at 80% of the entry height 15 px to its left, bullets 7 px on a
# 12 px pitch starting 20 px into the entry.
W=1920
H=1080

read -r LOGO_W LOGO_H < <(magick identify -format '%w %h\n' unlock.png)
LOGO_X=$(((W - LOGO_W) / 2))
LOGO_Y=$(((H - LOGO_H) / 2))

read -r ENTRY_W ENTRY_H < <(magick identify -format '%w %h\n' "$ASSETS/entry.png")
ENTRY_X=$(((W - ENTRY_W) / 2))
ENTRY_Y=$((LOGO_Y + LOGO_H + 40))

LOCK_H=$((ENTRY_H * 8 / 10))
LOCK_W=$((84 * LOCK_H / 96))
LOCK_X=$((ENTRY_X - LOCK_W - 15))
LOCK_Y=$((ENTRY_Y + (ENTRY_H - LOCK_H) / 2))

# omarchy-plymouth-set recolours these three the same way, to `foreground`.
for asset in entry lock bullet; do
  magick "$ASSETS/$asset.png" -channel RGB \
    +level-colors "$FOREGROUND","$FOREGROUND" "$TMP/$asset.png"
done

magick -size ${W}x${H} xc:"$BACKGROUND" \
  unlock.png -geometry +${LOGO_X}+${LOGO_Y} -compose over -composite \
  \( "$TMP/entry.png" \) -geometry +${ENTRY_X}+${ENTRY_Y} -composite \
  \( "$TMP/lock.png" -resize ${LOCK_W}x${LOCK_H}! \) -geometry +${LOCK_X}+${LOCK_Y} -composite \
  "$TMP/stage.png"

BULLET_Y=$((ENTRY_Y + ENTRY_H / 2 - 3))
args=()
for i in 0 1 2 3; do
  args+=(\( "$TMP/bullet.png" -resize 7x7! \)
         -geometry "+$((ENTRY_X + 20 + i * 12))+${BULLET_Y}" -composite)
done

magick "$TMP/stage.png" "${args[@]}" \
  -depth 8 -strip -define png:compression-level=9 preview-unlock.png

identify unlock.png preview-unlock.png "$WALLPAPER"
