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

-- The border is a glass rim, after the Velora Liquid Glass theme, lit in this
-- theme's own colour: pale steel (#cfe0f7, 40%) catching the top edge and
-- settling into the steel-blue accent (#7fa6d8, 18%) at the bottom, top to
-- bottom at 90 degrees. On translucent, blurred windows that reads as the edge
-- of a pane of glass in the smoke's light rather than as a coloured frame.
-- colors.toml hyprland_active_border.
local active_border_color = { colors = { "rgba(cfe0f766)", "rgba(7fa6d82e)" }, angle = 90 }
-- colors.toml hyprland_inactive_border: the smoke's mid tone (#26354f) at 50%,
-- a soft navy edge in the same glass as the bar and the windows.
local inactive_border_color = "rgba(26354f80)"

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
    -- Above 2 the corner becomes a superellipse instead of a circular arc —
    -- the softer, continuous curve of a real glass pane (Velora uses 3). The
    -- shell reads decoration:rounding for its own corner radius, so bar
    -- panels, menus and notifications follow.
    rounding_power = 3,

    -- A soft drop, lit from above like the rim: offset 5 px down so each pane
    -- floats over the wallpaper instead of sitting in a dark halo.
    shadow = {
      enabled = true,
      range = 25,
      render_power = 3,
      offset = { 0, 5 },
      color = "rgba(05060999)",
      color_inactive = "rgba(05060966)",
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
      -- Only pixels denser than 0.5 are frosted: the menu body (0.88 in
      -- gtk.css) is, its drop shadow (kept at or below 0.35) is not. At 0.2
      -- the shadow itself was blurred and darkened into a band around menus.
      popups = true,
      popups_ignorealpha = 0.5,
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
hl.animation({ leaf = "workspaces", enabled = true, speed = 2.5, bezier = "hyperspace", style = "slidefade 20%" })
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
-- The bar is a strip of glass at 0.7, so it takes a low threshold that only
-- skips its fully transparent edges.
-- blur_popups also frosts the xdg popups the bar opens (tray menus, media,
-- tooltips), as Velora does.
hl.layer_rule({ match = { namespace = "^omarchy-bar$" }, blur = true, blur_popups = true, ignore_alpha = 0.15 })

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
  blur_popups = true,
  ignore_alpha = 0.55,
})

-- Two themes live in this one directory: `star-wars` and `star-wars-glass` are
-- both symlinks to it, so every file is shared and they can never drift. The
-- only difference is hyprglass, switched on the active theme's name, which
-- omarchy-theme-set writes before its final `hyprctl reload`.
local function current_theme_name()
  local file = io.open((os.getenv("HOME") or "") .. "/.local/state/omarchy/current/theme.name", "r")
  if not file then
    return ""
  end
  local name = file:read("*l") or ""
  file:close()
  return name
end

local glass_theme = current_theme_name() == "star-wars-glass"

-- Real liquid glass, Star Wars Glass only. The hyprglass compositor plugin
-- (https://github.com/hyprnux/hyprglass) adds what Hyprland's own blur cannot:
-- edge refraction, chromatic aberration and a specular sheen. It is not part
-- of the theme and nothing here loads it; this block only configures it when
-- it is already loaded. In plain Star Wars a loaded plugin is switched off, so
-- that theme really is Hyprland's blur alone.
if hl.plugin and hl.plugin.hyprglass then
  local hg = hl.plugin.hyprglass

  if not glass_theme then
    hg.config({ enabled = false, layers = { enabled = false } })
  else

    -- A softer glass than the built-in "glass" preset, whose refraction (8.0),
    -- chromatic aberration (0.5) and lens distortion (0.3) bend the wallpaper
    -- hard at every corner and fringe it in colour. "saber" keeps the look —
    -- a lensed edge and a specular sheen — at a fraction of the bend, with a
    -- thinner bezel, so corners read as rounded glass rather than a fisheye.
    hg.preset("saber", {
      inherits = "glass",
      refraction_strength = 3.0,
      chromatic_aberration = 0.15,
      lens_distortion = 0.12,
      edge_thickness = 0.035,
      fresnel_strength = 0.3,
      specular_strength = 0.5,
    })

    hg.config({
      enabled = true,
      default_theme = "dark",
      default_preset = "saber",
      -- live_resample re-renders a layer's glass whenever anything behind it
      -- changes, and the bar sits over a clock that ticks every second, so it
      -- kept the compositor busy at idle. The bar is over the wallpaper and
      -- menus and panels are short-lived, so a static backdrop is invisible.
      layers = { enabled = true, live_resample = false },
    })

    -- No need to turn Hyprland's blur.new_optimizations off (Velora does): per
    -- the hyprglass README, manage_window_blur and layers.manage_blur (both on
    -- by default) set noblur on every glassed window and layer, so the cached
    -- blur never hides the glass, and everything else keeps the cheaper cache.
    -- On glassed layers the layer rule's ignore_alpha no longer applies —
    -- mask_threshold below does that job.

    hg.layer("omarchy-bar", { preset = "saber" })
    -- Full-screen scrim + card layers take the same 0.55 alpha gate as the blur
    -- rule above, so only the card refracts and the scrim stays a plain wash.
    hg.layer("omarchy-menu", { preset = "saber", mask_threshold = 0.55 })
    hg.layer("omarchy-keyboard-panel", { preset = "saber", mask_threshold = 0.55 })
  end
end
