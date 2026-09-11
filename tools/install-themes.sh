#!/bin/bash
# Install both themes from this checkout:
#
#   ./tools/install-themes.sh
#
#   ~/.config/omarchy/themes/star-wars        -> symlink to this repo
#   ~/.config/omarchy/themes/star-wars-glass  -> a real directory of absolute
#                                                symlinks into this repo, with
#                                                preview.png -> preview-glass.png
#
# Why the glass theme is not just a second symlink: Omarchy's theme switcher
# takes the thumbnail from `preview.png` at the root of the theme directory,
# so two symlinks to one directory would show the same picture. Every other
# file is still the repo's own, so the two themes cannot drift.
#
# The links are absolute on purpose: omarchy-theme-set stages a theme with
# `cp -r`, which copies symlinks as they are, so a relative link would point
# nowhere once staged in ~/.local/state/omarchy/current/theme.
#
# `.git` must never be linked in: omarchy-theme-set treats a theme directory
# holding `.git` as installed from a repo and strips every *.lua from it.
#
# Rerun after adding a new top-level file to the repo, so Star Wars Glass
# gets a link to it too.
set -euo pipefail
shopt -s nullglob dotglob

cd "$(dirname "$0")/.."
REPO=$PWD
THEMES=$HOME/.config/omarchy/themes
GLASS=$THEMES/star-wars-glass
MARKER=.star-wars-glass-links

mkdir -p "$THEMES"
ln -sfn "$REPO" "$THEMES/star-wars"

# Replace the glass theme only if it is ours: a symlink, or a directory this
# script built (it carries the marker file).
if [[ -L $GLASS ]]; then
  rm "$GLASS"
elif [[ -d $GLASS ]]; then
  if [[ ! -f $GLASS/$MARKER ]]; then
    echo "refusing to replace $GLASS: it was not created by this script" >&2
    exit 1
  fi
  rm -rf "$GLASS"
fi

mkdir "$GLASS"
touch "$GLASS/$MARKER"

for entry in "$REPO"/*; do
  name=${entry##*/}
  case $name in
    .git | .gitignore | .impeccable | CLAUDE.md | preview.png | preview-glass.png) continue ;;
  esac
  ln -s "$entry" "$GLASS/$name"
done
ln -s "$REPO/preview-glass.png" "$GLASS/preview.png"

echo "star-wars       -> $(readlink "$THEMES/star-wars")"
echo "star-wars-glass -> $GLASS ($(find "$GLASS" -maxdepth 1 -type l | wc -l) links)"
