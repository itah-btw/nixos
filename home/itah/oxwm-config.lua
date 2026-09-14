---@meta
-------------------------------------------------------------------------------
-- OXWM Configuration File
-------------------------------------------------------------------------------
-- This is the default configuration for OXWM, a dynamic window manager.
-- Edit this file and reload with Mod+Shift+R (no compilation needed)
--
-- For more information about configuring OXWM, see the documentation.
-- The Lua Language Server provides autocomplete and type checking.
-------------------------------------------------------------------------------

---Load type definitions for LSP
---@module 'oxwm'

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------
-- Define your variables here for easy customization throughout the config.
-- This makes it simple to change keybindings, colors, and settings in one place.

-- Modifier key: "Mod4" is the Super/Windows key, "Mod1" is Alt
local modkey = "Mod4"

-- Terminal emulator command (Super+Enter opens this)
local terminal = "alacritty"

-- Color palette - Catppuccin Mocha (single fixed theme, mauve accent).
-- Key names kept stable so the bar blocks below just reference these.
local colors = {
    fg = "#cdd6f4", -- text
    red = "#f38ba8",
    bg = "#1e1e2e", -- base
    cyan = "#94e2d5", -- teal
    green = "#a6e3a1",
    lavender = "#45475a", -- surface1 (separators: subtle)
    light_blue = "#89b4fa", -- blue
    grey = "#45475a", -- surface1
    blue = "#89b4fa",
    purple = "#cba6f7", -- mauve
    yellow = "#f9e2af",
    orange = "#fab387", -- peach
    teal = "#94e2d5",
}

-- UI chrome colors: borders, dmenu (mocha mauve)
local UI = {
    border_focus = "#cba6f7", -- mauve
    border_unfocus = "#45475a", -- surface1
    dmenu = {
        "#1e1e2e", -- normal bg
        "#cdd6f4", -- normal fg
        "#cba6f7", -- selection bg (mauve)
        "#1e1e2e", -- selection fg
    },
}

-- Workspace tags - can be numbers, names, or icons (requires a Nerd Font)
local tags = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
-- local tags = { "", "󰊯", "", "", "󰙯", "󱇤", "", "󱘶", "󰧮" } -- Example of nerd font icon tags

-- Font for the status bar (use "fc-list" to see available fonts)
local bar_font = "JetBrainsMono Nerd Font Propo:style=Bold:size=10"

-- Define your blocks
-- Similar to widgets in qtile, or dwmblocks
-- (oxwm has no native cpu/temp/brightness/volume blocks, so those are
-- shell blocks; each testable by running its command in a terminal)
local blocks = {
    oxwm.bar.block.ram({
        format = "Ram: {used}/{total} GB",
        interval = 5,
        color = colors.light_blue,
        underline = true,
        click = { command = "alacritty -e btop", floating = true },
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
    }),
    oxwm.bar.block.shell({
        format = "CPU: {}%",
        command = "/home/itah/.config/oxwm/cpu.sh",
        interval = 2,
        color = colors.yellow,
        underline = true,
        click = { command = "alacritty -e btop", floating = true },
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
    }),
    oxwm.bar.block.shell({
        format = "Temp: {}",
        command = "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = \"x86_pkg_temp\" ] && awk '{printf \"%d°C\", $1/1000}' $z/temp; done",
        interval = 5,
        color = colors.red,
        underline = true,
        click = { command = "alacritty -e btop", floating = true },
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
    }),
    oxwm.bar.block.shell({
        format = "Bri: {}%",
        command = "echo $(( $(cat /sys/class/backlight/intel_backlight/brightness) * 100 / $(cat /sys/class/backlight/intel_backlight/max_brightness) ))",
        interval = 2,
        color = colors.purple,
        underline = true,
        click = "brightnessctl set 5%+",
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
    }),
    oxwm.bar.block.shell({
        format = "Vol: {}",
        command = "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{if ($3==\"[MUTED]\") print \"MUTED\"; else printf \"%d%%\", $2*100}'",
        interval = 2,
        color = colors.blue,
        underline = true,
        click = { command = "alacritty -e pulsemixer", floating = true },
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
    }),
    oxwm.bar.block.shell({
        format = "WiFi: {}",
        command = "nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | awk -F: '$1==\"yes\" {print $2\" \"$3\"%\"}'",
        interval = 10,
        color = colors.orange,
        underline = true,
        click = { command = "alacritty -e nmtui", floating = true },
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
    }),
    oxwm.bar.block.shell({
        format = "BT: {}",
        command = "name=$(bluetoothctl devices Connected 2>/dev/null | head -1 | cut -d\" \" -f3-); if [ -n \"$name\" ]; then echo \"$name\"; elif bluetoothctl show 2>/dev/null | grep -q \"Powered: yes\"; then echo on; else echo off; fi",
        interval = 10,
        color = colors.teal,
        underline = true,
        click = { command = "alacritty -e bluetui", floating = true },
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
    }),
    oxwm.bar.block.battery({
        format = "Bat: {}%",
        charging = "⚡ Bat: {}%",
        discharging = "- Bat: {}%",
        full = "✓ Bat: {}%",
        interval = 30,
        color = colors.green,
        underline = true,
        click = { command = "alacritty -e btop", floating = true },
        -- click: run a command when the block is clicked
        -- click = "alacritty -e btop",
        -- click = { command = "bluetui", floating = true },
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.lavender,
        underline = false,
    }),
    oxwm.bar.block.datetime({
        format = "{}",
        date_format = "%a, %b %d - %H:%M",
        interval = 1,
        color = colors.cyan,
        underline = true,
        click = { command = "alacritty -e calcurse", floating = true },
    }),
};

