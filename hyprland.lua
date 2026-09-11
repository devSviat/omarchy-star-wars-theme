-- Star Wars — Hyprland side of the theme.
--
-- Hand-written instead of generated from default/themed/hyprland.lua.tpl:
-- the template only emits border colours, and this theme's whole point is the
-- glass — blur, window translucency, blurred shell surfaces. A template never
-- overwrites a file the theme ships, so the border values below are no longer
-- generated and must be kept in step with `hyprland_active_border` /
-- `hyprland_inactive_border` in colors.toml.
--
-- Load order (default/hypr/omarchy.lua, then ~/.config/hypr/hyprland.lua):
--
--   default.hypr.looknfeel         blur and shadow off, rounding 0
--   default.hypr.windows           default-opacity tag -> "0.985 0.96"
--   omarchy.current.theme.hyprland  <- this file
--   hypr.looknfeel                 the user's own overrides, loaded last
--
-- The window rules here are declared after Omarchy's, so for the same
-- property they win. Anything set in ~/.config/hypr/looknfeel.lua still wins
-- over this file.

-- `hl` and `o` are injected as globals by Hyprland's Lua runtime and Omarchy's
-- helpers, so a language server has nothing to resolve them against.
---@diagnostic disable-next-line: undefined-global
local hl = hl
---@diagnostic disable-next-line: undefined-global
local o = o

-- Lit smoke -> smoke in shadow. colors.toml hyprland_active_border. colors.toml hyprland_active_border.
local active_border_color = { colors = { "rgba(8fb4e3ee)", "rgba(4f6a9aee)" }, angle = 45 }
-- colors.toml hyprland_inactive_border
local inactive_border_color = "rgba(2a2b3caa)"

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,

    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },
  },

  decoration = {
    rounding = 10,

    -- A soft drop so translucent panes still separate from the wallpaper.
    shadow = {
      enabled = true,
      range = 22,
      render_power = 3,
      color = "rgba(050609cc)",
    },

    -- Frosted glass. Three passes at size 9 is a wide, smooth blur without
    -- banding; brightness pulls the wallpaper down so text on top stays
    -- legible even over the bright nostalgic-room wallpaper, and vibrancy
    -- keeps the blade colours alive through it instead of greying out.
    blur = {
      enabled = true,
      size = 9,
      passes = 3,
      noise = 0.015,
      contrast = 1.0,
      brightness = 0.75,
      vibrancy = 0.25,
      vibrancy_darkness = 0.3,
      new_optimizations = true,
      xray = false,
      ignore_opacity = true,
      special = true,
      -- Menus and tooltips of translucent apps (GTK popovers, context menus).
      popups = true,
      popups_ignorealpha = 0.2,
    },
  },
})

-- Animations. Omarchy's defaults (default.hypr.looknfeel) are brisk and turn
-- workspace switching off; this set gives the glass some motion. Speeds are
-- in tenths of a second. The bar and menus keep Omarchy's own no_anim layer
-- rules, so they still pop instantly.
--
--   ignite      fast with a slight overshoot — a blade snapping out
--   retract     eases in, then gone
--   glide       long ease-out, for anything that moves or changes colour
--   hyperspace  slow start, hard jump, soft landing — workspace switches
hl.curve("ignite", { type = "bezier", points = { { 0.16, 1 }, { 0.3, 1.08 } } })
hl.curve("retract", { type = "bezier", points = { { 0.6, 0.04 }, { 0.98, 0.34 } } })
hl.curve("glide", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("hyperspace", { type = "bezier", points = { { 0.76, 0 }, { 0.24, 1 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.5, bezier = "ignite", style = "popin 70%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2.5, bezier = "retract", style = "popin 70%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "glide", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 6, bezier = "glide" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "glide" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2.5, bezier = "retract" })
-- Focus moving across translucent windows fades their opacity rather than
-- snapping between 0.9 and 0.82.
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "glide" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "glide" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5.5, bezier = "hyperspace", style = "slidefade 20%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 4, bezier = "ignite", style = "slidefadevert 30%" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "glide", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "retract", style = "fade" })

-- Window translucency, active then inactive. Omarchy's default is
-- "0.985 0.96"; browsers, video players, games, PiP and screen-share targets
-- drop the default-opacity tag in default/hypr/apps/, so they stay opaque.
o.window({ tag = "default-opacity" }, { opacity = "0.9 0.82" })

-- Terminals carry their own background alpha (foot.ini, ghostty.conf,
-- alacritty.toml, kitty.conf), which keeps glyphs fully opaque over a
-- translucent cell background. Whole-window opacity on top would also fade
-- the text, so they are only dimmed slightly when unfocused. Declared after
-- the default-opacity rule above so it wins for terminal windows.
o.window({ tag = "terminal" }, { opacity = "1.0 0.94" })

-- Blur behind the Omarchy shell's own layer surfaces. Their alpha comes from
-- the shell.*.toml sections; ignore_alpha skips blurring any pixel at or
-- below that alpha.
--
-- The bar is a strip of glass at 0.45, so it takes a low threshold that only
-- skips its fully transparent edges.
hl.layer_rule({ match = { namespace = "^omarchy-bar$" }, blur = true, ignore_alpha = 0.15 })

-- Everything else is a full-screen layer: a scrim (0.1 in shell.menu.toml /
-- shell.launcher.toml, 0.45 for polkit, 0.5 for the image picker) with a card
-- on top (0.62 - 0.85). A threshold of 0.55 sits between the two, so only the
-- card is frosted and the desktop around it stays sharp and visible, rather
-- than the whole screen going to a dark blur whenever a menu opens.
hl.layer_rule({
  match = {
    namespace = "^(omarchy-menu|omarchy-notifications|omarchy-osd|omarchy-polkit|omarchy-clipboard|omarchy-emojis|omarchy-keyboard-panel|omarchy-reminders|omarchy-network-qr|omarchy-image-selector)$",
  },
  blur = true,
  ignore_alpha = 0.55,
})
