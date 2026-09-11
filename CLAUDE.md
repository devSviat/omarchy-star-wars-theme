# Star Wars — notes for a new session

An Omarchy 4 theme built around the Sith lightsaber wallpaper: navy-black
smoke, a red blade and a violet one. The accent is the steel-blue smoke around
the figure, lifted, and the border runs from its light to its shadow. Its defining feature is glass — translucent windows, terminals
and shell surfaces over a Hyprland blur. Local only; no remote.

Derived from `~/Projects/omarchy-devsviat-theme` (slug `dev-sviat`); that
repo's `docs/RESEARCH.md` is the full account of how Omarchy 4 theming works
and is not duplicated here.

## Two themes, maintained in parallel

This directory is **two** Omarchy themes: `star-wars` (**Star Wars**, no
hyprglass) and `star-wars-glass` (**Star Wars Glass**, with hyprglass). Both
are symlinks to this one repo:

```bash
ln -sfn /home/sviat/Projects/omarchy-star-wars-theme ~/.config/omarchy/themes/star-wars
ln -sfn /home/sviat/Projects/omarchy-star-wars-theme ~/.config/omarchy/themes/star-wars-glass
```

Rules for keeping them in parallel:

- **Never split the files into two copies.** Every change goes into this one
  directory and lands in both themes.
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

`preview.png` is shared, so the theme switcher shows the same thumbnail for
both.

## Installed as a symlink, deliberately

```bash
ln -sfn /home/sviat/Projects/omarchy-star-wars-theme ~/.config/omarchy/themes/star-wars
```

`omarchy-theme-set` treats a directory containing `.git` as untrusted and
strips every `*.lua`, the four terminal configs and `vscode.json`. A symlink
fails that check and stages in full. Never `omarchy theme install` this
theme — it would drop `hyprland.lua` (all of the blur) and the terminal
configs (all of the terminal transparency).

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

Editing `colors.toml` makes `preview.png` stale (`./tools/generate-preview.sh`)
and `preview-unlock.png` stale (`./tools/generate-orrery.sh
~/Wallpapers/star-wars-ahsoka-3840x2160-12833.jpg`). `unlock.png` and the
orrery wallpaper deliberately use DevSviat's ink, not this palette, so they
match that theme's files byte for byte.

The boot splash is applied separately, only on request:

```bash
omarchy-plymouth-set-by-theme star-wars   # sudo + mkinitcpio, takes a while
```