-------------------------------------------------------------------------------
-- Basic Settings
-------------------------------------------------------------------------------
oxwm.set_terminal(terminal)
oxwm.set_modkey(modkey) -- This is for Mod + mouse binds, such as drag/resize
oxwm.set_tags(tags)

-- Set default layout (tiling by default)
-- oxwm.set_layout("tiling")

-------------------------------------------------------------------------------
-- Layouts
-------------------------------------------------------------------------------
-- Set custom symbols for layouts (displayed in the status bar)
-- Available layouts: "tiling", "normie" (floating), "grid", "monocle", "tabbed", "dwindle"
oxwm.set_layout_symbol("tiling", "[T]")
oxwm.set_layout_symbol("normie", "[F]")
oxwm.set_layout_symbol("tabbed", "[=]")
-- oxwm.set_layout_symbol("dwindle", "[\\]")

-- Example: bind dwindle (fibonacci) layout
-- oxwm.key.bind({ modkey }, "R", oxwm.layout.set("dwindle"))

-- Set default layout of specific tag (tag_index, layout_name)
-- Unset value uses oxwm.set_layout value
-- oxwm.set_tag_layout(1, "grid")

-------------------------------------------------------------------------------
-- Appearance
-------------------------------------------------------------------------------
-- Border configuration

-- Width in pixels
oxwm.border.set_width(3)
-- Color of focused window border
oxwm.border.set_focused_color(UI.border_focus)
-- Color of unfocused window borders
oxwm.border.set_unfocused_color(UI.border_unfocus)

-- Where floating windows spawn: "top-left", "top-center", "top-right",
-- "center-left", "center", "center-right", "bottom-left", "bottom-center", "bottom-right"
oxwm.set_floating_position("center")

-- Smart Enable = No outer gaps when only 1 window on a tag.
oxwm.gaps.set_smart(true)
-- Inner gaps (horizontal, vertical) in pixels
oxwm.gaps.set_inner(5, 5)
-- Outer gaps (horizontal, vertical) in pixels
oxwm.gaps.set_outer(5, 5)

-------------------------------------------------------------------------------
-- Window Rules
-------------------------------------------------------------------------------
-- Rules allow you to automatically configure windows based on their properties
-- You can match windows by class, instance, title, or role
-- Available properties: floating, tag, fullscreen, etc.
--
-- Common use cases:
-- - Force floating for certain applications (dialogs, utilities)
-- - Send specific applications to specific workspaces
-- - Configure window behavior based on title or class

-- Examples (uncomment to use):
oxwm.rule.add({ instance = "gimp", floating = true })
-- oxwm.rule.add({ class = "Alacritty", tag = 9, focus = true })
-- oxwm.rule.add({ class = "firefox", title = "Library", floating = true })
-- oxwm.rule.add({ class = "firefox", tag = 2 })
-- oxwm.rule.add({ instance = "mpv", floating = true })

-- To find window properties, use xprop and click on the window
-- WM_CLASS(STRING) shows both instance and class (instance, class)

