# Star Wars

An [Omarchy 4](https://omarchy.org/) theme built around a Sith lightsaber
wallpaper — navy-black smoke, one red blade, one violet blade — with frosted
glass everywhere: translucent windows, terminals, bar, menus and
notifications over a Hyprland blur.

![preview](preview.png)

## Install

```bash
ln -sfn "$PWD" ~/.config/omarchy/themes/star-wars
omarchy theme set star-wars
```

Use a symlink, not `omarchy theme install`. A theme cloned from a repo is
filtered: Omarchy drops every `*.lua` and the terminal configs from it, and
those are exactly the files that carry the blur and the terminal
transparency. A symlink skips that filter.

## Palette

| Role | Value | From |
|---|---|---|
| `background` | `#0d0e15` | the smoke field of the Sith wallpaper (`#11121b`), a step down |
| `dark_background` / `darker_background` | `#090a10` / `#050609` | one and two steps below |
| `lighter_background` | `#1b1c2b` | the violet haze in the smoke |
| `foreground` | `#dcd6e6` | the pale lavender rim light on the cloak |
| `accent` | `#7fa6d8` | the steel-blue smoke (`#626f90`), lifted |
| `selection` | `#26354f` | the smoke's mid tone (`#283646`), a step up |
| active border | `#8fb4e3` -> `#4f6a9a`, 45° | lit smoke -> smoke in shadow |
| `green` | `#3ddc97` | the stormtrooper's smoke |
| `orange` / `yellow` | `#ff7a3d` / `#f0c05a` | the Mandalorian's sparks |
| `blue` | `#4d9bff` | a Jedi blade |
| `magenta` | `#9b5cff` | the violet blade, a purer step |

## Glass

| What | Where | Setting |
|---|---|---|
| Blur | `hyprland.lua` | size 9, 3 passes, brightness 0.75, vibrancy 0.25 |
| App windows | `hyprland.lua` | opacity 0.90 active / 0.82 inactive |
| Terminals | `foot.ini`, `ghostty.conf`, `alacritty.toml`, `kitty.conf` | background alpha 0.72 + blur requested, window 1.0 / 0.94 |
| Bar | `shell.bar.toml` | 0.45 |
| Menu / launcher | `shell.menu.toml`, `shell.launcher.toml` | card 0.68 / 0.62, scrim 0.1 (unblurred), selected row in the accent |
| Notifications / popups | `shell.notifications.toml`, `shell.popups.toml` | 0.72 / 0.78 |
| Polkit / tooltip / lock field | `shell.polkit.toml`, `shell.tooltip.toml`, `shell.lock.toml` | 0.85 / 0.9 / 0.55 |
| GTK apps (Files…) | `gtk.css` | rgba surfaces |

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
kylo-ren-star-wars-the-rise-of-skywalker-black
nostalgic-room
star-wars-ahsoka-orrery                         (DevSviat's ink, see below)
star-wars-the-7680x4320
stormtrooper-star-wars-neon
```

Omarchy has no default-background key: on a first apply it takes the first
file in sort order, hence the `00-` prefix.

## Unlock screen

Omarchy Menu -> Style -> Unlock (the Plymouth boot splash and SDDM greeter)
uses `unlock.png`: the Ahsoka orrery exactly as the DevSviat theme draws it,
so the boot splash matches the Ahsoka wallpaper in the rotation. Both files
are byte-for-byte the DevSviat ones; `tools/generate-orrery.sh` rebuilds them
from the untouched source image, plus a `preview-unlock.png` that shows the
logo over this theme's own background — the flat fill Plymouth draws here.

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
glass. The bar and menus keep Omarchy's own `no_anim` rules and still pop
instantly. Anything in `~/.config/hypr/looknfeel.lua` still wins.

## Generated from `colors.toml`

Neovim (aether), btop, Chromium, Helix, Obsidian, VS Code (a local "Omarchy"
theme), the keyboard backlight (steel blue) and the rest come from
Omarchy's own templates. Icons are `Yaru-blue-dark`.

## tools/

| File | What it does |
|---|---|
| `generate-orrery.sh` | builds `unlock.png`, `preview-unlock.png` and the orrery wallpaper |
| `preview.html` + `generate-preview.sh` | renders `preview.png` with headless Chromium |
