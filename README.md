# Star Wars

An [Omarchy 4](https://omarchy.org/) theme built around a Sith lightsaber
wallpaper — navy-black smoke, one red blade, one violet blade — with frosted
glass everywhere: translucent windows, terminals, bar, menus and
notifications over a Hyprland blur.

> **The wallpapers are not in this repository.** They are Star Wars artwork
> by other people, so the repo doesn't redistribute them. `tools/get-wallpapers.sh`
> downloads them from their source and checks each against a pinned SHA-256.
> Screenshots aren't included for the same reason — they would show that
> artwork — but `tools/capture-previews.sh` makes them on your own desktop.

## Two themes: Star Wars and Star Wars Glass

This one directory is two Omarchy themes, kept in parallel:

| Theme | Slug | Glass |
|---|---|---|
| **Star Wars** | `star-wars` | Hyprland's own blur only; if hyprglass is loaded, the theme switches it off |
| **Star Wars Glass** | `star-wars-glass` | the same theme plus hyprglass liquid glass (`saber` preset) |

Every file — palette, borders, bar, terminals, wallpapers — comes from this
one directory, so the two cannot drift. `star-wars` is a symlink to it;
`star-wars-glass` is a directory of absolute symlinks into it, so that it can
carry its own thumbnail (`preview.png` -> `preview-glass.png`). The glass
itself is decided at load time in `hyprland.lua`, from the active theme's
name in `~/.local/state/omarchy/current/theme.name`. Change something once
and both themes have it.

Each theme gets its own thumbnail in the theme switcher once you run
`tools/capture-previews.sh` (`preview.png` and `preview-glass.png`, both
local-only); until then the switcher shows the first wallpaper.

## Install

Needs Omarchy 4 (Hyprland with the Lua config and the Quickshell bar). Star
Wars Glass additionally needs the hyprglass plugin, set up in step 4.

1. **Get the repo** somewhere permanent — both themes point into it, so don't
   move or delete it afterwards:

   ```bash
   git clone <this repo> ~/Projects/omarchy-star-wars-theme
   cd ~/Projects/omarchy-star-wars-theme
   ```

2. **Fetch the wallpapers** (about 20 MB; needs `curl` and ImageMagick):

   ```bash
   ./tools/get-wallpapers.sh
   ```

   It downloads each wallpaper from 4kwallpapers.com, rejects any file whose
   SHA-256 differs from the pinned one, darkens the strip under the bar on
   three of them, and builds the orrery unlock screen. Without it the theme
   still works — it just has no wallpapers of its own.

3. **Install both themes:**

   ```bash
   ./tools/install-themes.sh
   ```

   This creates `~/.config/omarchy/themes/star-wars` (a symlink to the repo)
   and `~/.config/omarchy/themes/star-wars-glass` (a directory of absolute
   symlinks into the repo, with its own `preview.png`). Both then show up in
   Omarchy Menu → Style → Theme as **Star Wars** and **Star Wars Glass**.

4. **Apply one** — from Omarchy Menu → Style → Theme, or:

   ```bash
   omarchy theme set star-wars          # Hyprland blur only
   omarchy theme set star-wars-glass    # plus hyprglass liquid glass
   ```

   Check it came up clean: `hyprctl configerrors` should print nothing.

5. **For Star Wars Glass, build and load hyprglass.** Without the plugin,
   Star Wars Glass looks exactly like Star Wars. See
   [Liquid glass](#liquid-glass-optional-hyprglass) for the build, the
   per-session load and loading it at every login.

6. **Optional extras:**

   - *GTK apps (Files, Disks, …)* read the theme's `gtk.css` only through a
     user-level link, and only at startup:

     ```bash
     ln -sfn ~/.local/state/omarchy/current/theme/gtk.css ~/.config/gtk-4.0/gtk.css
     nautilus -q    # then reopen Files
     ```

   - *Boot splash and login screen* (the Ahsoka orrery): Omarchy Menu → Style
     → Unlock → Star Wars, or `omarchy-plymouth-set-by-theme star-wars`
     (asks for sudo, rebuilds the initramfs).

   - *The bar* works with its background on or off — double-click the bar to
     switch. The theme's bar tint shows only with the background on.

   - *Theme-switcher thumbnails*: switch a monitor to an empty workspace and
     run `PREVIEW_WORKSPACE=<n> ./tools/capture-previews.sh`. It applies each
     theme in turn, screenshots it and puts your theme back.

### Why not `omarchy theme install`

A theme cloned by `omarchy theme install` is treated as untrusted: Omarchy
drops every `*.lua` and the terminal configs from it — exactly the files that
carry the blur, the glass switch and the terminal transparency. The symlinks
from `install-themes.sh` skip that filter. For the same reason `.git` is never
linked into Star Wars Glass, and the links are absolute: Omarchy stages a
theme with `cp -r`, which copies symlinks as they are.

### Update

```bash
cd ~/Projects/omarchy-star-wars-theme
git pull
./tools/get-wallpapers.sh        # fetches any wallpaper added since
./tools/install-themes.sh        # picks up any new top-level file
omarchy theme set star-wars-glass   # or star-wars — re-apply to stage the changes
```

After an Omarchy update that bumps Hyprland, rebuild hyprglass (see
[Liquid glass](#liquid-glass-optional-hyprglass)); until then Star Wars Glass
falls back to the plain look and a notification says so.

### Uninstall

Switch to another theme first, then:

```bash
rm ~/.config/omarchy/themes/star-wars
rm -r ~/.config/omarchy/themes/star-wars-glass   # only links, the repo is untouched
```

## Palette

| Role | Value | From |
|---|---|---|
| `background` | `#0d0e15` | the smoke field of the Sith wallpaper (`#11121b`), a step down |
| `dark_background` / `darker_background` | `#090a10` / `#050609` | one and two steps below |
| `lighter_background` | `#1b1c2b` | the violet haze in the smoke |
| `foreground` | `#dcd6e6` | the pale lavender rim light on the cloak |
| `accent` | `#7fa6d8` | the steel-blue smoke (`#626f90`), lifted |
| `selection` | `#26354f` | the smoke's mid tone (`#283646`), a step up |
| active border | pale steel `#cfe0f7` 40% -> accent `#7fa6d8` 18%, 90°; inactive smoke navy `#26354f` 50%; shell rims at 85% | a glass rim lit from above, after [Velora Liquid Glass](https://github.com/shoxjaxon-atabayev/omarchy-velora-liquid-glass) |
| `green` | `#3ddc97` | the stormtrooper's smoke |
| `orange` / `yellow` | `#ff7a3d` / `#f0c05a` | the Mandalorian's sparks |
| `blue` | `#4d9bff` | a Jedi blade |
| `magenta` | `#9b5cff` | the violet blade, a purer step |

## Glass

| What | Where | Setting |
|---|---|---|
| Blur | `hyprland.lua` | size 9, 3 passes, brightness 0.75, vibrancy 0.25 |
| Glass edge | `hyprland.lua` | rim border, superellipse corners (`rounding_power 3`), shadow offset 5 px down |
| App windows | `hyprland.lua` | opacity 0.90 active / 0.82 inactive |
| Terminals | `foot.ini`, `ghostty.conf`, `alacritty.toml`, `kitty.conf` | background alpha 0.72 + blur requested, window 1.0 / 0.94 |
| Bar | `shell.bar.toml` | `background` at 0.7 — the windows' hue, a step deeper; needs the bar's transparent mode off |
| Menu / launcher | `shell.menu.toml`, `shell.launcher.toml` | card 0.68 / 0.62, scrim 0.1 (unblurred), selected row in the accent |
| Notifications / popups | `shell.notifications.toml`, `shell.popups.toml` | 0.72 / 0.78 |
| Polkit / tooltip / lock field | `shell.polkit.toml`, `shell.tooltip.toml`, `shell.lock.toml` | 0.85 / 0.9 / 0.55 |
| GTK apps (Files…) | `gtk.css` | rgba surfaces |

The bar tint only applies while Omarchy's transparent-bar mode is off
(Omarchy Menu → Style → Bar → Transparency, or `omarchy-bar transparent
toggle`). With it on, the bar draws no background at all and shows the bare
top strip of the wallpaper — the darkest part of every image here — so it
reads near-black next to the frosted windows.

Terminals get alpha on the cell background rather than whole-window opacity,
so the text itself stays fully opaque. Each terminal config also asks for
blur: foot 1.28 speaks `ext-background-effect-v1`, and without `blur=yes`
it tells Hyprland not to blur behind it — translucent but sharp. Browsers, video players, games and
screen-share targets keep Omarchy's opaque rules.

Blur brightness 0.75 keeps text legible even over the bright
`nostalgic-room` wallpaper. For more see-through, lower the alpha values
above; for less, raise them.

`gtk.css` reaches GTK apps only through
`~/.config/gtk-4.0/gtk.css -> ~/.local/state/omarchy/current/theme/gtk.css`
(machine config, not part of the theme). GTK reads CSS at startup — restart
the app (`nautilus -q`) to repaint.

## Backgrounds

```
00-sith-star-wars-lightsaber-dark-background   <- default
ahsoka-tano-2023                                (5650x2160, cropped to the centre)
amandla-stenberg
kylo-ren-star-wars-dark-background-lightsaber-cosplay
kylo-ren-star-wars-the-rise-of-skywalker-black
nostalgic-room
sev-clone-troopers-star-wars-republic-commando
star-wars-ahsoka-orrery                         (DevSviat's ink, see below)
star-wars-maul
the-mandalorian-season-2-tv-series-2020
```

None of these files are in the repo; `tools/get-wallpapers.sh` fetches them
from [4kwallpapers.com](https://4kwallpapers.com/) (names as published
there), where the credits are. The Ahsoka Tano 2023 art is by Andre Zottolo
and The Mandalorian season 2 edit by aggro, per the files' own metadata; the
characters and the rest are Lucasfilm's. All rights stay with their owners.

Three wallpapers — Kylo Ren with the lightsaber (cosplay), the Sev clone
trooper and Maul — carry a
soft dark scrim across the top (`tools/bar-scrim.sh`: black at 72% under the
bar, fading out by 14% of the height). The rest are untouched. With the bar's own background off — double-click the bar — Omarchy
picks one text colour from the *average* of the strip under it, so a dark
strip with a lightsaber or a burst of smoke got light text that vanished over
the bright part. On those three the scrim keeps every pixel under the bar at 6.6:1
or better against the light bar text, in both bar modes. The script processes
only the wallpapers listed in it, marks what it processed and skips it on a
rerun.

Omarchy has no default-background key: on a first apply it takes the first
file in sort order, hence the `00-` prefix.

## Unlock screen

Omarchy Menu -> Style -> Unlock (the Plymouth boot splash and SDDM greeter)
uses `unlock.png`: the Ahsoka orrery, traced in a navy-grey ink so the boot
splash matches the orrery wallpaper in the rotation. `tools/generate-orrery.sh`
builds both, and a `preview-unlock.png` for the picker, from the untouched
Ahsoka orrery artwork — `tools/get-wallpapers.sh` fetches that and runs it for
you. Like the wallpapers, none of these files are committed.

## Liquid glass (optional hyprglass)

`hyprland.lua` carries a configuration block for the
[hyprglass](https://github.com/hyprnux/hyprglass) compositor plugin — edge
refraction, chromatic aberration and a specular sheen on windows, the bar, the
Omarchy menu and the bar panels. The block only runs when the plugin is
already loaded; without it the theme is unchanged. It follows the
[Velora Liquid Glass](https://github.com/shoxjaxon-atabayev/omarchy-velora-liquid-glass)
approach, with a softer preset of its own: `saber` inherits hyprglass's
`glass` but cuts refraction from 8.0 to 3.0, chromatic aberration from 0.5 to
0.15 and lens distortion from 0.3 to 0.12, with a thinner bezel — corners read
as rounded glass instead of a fisheye. The 0.55 alpha gate matches the blur
rules, so a menu's scrim never refracts.

Measured cost on this laptop (Hyprland on the RTX 4060, two high-res
monitors, 15 s per case, no other test windows open):

| Case | Hyprland CPU | GPU power |
|---|---|---|
| hyprglass off, idle | 1.1% | 9.0 W |
| hyprglass on, idle | 3.9% | 9.4 W |
| hyprglass on, a window redrawing at 30 Hz | 5.0% | 10.4 W |
| hyprglass off, a window redrawing at 30 Hz | 5.3% | 9.9 W |

That is with `live_resample` off for the shell layers (it re-rendered the
bar's glass on every clock tick and pushed idle CPU to 5.3%). What remains is
about 3% of one core and 0.5–1.5 W — small, but not free. GPU utilisation
swung too much between runs to quote. Unload it on battery if that matters.

The plugin must match the running Hyprland exactly. The prebuilt release links
against an older aquamarine, so build it locally:

```bash
git clone --depth 1 --branch v0.8.1 https://github.com/hyprnux/hyprglass ~/.local/share/hyprglass/src
git -C ~/.local/share/hyprglass/src rev-parse HEAD   # expect 725383e86a2a79457a81cdbc2ceb33c07363bd8d
make -C ~/.local/share/hyprglass/src
hyprctl plugin load ~/.local/share/hyprglass/src/hyprglass.so
hyprctl reload        # so the theme's hyprglass block runs
```

A compositor plugin runs inside Hyprland with full access to your session,
so check the commit before building: a tag can be moved, a commit hash
cannot. The hash above is the v0.8.1 this theme was tested with.

That loads it for the current session only. To load it at every login, run
the same two commands on start, e.g. in `~/.config/hypr/autostart.lua`:

```lua
o.exec_on_start([[f="$HOME/.local/share/hyprglass/src/hyprglass.so"; [ -f "$f" ] && hyprctl plugin load "$f" | grep -qx ok && hyprctl reload]])
```

The theme leaves `blur.new_optimizations` on: hyprglass sets `noblur` on the
windows and layers it glasses, so the cached blur never hides the glass. Rebuild after every Hyprland
update; a mismatched build refuses to load. To unload:
`hyprctl plugin unload ~/.local/share/hyprglass/src/hyprglass.so`.

## Animations

`hyprland.lua` replaces Omarchy's animation set with four curves:

| Curve | Feel | Used by |
|---|---|---|
| `ignite` | fast, slight overshoot — a blade snapping out | windows opening, special workspace |
| `retract` | eases in, then gone | windows closing, fade-outs |
| `glide` | long ease-out | moves, resizes, border colour, fades |
| `hyperspace` | slow start, hard jump, soft landing | workspace switches (slide + fade) |

Workspace switching is animated here, while Omarchy's defaults have it off.
The active/inactive opacity change fades, so focus moves smoothly across the
glass. The bar, the Omarchy menu and the bar panels keep Omarchy's own `no_anim`
rules: Hyprland can only move or scale a whole full-screen layer, so the
panels' motion belongs in the shell's QML, not in the theme. Anything in `~/.config/hypr/looknfeel.lua` still wins.

## Generated from `colors.toml`

Neovim (aether), btop, Chromium, Helix, Obsidian, VS Code (a local "Omarchy"
theme), the keyboard backlight (steel blue) and the rest come from
Omarchy's own templates. Icons are `Yaru-blue-dark`.

## What installing this runs

- `hyprland.lua` is Lua that Hyprland executes at every config load — that is
  how Omarchy themes set blur, animations and window rules, and why
  `omarchy theme install` strips `*.lua` from themes it clones. This one only
  sets options and rules and reads `~/.local/state/omarchy/current/theme.name`
  to pick the glass variant; it starts no processes. Read it before
  installing, as with any theme that ships Lua.
- The scripts in `tools/` run only when you call them. `install-themes.sh`
  writes under `~/.config/omarchy/themes/` and only replaces what it created
  itself; `get-wallpapers.sh` downloads over HTTPS and rejects anything that
  fails its pinned SHA-256; the others work inside the checkout and a private
  temporary directory.
- hyprglass is optional, third-party and runs inside the compositor — see
  [Liquid glass](#liquid-glass-optional-hyprglass).

## tools/

| File | What it does |
|---|---|
| `get-wallpapers.sh` | downloads the wallpapers (pinned SHA-256), applies the bar scrim, builds the orrery files |
| `generate-orrery.sh` | builds `unlock.png`, `preview-unlock.png` and the orrery wallpaper |
| `capture-previews.sh` | shoots `preview.png` and `preview-glass.png` from the running desktop — each theme applied in turn, two floating windows placed so a lightsaber crosses each window's edge, where the glass differs most |
| `install-themes.sh` | installs both themes: the symlink and the Star Wars Glass link directory |
| `bar-scrim.sh` | darkens the strip under the bar in the listed wallpapers, so the bar stays legible with its background on or off |