-------------------------------------------------------------------------------
-- Status Bar Configuration
-------------------------------------------------------------------------------
-- Font configuration
oxwm.bar.set_font(bar_font)

-- Position configuration (top/bottom, top is default)
-- oxwm.bar.set_position("bottom")

-- Set your blocks here (defined above)
oxwm.bar.set_blocks(blocks)

-- Bar color schemes (for workspace tag display)
-- Parameters: foreground, background, border

-- Unoccupied tags
oxwm.bar.set_scheme_normal(colors.fg, colors.bg, "#45475a")
-- Occupied tags (accent text on the bar background)
oxwm.bar.set_scheme_occupied(colors.fg, colors.bg, colors.fg)
-- Currently selected tag (bright mauve accent text so it stays readable on dark)
oxwm.bar.set_scheme_selected(colors.purple, colors.bg, colors.purple)
-- Urgent tags (windows requesting attention)
oxwm.bar.set_scheme_urgent(colors.red, colors.bg, colors.red)

-- Hide tags that have no windows and are not selected
-- oxwm.bar.set_hide_vacant_tags(true)

-------------------------------------------------------------------------------
-- Keybindings
-------------------------------------------------------------------------------
-- Spawn commands for keybinds. They all live in a GLOBAL table on purpose:
-- oxwm 0.12.0 (and master) stores the Lua string behind a keybound spawn
-- command *by reference* and frees its stack slot immediately, so Lua's GC
-- reclaims the memory before the keypress ever runs (only `autostart` and
-- bar-click commands are copied safely). Keeping each command string
-- referenced from a global table prevents the collection, making the binds
-- work. This can be removed once oxwm copies keybind strings (dupeLuaString).
CMD = {}
CMD.dmenu = "dmenu_run -l 10 -nb '" .. UI.dmenu[1] .. "' -nf '" .. UI.dmenu[2] .. "' -sb '" .. UI.dmenu[3] .. "' -sf '" .. UI.dmenu[4] .. "'"
CMD.screenshot = "mkdir -p ~/Pictures/Screenshots && F=~/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png && maim -s | tee \"$F\" | xclip -selection clipboard -t image/png && notify-send \"Screenshot\" \"saved to $F\""
-- Bare path (no `sh -c` wrapper of its own): use $HOME so it never depends
-- on tilde expansion, only on the shell spawnCommand already uses.
CMD.clipmenu = "$HOME/.config/oxwm/clipmenu-sync.sh"
CMD.kbhelp = "alacritty --class kbhelp -e sh -c 'glow -p ~/.config/oxwm/keybinds.md'"
CMD.ocr = "maim -s | tesseract stdin stdout -l eng+ind 2>/dev/null | xclip -selection clipboard"
CMD.opencode = "alacritty --class opencode -e opencode"
CMD.yazi = "alacritty --class yazi -e yazi"
CMD.btop = "alacritty --class btop -e btop"
CMD.pcmanfm = "pcmanfm"
CMD.browser = "brave-origin"
CMD.libreoffice = "libreoffice"
CMD.localsend = "localsend_app"
CMD.obs = "obs"
CMD.fetcher = "alacritty --class fetcher -o window.dimensions.columns=110 -o window.dimensions.lines=30 -e sh -c 'fastfetch; echo; read -p \"Press Enter to close\"'"
CMD.nmtui = "alacritty --class nmtui -e nmtui"
CMD.bluetui = "alacritty --class btui -e bluetui"
CMD.calcurse = "alacritty --class calcurse -e calcurse"

-- App launcher rules: float these single-purpose terminal windows (matched by
-- the alacritty instance name, set with `alacritty --class NAME` in the binds below).
oxwm.rule.add({ instance = "fetcher", floating = true })
oxwm.rule.add({ instance = "kbhelp", floating = true })
oxwm.rule.add({ instance = "nmtui", floating = true })
oxwm.rule.add({ instance = "btui", floating = true })
oxwm.rule.add({ instance = "calcurse", floating = true })

-- Keybindings are defined using oxwm.key.bind(modifiers, key, action)
-- Modifiers: {"Mod4"}, {"Mod1"}, {"Shift"}, {"Control"}, or combinations like {"Mod4", "Shift"}
-- Keys: Use uppercase for letters (e.g., "Return", "H", "J", "K", "L")
-- Actions: Functions that return actions (e.g., oxwm.spawn(), oxwm.client.kill())
--
-- A list of available keysyms can be found in the X11 keysym definitions.
-- Common keys: Return, Space, Tab, Escape, Backspace, Delete, Left, Right, Up, Down

