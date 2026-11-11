-- Rice: monochrome glass + matugen colors from wallpaper
-- Предыдущий конфиг: hyprland.lua.bak-20261108

local HOME = os.getenv("HOME")

-- Цвета, сгенерированные matugen из текущих обоев (скрипт `wall`)
local ok, C = pcall(dofile, HOME .. "/.config/hypr/colors.lua")
if not ok or type(C) ~= "table" then
    C = { primary = "c8c8d0", outline = "5c5c66", outline_variant = "3a3a40", surface = "121214" }
end

------------------
---- MONITORS ----
------------------
hl.monitor({ output = "desc:Xiaomi Corporation Mi 30 HFCW", mode = "2560x1080@200", position = "0x0", scale = 1 })
hl.monitor({ output = "",     mode = "preferred",     position = "auto", scale = "auto" })

---------------------
---- MY PROGRAMS ----
---------------------
local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "pkill -x wofi || wofi --show drun"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 0.6 && " .. HOME .. "/.local/bin/wall --restore")
    hl.exec_cmd(HOME .. "/.local/bin/rice-bar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("command -v kdeconnectd >/dev/null && kdeconnectd || /usr/lib/kdeconnectd")
    hl.exec_cmd("easyeffects --gapplication-service")
    hl.exec_cmd("sleep 4 && easyeffects -l 'Мне нравится · бас'")
    hl.exec_cmd(HOME .. "/.local/bin/rice-min --daemon")
    hl.exec_cmd("sleep 1.5 && " .. HOME .. "/.local/bin/rice-widgets")
    hl.exec_cmd("wl-paste --watch cliphist store")
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 22")
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd("sleep 2 && " .. HOME .. "/.local/bin/tg-ws-proxy")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "22")
hl.env("HYPRCURSOR_SIZE", "22")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 6,
        border_size = 1,
        col = {
            active_border   = "rgba(" .. C.primary .. "ee)",
            inactive_border = "rgba(" .. C.outline .. "88)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 3,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = { enabled = false },
        blur = {
            enabled  = true,
            size     = 6,
            passes   = 3,
            noise    = 0.02,
            contrast = 1.0,
            brightness = 0.9,
            vibrancy = 0.17,
            new_optimizations = true,
            ignore_opacity = true,
            popups = true,
        },
    },

    animations = { enabled = true },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, damping = 24.21279333 })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy", style = "popin 90%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear", style = "popin 90%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear", style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.5,  bezier = "easeOutQuint", style = "slide" })

hl.config({ dwindle = { preserve_split = true } })
hl.config({ master  = { new_status = "master" } })

hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        enable_anr_dialog = false,   -- lo-fi замораживает программы; без этого выскакивает «не отвечает»
    },
})

hl.config({ layers = { allow_new_top_layers_over_existing_fullscreen = true } })

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout  = "us,ru",
        kb_options = "grp:alt_shift_toggle",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

---------------------
---- KEYBINDINGS ----
---------------------
local mainMod = "SUPER"

hl.bind(mainMod .. " + Q",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C",      hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + SPACE",  hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J",      hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + B",      hl.dsp.exec_cmd("firefox"))

-- Обои + тема
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd(HOME .. "/.local/bin/wall"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd(HOME .. "/.local/bin/wall --random"))
-- Виджеты рабочего стола (cava, cmatrix, часы)
hl.bind(mainMod .. " + D",         hl.dsp.exec_cmd(HOME .. "/.local/bin/rice-widgets"))
-- Перезапуск бара
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill -x waybar"))

-- Скриншоты
hl.bind("PRINT",            hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("grim - | wl-copy"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | wl-copy"))

-- Фокус
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Перестановка окон
hl.bind(mainMod .. " + ALT + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + ALT + up",    hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + ALT + down",  hl.dsp.window.swap({ direction = "d" }))

-- Размер окон с клавиатуры
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 60,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -60, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,   y = 60,  relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,   y = -60, relative = true }), { repeating = true })

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Свернуть окно / показать свёрнутые
hl.bind(mainMod .. " + H",         hl.dsp.exec_cmd(HOME .. "/.local/bin/rice-min"))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.workspace.toggle_special("minimized"))

hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + CTRL + S",  hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

--------------------------------
---- WINDOWS AND LAYERS     ----
--------------------------------
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "float-pavucontrol",
    match = { class = "^(org.pulseaudio.pavucontrol)$" },
    float = true,
    size  = "900 600",
    center = true,
})

-- Виджеты рабочего стола — без блюра, чтобы обои за ними были видны чётко
hl.window_rule({ name = "no-blur-widgets", match = { class = "^(widget|lofi-widget)$" }, no_blur = true })

-- Стекло под баром и лаунчером
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ match = { namespace = "wofi" },   blur = true, ignore_alpha = 0.1 })

-- плагины (hyprbars, Hyprspace) — см. plugins.lua
local okp, errp = pcall(dofile, HOME .. "/.config/hypr/plugins.lua")
if not okp then print("plugins.lua: " .. tostring(errp)) end
