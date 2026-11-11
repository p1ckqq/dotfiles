-- Плагины Hyprland (собираются через hyprpm): hyprbars + Hyprspace
-- Подключается из hyprland.lua. Если плагин не загружен — его блок просто пропускается.

local HOME = os.getenv("HOME")
local ok, C = pcall(dofile, HOME .. "/.config/hypr/colors.lua")
if not ok or type(C) ~= "table" then
    C = { primary = "9fcafc", on_surface = "e1e2e8", surface = "101418",
          surface_container = "1d2024", outline = "8c9199", error = "ffb4ab", tertiary = "d5bee5" }
end
local function rgba(hex, a) return "rgba(" .. hex .. (a or "ff") .. ")" end

local plugin = hl.plugin or {}

------------------------------------------------------------
-- hyprbars: заголовки окон с кнопками «–» и «×»
------------------------------------------------------------
-- заголовки выключены по желанию; вернуть: HYPRBARS = true
local HYPRBARS = false

if plugin.hyprbars and not HYPRBARS then
    hl.config({ plugin = { hyprbars = { enabled = false } } })
end

if plugin.hyprbars and HYPRBARS then
    hl.config({
        plugin = {
            hyprbars = {
                bar_height                 = 24,
                bar_color                  = rgba(C.surface_container, "e6"),
                ["col.text"]               = rgba(C.on_surface),
                bar_text_size              = 10,
                bar_text_weight            = "bold",
                bar_text_font              = "JetBrainsMono Nerd Font",
                bar_text_align             = "left",
                bar_title_enabled          = true,
                bar_blur                   = true,
                bar_part_of_window         = true,
                bar_precedence_over_border = true,
                bar_buttons_alignment      = "right",
                bar_padding                = 10,
                bar_button_padding         = 7,
                icon_on_hover              = true,
            },
        },
    })

    -- кнопки добавляются справа налево: первая — самая правая
    plugin.hyprbars.add_button({
        bg_color = rgba(C.error, "ff"), fg_color = rgba(C.surface), size = 13,
        icon = "\u{F0156}", action = "hyprctl dispatch 'hl.dsp.window.close()'",
    })
    plugin.hyprbars.add_button({
        bg_color = rgba(C.primary, "ff"), fg_color = rgba(C.surface), size = 13,
        icon = "\u{F0374}", action = HOME .. "/.local/bin/rice-min",
    })

    -- без заголовков: виджеты рабочего стола и плавающие служебные окна
    hl.window_rule({ name = "nobar-widgets", match = { class = "^(widget)$" }, ["hyprbars:no_bar"] = true })
end

------------------------------------------------------------
-- Hyprspace: обзор рабочих столов (Super+Tab)
------------------------------------------------------------
if plugin.overview then
    hl.config({
        plugin = {
            overview = {
                panelColor                  = rgba(C.surface, "d9"),
                panelBorderColor            = rgba(C.primary, "66"),
                panelBorderWidth            = 1,
                workspaceActiveBackground   = rgba(C.primary, "22"),
                workspaceInactiveBackground = rgba(C.surface_container, "aa"),
                workspaceActiveBorder       = rgba(C.primary),
                workspaceInactiveBorder     = rgba(C.outline, "55"),
                workspaceBorderSize         = 2,
                workspaceMargin             = 14,
                panelHeight                 = 240,
                centerAligned               = true,
                onBottom                    = false,
                autoDrag                    = true,
                dragAlpha                   = 0.6,
                hideTopLayers               = false,
                drawActiveWorkspace         = true,
                affectStrut                 = true,
                overrideGaps                = true,
                gapsIn                      = 8,
                gapsOut                     = 24,
            },
        },
    })

    hl.bind("SUPER + TAB", function() plugin.overview.toggle() end)
end