-- Basic window management

oxwm.key.bind({ modkey }, "Return", oxwm.spawn_terminal())
-- Launch Dmenu
oxwm.key.bind({ modkey }, "D", oxwm.spawn(CMD.dmenu))
-- Screenshot to ~/Pictures/Screenshots/ (timestamped) + clipboard
oxwm.key.bind({ modkey }, "S", oxwm.spawn(CMD.screenshot))
-- Clipboard history picker (clipmenu over dmenu, pastes the selection)
oxwm.key.bind({ modkey }, "V", oxwm.spawn(CMD.clipmenu))
oxwm.key.bind({ modkey }, "Q", oxwm.client.kill())

-- Keybind overlay - Shows important keybindings on screen
-- Show keybind cheatsheet (the built-in overlay is a minimal hardcoded list;
-- this opens a floating glow render of the full Markdown list).
oxwm.key.bind({ modkey, "Shift" }, "Slash", oxwm.spawn(CMD.kbhelp))

-- Window state toggles
oxwm.key.bind({ modkey, "Shift" }, "F", oxwm.client.toggle_fullscreen())
oxwm.key.bind({ modkey, "Shift" }, "Space", oxwm.client.toggle_floating())

-- Layout management
oxwm.key.bind({ modkey }, "F", oxwm.layout.set("normie"))
oxwm.key.bind({ modkey }, "C", oxwm.layout.set("tiling"))
-- Cycle through layouts
oxwm.key.bind({ modkey }, "N", oxwm.layout.cycle())

-- Master area controls (tiling layout)

-- Decrease/Increase master area width
oxwm.key.bind({ modkey }, "H", oxwm.set_master_factor(-5))
oxwm.key.bind({ modkey }, "L", oxwm.set_master_factor(5))
-- Enable tiled resize mode: Mod+RMB drag adjusts mfact instead of floating
-- oxwm.tiled_resize_mode(true)
-- Increment/Decrement number of master windows
oxwm.key.bind({ modkey }, "I", oxwm.inc_num_master(1))
oxwm.key.bind({ modkey }, "P", oxwm.inc_num_master(-1))

-- Gaps toggle
oxwm.key.bind({ modkey }, "A", oxwm.toggle_gaps())
-- Bar toggle
oxwm.key.bind({ modkey }, "B", oxwm.toggle_bar())

-- Window manager controls
oxwm.key.bind({ modkey, "Shift" }, "Q", oxwm.quit())
oxwm.key.bind({ modkey, "Shift" }, "R", oxwm.restart())

-- Focus movement [1 for up in the stack, -1 for down]
oxwm.key.bind({ modkey }, "J", oxwm.client.focus_stack(1))
oxwm.key.bind({ modkey }, "K", oxwm.client.focus_stack(-1))

-- Window movement (swap position in stack)
oxwm.key.bind({ modkey, "Shift" }, "J", oxwm.client.move_stack(1))
oxwm.key.bind({ modkey, "Shift" }, "K", oxwm.client.move_stack(-1))

-- Multi-monitor support

-- Focus next/previous Monitors
oxwm.key.bind({ modkey }, "Comma", oxwm.monitor.focus(-1))
oxwm.key.bind({ modkey }, "Period", oxwm.monitor.focus(1))
-- Move window to next/previous Monitors
oxwm.key.bind({ modkey, "Shift" }, "Comma", oxwm.monitor.tag(-1))
oxwm.key.bind({ modkey, "Shift" }, "Period", oxwm.monitor.tag(1))

-- Workspace (tag) navigation
-- Switch to workspace N (tags are 0-indexed, so tag "1" is index 0)
oxwm.key.bind({ modkey }, "1", oxwm.tag.view(0))
oxwm.key.bind({ modkey }, "2", oxwm.tag.view(1))
oxwm.key.bind({ modkey }, "3", oxwm.tag.view(2))
oxwm.key.bind({ modkey }, "4", oxwm.tag.view(3))
oxwm.key.bind({ modkey }, "5", oxwm.tag.view(4))
oxwm.key.bind({ modkey }, "6", oxwm.tag.view(5))
oxwm.key.bind({ modkey }, "7", oxwm.tag.view(6))
oxwm.key.bind({ modkey }, "8", oxwm.tag.view(7))
oxwm.key.bind({ modkey }, "9", oxwm.tag.view(8))

