#!/bin/bash
# Install both themes, in full, from this checkout:
#
#   ./tools/install-themes.sh
#
#   ~/.config/omarchy/themes/star-wars        preview.png -> preview-full.png
#   ~/.config/omarchy/themes/star-wars-glass  preview.png -> preview-glass.png
#
# Each is a real directory of absolute symlinks into this repo, so every file
# is still the repo's own and the two themes cannot drift.
#
# A `<name>.example` file is linked in as `<name>`, replacing the plain file of
# that name if there is one. That is how the glass gets in: hyprland.lua and
# the terminal configs exist here only as `.example`, because omarchy-theme-set
# drops them from a theme cloned by `omarchy theme install`, and the
# shell.*.toml.example files are the translucent cards that need the blur
# hyprland.lua sets up.
#
# A directory rather than one symlink to the repo, for two reasons: the rename
# above, and the theme switcher's thumbnail, which is always `preview.png` at
# the root of the theme directory.
#
# The links are absolute on purpose: omarchy-theme-set stages a theme with
# `cp -r`, which copies symlinks as they are, so a relative link would point
# nowhere once staged in ~/.local/state/omarchy/current/theme.
#
# `.git` must never be linked in: omarchy-theme-set treats a theme directory
# holding `.git` as installed from a repo and strips every *.lua from it.
#
# unlock.png is copied, not linked: omarchy-plymouth-set refuses a symlinked
# logo, so "Set unlock" fails on a link.
#
# Rerun after adding or renaming a top-level file in the repo, or after
# changing unlock.png.
set -euo pipefail
shopt -s nullglob dotglob

cd "$(dirname "$0")/.."
REPO=$PWD
THEMES=$HOME/.config/omarchy/themes
MARKER=.star-wars-links
# Written for star-wars-glass before both themes shared one marker.
LEGACY_MARKER=.star-wars-glass-links

# Replace a theme only if it is ours: a symlink, or a directory this script
# built (it carries the marker file).
remove_ours() {
  local dir=$1
  if [[ -L $dir ]]; then
    rm "$dir"
  elif [[ -d $dir ]]; then
    if [[ ! -f $dir/$MARKER && ! -f $dir/$LEGACY_MARKER ]]; then
      echo "refusing to replace $dir: it was not created by this script" >&2
      echo "if it came from \`omarchy theme install\`, remove it first: omarchy theme remove ${dir##*/}" >&2
      exit 1
    fi
    rm -rf "$dir"
  fi
}

build_theme() {
  local dir=$THEMES/$1 preview=$2 entry name

  remove_ours "$dir"
  mkdir "$dir"
  touch "$dir/$MARKER"

  for entry in "$REPO"/*; do
    name=${entry##*/}
    case $name in
      .git | .gitignore | .impeccable | CLAUDE.md | preview.png | preview-full.png | preview-glass.png) continue ;;
      unlock.png) cp "$entry" "$dir/$name" ;;
      *.example) ln -s "$entry" "$dir/${name%.example}" ;;
      *) [[ -e $entry.example ]] || ln -s "$entry" "$dir/$name" ;;
    esac
  done
  ln -s "$REPO/$preview" "$dir/preview.png"

  echo "$1 -> $dir ($(find "$dir" -maxdepth 1 -type l | wc -l) links)"
}

mkdir -p "$THEMES"
build_theme star-wars preview-full.png
build_theme star-wars-glass preview-glass.png
