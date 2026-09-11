#!/bin/bash
# Darken the strip under the bar in the wallpapers where the bar's icons and
# text got lost with its own background off:
#
#   ./tools/bar-scrim.sh            # the wallpapers listed in SCRIM below
#   ./tools/bar-scrim.sh FILE...    # just these
#
# Only the wallpapers the user picked out get it — the rest stay exactly as
# they came. Add a file to SCRIM (and run the script) only when the user
# reports its bar as unreadable.
#
# With the bar's background off (double-click the bar, or Omarchy Menu ->
# Style -> Bar -> Transparency), Omarchy averages the whole strip under the bar
# to one colour and picks the light or dark text by contrast against that
# average (omarchy-bar-text-color). A mostly dark strip with a lightsaber or a
# burst of smoke in it averages dark, so it gets light text — which then
# vanishes over the bright part. No single text colour can fix that, so the
# strip itself is darkened instead.
#
# The scrim is black at 72% from the top edge down to 4% of the height, then
# fades out on a smoothstep by 14%. The bar is about 2.3-2.6% of the height
# on this machine's screens, so it always sits on the solid part: even a white
# blade core under an icon ends up near #474747, about 5.9:1 against the light
# bar text.
#
# Idempotent: a processed file carries the comment "star-wars bar scrim v1"
# and is skipped on a rerun. The Ahsoka orrery is never touched — it must
# stay byte-for-byte DevSviat's file.
set -euo pipefail

cd "$(dirname "$0")/.."

MARK="star-wars bar scrim v1"
ALPHA=0.72
SOLID=0.04
FADE_END=0.14

# The wallpapers the user reported, 2026-09-11: a lightsaber, smoke or a
# painted burst sat right under the bar icons.
SCRIM=(
  kylo-ren-star-wars-dark-background-lightsaber-cosplay-5k-8k-3840x2160-7587.jpg
  sev-clone-troopers-star-wars-republic-commando-3840x2160-302.jpg
  star-wars-maul-3840x2160-25269.jpg
)

files=("$@")
if ((${#files[@]} == 0)); then
  files=("${SCRIM[@]/#/backgrounds/}")
fi

for file in "${files[@]}"; do
  [[ -f $file ]] || continue
  case ${file##*/} in
    star-wars-ahsoka-orrery-*) echo "skip   ${file##*/} (orrery stays DevSviat's)"; continue ;;
  esac
  if [[ $(magick identify -format '%c' "$file" 2>/dev/null) == *"$MARK"* ]]; then
    echo "skip   ${file##*/} (already has the scrim)"
    continue
  fi

  read -r w h < <(magick identify -format '%w %h\n' "$file")
  tmp=$(mktemp --suffix=".${file##*.}")

  # One column holds the vertical alpha profile; it is scaled to the full
  # width and used as the opacity of a black layer over the wallpaper.
  # (`tt`, not `t`: single-letter names are reserved symbols in -fx.)
  magick "$file" \
    \( -size "1x$h" xc: -fx "tt=(j/h-$SOLID)/($FADE_END-$SOLID); tt=tt<0?0:(tt>1?1:tt); $ALPHA*(1-tt*tt*(3-2*tt))" \
       -scale "${w}x${h}!" \( -size "${w}x${h}" xc:black \) +swap \
       -alpha off -compose CopyOpacity -composite \) \
    -compose over -composite \
    -set comment "$MARK" -quality 92 "$tmp"
  mv "$tmp" "$file"
  echo "scrim  ${file##*/}"
done