-- Move focused window to workspace N
oxwm.key.bind({ modkey, "Shift" }, "1", oxwm.tag.move_to(0))
oxwm.key.bind({ modkey, "Shift" }, "2", oxwm.tag.move_to(1))
oxwm.key.bind({ modkey, "Shift" }, "3", oxwm.tag.move_to(2))
oxwm.key.bind({ modkey, "Shift" }, "4", oxwm.tag.move_to(3))
oxwm.key.bind({ modkey, "Shift" }, "5", oxwm.tag.move_to(4))
oxwm.key.bind({ modkey, "Shift" }, "6", oxwm.tag.move_to(5))
oxwm.key.bind({ modkey, "Shift" }, "7", oxwm.tag.move_to(6))
oxwm.key.bind({ modkey, "Shift" }, "8", oxwm.tag.move_to(7))
oxwm.key.bind({ modkey, "Shift" }, "9", oxwm.tag.move_to(8))

-- Combo view (view multiple tags at once) {argos_nothing}
-- Example: Mod+Ctrl+2 while on tag 1 will show BOTH tags 1 and 2
oxwm.key.bind({ modkey, "Control" }, "1", oxwm.tag.toggleview(0))
oxwm.key.bind({ modkey, "Control" }, "2", oxwm.tag.toggleview(1))
oxwm.key.bind({ modkey, "Control" }, "3", oxwm.tag.toggleview(2))
oxwm.key.bind({ modkey, "Control" }, "4", oxwm.tag.toggleview(3))
oxwm.key.bind({ modkey, "Control" }, "5", oxwm.tag.toggleview(4))
oxwm.key.bind({ modkey, "Control" }, "6", oxwm.tag.toggleview(5))
oxwm.key.bind({ modkey, "Control" }, "7", oxwm.tag.toggleview(6))
oxwm.key.bind({ modkey, "Control" }, "8", oxwm.tag.toggleview(7))
oxwm.key.bind({ modkey, "Control" }, "9", oxwm.tag.toggleview(8))

-- Multi tag (window on multiple tags)
-- Example: Mod+Ctrl+Shift+2 puts focused window on BOTH current tag and tag 2
oxwm.key.bind({ modkey, "Control", "Shift" }, "1", oxwm.tag.toggletag(0))
oxwm.key.bind({ modkey, "Control", "Shift" }, "2", oxwm.tag.toggletag(1))
oxwm.key.bind({ modkey, "Control", "Shift" }, "3", oxwm.tag.toggletag(2))
oxwm.key.bind({ modkey, "Control", "Shift" }, "4", oxwm.tag.toggletag(3))
oxwm.key.bind({ modkey, "Control", "Shift" }, "5", oxwm.tag.toggletag(4))
oxwm.key.bind({ modkey, "Control", "Shift" }, "6", oxwm.tag.toggletag(5))
oxwm.key.bind({ modkey, "Control", "Shift" }, "7", oxwm.tag.toggletag(6))
oxwm.key.bind({ modkey, "Control", "Shift" }, "8", oxwm.tag.toggletag(7))
oxwm.key.bind({ modkey, "Control", "Shift" }, "9", oxwm.tag.toggletag(8))

-------------------------------------------------------------------------------
-- Advanced: Keychords
-------------------------------------------------------------------------------
-- Keychords allow you to bind multiple-key sequences (like Emacs or Vim)
-- Format: {{modifiers}, key1}, {{modifiers}, key2}, ...
-- Example: Press Mod4+Space, then release and press T to spawn a terminal
oxwm.key.chord({
    { { modkey }, "Space" },
    { {},         "T" }
}, oxwm.spawn_terminal())

-------------------------------------------------------------------------------
-- Media keys (brightness / volume, no modifier)
-------------------------------------------------------------------------------
-- Brightness via brightnessctl (user must be in the `video` group).
-- NOTE: oxwm only understands the {"sh", "-c", "<cmd>"} table form (or a
-- plain string); a multi-arg table runs just its first element.
CMD.brightness_up = "brightnessctl set 5%+ && b=$(brightnessctl i | sed -n 's/.*(\\([0-9]*\\)%).*/\\1/p') && notify-send -t 1500 -h int:value:$b -h string:synchronous:brightness \"Brightness\" \"$b%\""
CMD.brightness_down = "brightnessctl set 5%- && b=$(brightnessctl i | sed -n 's/.*(\\([0-9]*\\)%).*/\\1/p') && notify-send -t 1500 -h int:value:$b -h string:synchronous:brightness \"Brightness\" \"$b%\""

