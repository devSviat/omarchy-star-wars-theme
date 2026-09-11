# Star Wars — notes for a new session

An Omarchy 4 theme built around the Sith lightsaber wallpaper: navy-black
smoke, a red blade and a violet one. The accent is the steel-blue smoke around
the figure, lifted, and the border runs from its light to its shadow. Its defining feature is glass — translucent windows, terminals
and shell surfaces over a Hyprland blur. Local only; no remote.

**The wallpapers are committed.** The repo is public, and the wallpapers are
third-party Star Wars art: the user first published without them (history
rewritten to purge images, a downloader script), then chose to ship them after
all. `backgrounds/`, `unlock.png`, `preview-unlock.png`, `preview.png` and
`preview-glass.png` are in git; README credits the authors and says the MIT
license does not cover them. Keep that credit and notice accurate when the
set of wallpapers changes.

Derived from `~/Projects/omarchy-devsviat-theme` (slug `dev-sviat`); that
repo's `docs/RESEARCH.md` is the full account of how Omarchy 4 theming works
and is not duplicated here.

## Two themes, maintained in parallel

This directory is **two** Omarchy themes: `star-wars` (**Star Wars**, no
hyprglass) and `star-wars-glass` (**Star Wars Glass**, with hyprglass).
`./tools/install-themes.sh` installs both: `star-wars` is a symlink to this
repo; `star-wars-glass` is a real directory of **absolute** symlinks into it,
with `preview.png -> preview-glass.png` so the switcher shows its own
thumbnail (it only reads `preview.png` at a theme's root). Absolute because
`omarchy-theme-set` stages with `cp -r`, which copies links verbatim; never
link `.git` in, or the theme is treated as repo-installed and loses its Lua.

Rules for keeping them in parallel:

- **Never split the files into two copies.** Every change goes into this one
  directory and lands in both themes. After adding a top-level file, rerun
  `./tools/install-themes.sh` so Star Wars Glass links it too.
- **The only difference is hyprglass**, chosen in `hyprland.lua` by reading
  `~/.local/state/omarchy/current/theme.name`. `omarchy-theme-set` writes that
  file right after swapping the theme in and before its final `hyprctl reload`
  (`omarchy-restart-hyprctl`), so the name is always current.
- In `star-wars` a loaded hyprglass is set `enabled = false` and
  `layers.enabled = false` — the plugin stays loaded (autostart) but draws
  nothing, so the theme really is Hyprland's blur alone.
- Anything else that should differ between the two must be keyed the same way
  (on the theme name at load time), not by forking a file.
- After a change, apply and check **both**: `omarchy theme set star-wars`, then
  `omarchy theme set star-wars-glass`, `hyprctl configerrors` each time.
- Both slugs have a wallpaper pin (`~/.local/state/omarchy/pinned-background/`),
  since the shared `backgrounds/` paths would otherwise make a switch advance
  the rotation.

Thumbnails: `preview.png` (Star Wars) and `preview-glass.png` (Star Wars
Glass) are real screenshots from `./tools/capture-previews.sh`: it applies
each theme for real (fastfetch prints the theme name, so a shot taken under
the wrong theme is visibly wrong) and floats two windows so the Sith
wallpaper's blades cross their edges — where hyprglass visibly bends the
light and plain blur does not. It needs an empty visible workspace
(`PREVIEW_WORKSPACE`) and puts the original theme back.

## Installed by `tools/install-themes.sh`, deliberately

```bash
./tools/install-themes.sh
```

It makes `~/.config/omarchy/themes/star-wars` a symlink to this repo and
`~/.config/omarchy/themes/star-wars-glass` a directory of absolute symlinks
into it (see "Two themes" below). `omarchy-theme-set` treats a theme directory
containing `.git` as untrusted and strips every `*.lua`, the four terminal
configs and `vscode.json`; neither install shape trips that check, so both
stage in full. Never `omarchy theme install` this theme — it would drop
`hyprland.lua` (all of the blur and the glass switch) and the terminal configs
(all of the terminal transparency). The user-facing install guide is the
Install section of README.md; keep it in step with this script.

## Where the transparency lives

| Layer | File | Value |
|---|---|---|
| Animations (curves ignite / retract / glide / hyperspace) | `hyprland.lua` | workspaces slide + fade, 250 ms. Bar panels are NOT animated here: `omarchy-keyboard-panel` is full-screen, and Hyprland's layer `slide` always starts fully off-screen while `popin` scales about the screen centre (LayerSurfaceAnimationController.cpp), so a short drop from the bar can only live in the shell's QML |
| Blur, shadow, rounding, border | `hyprland.lua` | blur size 9 x 3 passes, brightness 0.75 |
| Window opacity (non-terminal) | `hyprland.lua` | `default-opacity` tag -> `0.9 0.82` |
| Terminal window opacity | `hyprland.lua` | `terminal` tag -> `1.0 0.94` |
| Terminal background | `foot.ini`, `ghostty.conf`, `alacritty.toml`, `kitty.conf` | alpha 0.72 |
| Shell bar / menus / notifications | `shell.*.toml` | `background-alpha` 0.45 – 0.9 |
| Blur behind shell layers | `hyprland.lua` | `hl.layer_rule`: bar `ignore_alpha 0.15`, full-screen layers `0.55` so only the card blurs, never the scrim |
| GTK / libadwaita apps | `gtk.css` | rgba surfaces |

Browsers, video players, games, PiP and screen-share targets drop the
`default-opacity` tag in Omarchy's own `default/hypr/apps/`, so they stay
opaque — deliberately untouched.

Terminals get alpha on the cell background, not whole-window opacity, so the
text stays fully opaque. foot reads `alpha` only at startup — a terminal
opened before the theme was applied stays opaque until reopened.

**Every terminal config must ask for blur** (`blur=yes` in foot, and the
matching keys in ghostty/kitty/alacritty). foot 1.28 is built `+blur` and
speaks `ext-background-effect-v1`; with its default `blur=no` it tells
Hyprland not to blur behind it, so the window is translucent but sharp and no
Hyprland setting can override that. Found by an A/B run of two foot windows.

## The bar's own transparent mode hides the theme's bar tint

`shell.bar.toml` sets the bar's glass tint, but Omarchy's bar has a separate
transparent mode (`bar.transparent` in `~/.config/omarchy/shell.json`, toggled
from Omarchy Menu -> Style -> Bar -> Transparency or `omarchy-bar transparent
true|false`). With it on, the bar draws no background at all — only the
darkest strip of the wallpaper shows, and no theme value reaches it. That is
what made the bar read near-black next to the windows. On this machine it is
set to `false`; the shell writes that key only on a manual toggle.

When measuring the bar against a window, wait a few seconds after
`omarchy theme set`: the theme transition briefly paints the bar black.

## hyprglass

`hyprland.lua` ends with an `if hl.plugin and hl.plugin.hyprglass` block — inert
unless the plugin is loaded. The prebuilt `hyprglass.so` release links
`libaquamarine.so.13`, this machine has `.so.14`, so it is built locally in
`~/.local/share/hyprglass/src` (plain `make`, no hyprpm — hyprpm needs sudo and
cmake/meson). Autoloaded from `~/.config/hypr/autostart.lua`
(machine config): `hyprctl plugin load`, then `hyprctl reload` so the block
runs; a failed load sends a notification to rebuild. The block leaves
`blur.new_optimizations` on: hyprglass's `manage_window_blur` / `layers.manage_blur`
already set noblur on glassed surfaces (Velora's advice to turn it off is outdated). Rebuild after each
Hyprland update. The theme defines its own preset, `saber` (inherits
`glass`, refraction 3.0 instead of 8.0, aberration 0.15, lens 0.12, bezel
0.035) — the stock `glass` bent the corners into a fisheye. Measured cost with
`layers.live_resample = false` (on, it re-rendered the bar glass every clock
tick): Hyprland idle CPU 1.1% without the plugin, 3.9% with it; about +0.5 to
1.5 W. When benchmarking, find the test windows by /proc cmdline — `pgrep -f`
on a pattern that appears in your own command line kills the script, and
`^foot` misses `/usr/bin/foot`.

Bar-panel open/close motion was tried and dropped: Hyprland can only move a
whole full-screen layer (`slide` starts fully off-screen, `popin` scales about
the screen centre), so a correct drop needs a patch to Omarchy's
`shell/Ui/KeyboardPanel.qml` — outside the theme, overwritten by every update,
and not worth an upstream PR. The panels keep Omarchy's own 140 ms fade.

## Adding a wallpaper

Copy it into `backgrounds/` as it is. Do **not** darken it on your own: the
user asked for the bar scrim only on the wallpapers they named, and had the
scrim removed from every other one.

The user toggles the bar's own background off and on (double-click the bar);
with it off Omarchy picks one text colour from the average of the strip under
the bar, so bright spots there can swallow the icons. If the user reports that
for a wallpaper, add it to the `SCRIM` list in `tools/bar-scrim.sh` and run
the script — it darkens the top (6.6:1 or better against the bar text), marks
the file, and never touches the orrery, which must stay byte-identical to
DevSviat's.

## Things that have already broken once (inherited from dev-sviat)

1. **No inline comments in `colors.toml`** — `omacalc` swallows them into the
   value and draws a black window. Same rule kept in `shell.*.toml`.
2. **`shell.<section>.toml` replaces a section, it does not merge.** Every
   file carries the complete section.
3. **`hyprland.lua` and the terminal configs are hand-written**, so their
   colours are not generated. Keep the border values in step with
   `hyprland_active_border` / `hyprland_inactive_border`, and the terminal
   palettes with `colors.toml`.

## After changing anything

```bash
omarchy theme set star-wars            # stderr must be empty: nothing dropped
hyprctl configerrors                   # must be empty
grep -r '{{' ~/.local/state/omarchy/current/theme/ \
  --exclude-dir=tools --exclude=README.md --exclude=CLAUDE.md   # must find nothing
```

Re-applying advances the wallpaper rotation; this machine pins it back with
`~/.local/bin/omarchy-bg-pin` (pinned to the `00-sith-...` wallpaper).

Editing `colors.toml` makes both previews stale (`./tools/capture-previews.sh`)
and `preview-unlock.png` stale (`./tools/generate-orrery.sh
~/Wallpapers/star-wars-ahsoka-3840x2160-12833.jpg`). `unlock.png` and the
orrery wallpaper deliberately use DevSviat's ink, not this palette, so they
match that theme's files byte for byte.

The boot splash is applied separately, only on request:

```bash
omarchy-plymouth-set-by-theme star-wars   # sudo + mkinitcpio, takes a while
```