-- Volume via PipeWire / WirePlumber.
CMD.volume_up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}') && notify-send -t 1500 -h int:value:$v -h string:synchronous:volume \"Volume\" \"$v%\""
CMD.volume_down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}') && notify-send -t 1500 -h int:value:$v -h string:synchronous:volume \"Volume\" \"$v%\""
CMD.volume_mute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && if wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q '\\[MUTED\\]'; then notify-send -t 1500 -h string:synchronous:volume \"Volume\" \"muted\"; else v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}'); notify-send -t 1500 -h int:value:$v -h string:synchronous:volume \"Volume\" \"$v%\"; fi"

oxwm.key.bind({}, "XF86MonBrightnessUp", oxwm.spawn(CMD.brightness_up))
oxwm.key.bind({}, "XF86MonBrightnessDown", oxwm.spawn(CMD.brightness_down))
oxwm.key.bind({}, "XF86AudioRaiseVolume", oxwm.spawn(CMD.volume_up))
oxwm.key.bind({}, "XF86AudioLowerVolume", oxwm.spawn(CMD.volume_down))
oxwm.key.bind({}, "XF86AudioMute", oxwm.spawn(CMD.volume_mute))

-- OCR: select a screen region, recognize text (English + Indonesian),
-- and copy it to the clipboard.
oxwm.key.bind({ modkey }, "O", oxwm.spawn(CMD.ocr))

-- App launchers (default binds untouched; new combos only)
oxwm.key.bind({ modkey, "Shift" }, "O", oxwm.spawn(CMD.opencode))            -- TUI chat/GitHub Copilot
oxwm.key.bind({ modkey, "Shift" }, "Y", oxwm.spawn(CMD.yazi))                -- file manager (TUI)
oxwm.key.bind({ modkey, "Shift" }, "B", oxwm.spawn(CMD.btop))                -- system monitor (TUI)
oxwm.key.bind({ modkey }, "T", oxwm.spawn(CMD.pcmanfm))                      -- file manager (GUI)
oxwm.key.bind({ modkey }, "W", oxwm.spawn(CMD.browser))                      -- browser
oxwm.key.bind({ modkey, "Shift" }, "L", oxwm.spawn(CMD.libreoffice))         -- office suite
oxwm.key.bind({ modkey, "Shift" }, "M", oxwm.spawn(CMD.localsend))           -- file sharing (GUI)
oxwm.key.bind({ modkey, "Shift" }, "P", oxwm.spawn(CMD.obs))                 -- screen recording (GUI)
-- Floating TUIs (matched by instance rule above)
oxwm.key.bind({ modkey }, "E", oxwm.spawn(CMD.fetcher))                      -- system info (float)
oxwm.key.bind({ modkey, "Shift" }, "N", oxwm.spawn(CMD.nmtui))               -- network (float)
oxwm.key.bind({ modkey, "Shift" }, "T", oxwm.spawn(CMD.bluetui))             -- bluetooth (float)
oxwm.key.bind({ modkey, "Shift" }, "C", oxwm.spawn(CMD.calcurse))            -- calendar (float)

-------------------------------------------------------------------------------
-- Autostart
-------------------------------------------------------------------------------
-- Commands to run once when OXWM starts
-- Uncomment and modify these examples, or add your own

-- Clipboard history daemon (guarded so a config reload won't stack copies;
-- CM_DIR comes from the session profile; history persists across reboots)
oxwm.autostart("pidof clipmenud >/dev/null || clipmenud")
-- Wallpaper (fill: cover the screen, cropping as needed).
oxwm.autostart("feh --bg-fill ~/.config/oxwm/wallpaper.jpg")
-- Cursor theme for Qt/Java/WebKit apps (GTK reads its own settings.ini)
oxwm.autostart("xrdb -merge ~/.config/Xresources")
-- Themed root cursor (oxwm itself draws plain core-X glyphs; this keeps the
-- desktop cursor on theme)
oxwm.autostart("xsetroot -cursor_name left_ptr")

-- Notification daemon (static Catppuccin Mocha dunstrc from home-manager)
oxwm.autostart("pgrep dunst >/dev/null || dunst")
-- oxwm.autostart("nm-applet")
