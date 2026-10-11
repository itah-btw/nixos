{
  flake.homeManagerModules.oxwm =
    {
      inputs,
      pkgs,
      lib,
      constants,
      ...
    }:
    let
      repo = inputs."oxwm-config";
      wallpapers = inputs."oxwm-wallpapers";

      # Single source of truth for theme colors. The Lua palettes and the
      # rofi configs below are both generated from this; add a theme here
      # and extend theme_names in the loader to wire a new one through.
      palettes = {
        tokyonight = {
          fg = "#bbbbbb";
          red = "#f7768e";
          bg = "#1a1b26";
          cyan = "#0db9d7";
          green = "#9ece6a";
          lavender = "#a9b1d6";
          light_blue = "#7aa2f7";
          grey = "#bbbbbb";
          blue = "#6dade3";
          purple = "#ad8ee6";
          yellow = "#e0af68";
          orange = "#ff9e64";
          sep = "#444b6a";
        };
        gruvbox = {
          fg = "#ebdbb2";
          red = "#fb4934";
          bg = "#282828";
          cyan = "#8ec07c";
          green = "#b8bb26";
          lavender = "#d3869b";
          light_blue = "#83a598";
          grey = "#928374";
          blue = "#83a598";
          purple = "#d3869b";
          yellow = "#fabd2f";
          orange = "#fe8019";
          sep = "#504945";
        };
        catppuccin = {
          fg = "#cdd6f4";
          red = "#f38ba8";
          bg = "#1e1e2e";
          cyan = "#94e2d5";
          green = "#a6e3a1";
          lavender = "#bac2de";
          light_blue = "#89b4fa";
          grey = "#6c7086";
          blue = "#89b4fa";
          purple = "#cba6f7";
          yellow = "#f9e2af";
          orange = "#fab387";
          sep = "#313244";
        };
      };

      luaPalette =
        p:
        "return {\n"
        + lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "    ${k} = \"${v}\";") p)
        + "\n}\n";

      # The bar, generated so every block carries its own color, the clock
      # sits last (rightmost), and wifi/bluetooth open floating TUIs on click.
      blocksLua = ''
        local blocks = {
            oxwm.bar.block.ram({
                format = "Ram: {used}/{total} GB",
                interval = 5,
                color = colors.purple,
                underline = true,
                click = { command = "st -e btop", floating = true },
            }),
            oxwm.bar.block.static({
                text = "│",
                interval = 999999999,
                color = colors.sep,
                underline = false,
            }),
            oxwm.bar.block.shell({
                format = "{}",
                command = "$HOME/.config/oxwm/cpu-status.sh",
                interval = 5,
                color = colors.orange,
                underline = true,
                click = { command = "st -e btop", floating = true },
            }),
            oxwm.bar.block.static({
                text = "│",
                interval = 999999999,
                color = colors.sep,
                underline = false,
            }),
            oxwm.bar.block.shell({
                format = "{}",
                command = "$HOME/.config/oxwm/temp-status.sh",
                interval = 30,
                color = colors.red,
                underline = true,
                click = { command = "st -e btop", floating = true },
            }),
            oxwm.bar.block.static({
                text = "│",
                interval = 999999999,
                color = colors.sep,
                underline = false,
            }),
            oxwm.bar.block.shell({
                format = "{}",
                command = "$HOME/.config/oxwm/wifi-status.sh",
                interval = 10,
                color = colors.yellow,
                underline = true,
                click = { command = "st -e nmtui", floating = true },
            }),
            oxwm.bar.block.static({
                text = "│",
                interval = 999999999,
                color = colors.sep,
                underline = false,
            }),
            oxwm.bar.block.shell({
                format = "{}",
                command = "$HOME/.config/oxwm/bluetooth-status.sh",
                interval = 10,
                color = colors.light_blue,
                underline = true,
                click = { command = "st -e bluetui", floating = true },
            }),
            oxwm.bar.block.static({
                text = "│",
                interval = 999999999,
                color = colors.sep,
                underline = false,
            }),
            oxwm.bar.block.battery({
                format = "Bat: {}%",
                charging = "Chg: {}%",
                discharging = "Bat: {}%",
                full = "Full",
                interval = 30,
                color = colors.green,
                underline = true,
                click = { command = [[sh -c 'prof=$(printf power-saver\\nbalanced\\nperformance\\n | dmenu-themed -l 3) && [ -n "$prof" ] && powerprofilesctl set $prof && notify-send -h string:x-dunst-stack-tag:osd Power $prof']], floating = true },
            }),
            oxwm.bar.block.static({
                text = "│",
                interval = 999999999,
                color = colors.sep,
                underline = false,
            }),
            oxwm.bar.block.datetime({
                format = "{}",
                date_format = "%a, %b %d - %H:%M",
                interval = 30,
                color = colors.cyan,
                underline = true,
                click = { command = "st -e ikhal", floating = true },
            }),
        };
      '';

      themeLoader = ''
        local theme_names = { tokyonight = true, gruvbox = true, catppuccin = true }
        local theme = "tokyonight"
        local theme_file = io.open(os.getenv("HOME") .. "/.config/oxwm/theme", "r")
        if theme_file then
          local wanted = (theme_file:read("*l") or ""):match("^%s*(.-)%s*$")
          theme_file:close()
          if theme_names[wanted] then theme = wanted end
        end
        local colors = require("colors." .. theme);'';

      wallpaperBlock = ''
        local hp_wallpapers = {
          tokyonight = os.getenv("HOME") .. "/.config/oxwm/wallpapers/tokyonight.jpg",
          gruvbox = os.getenv("HOME") .. "/.config/oxwm/wallpapers/gruvbox.png",
          catppuccin = os.getenv("HOME") .. "/.config/oxwm/wallpapers/catppuccin.jpg",
        }
        oxwm.autostart("feh --bg-fill " .. hp_wallpapers[theme])'';

      firefoxBind = ''oxwm.key.bind({ modkey }, "B", oxwm.spawn({ "sh", "-c", "firefox" }))'';

      screenshotCmd = "mkdir -p ~/Pictures/Screenshots && f=~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png && maim -s $f && xclip -selection clipboard -t image/png < $f && notify-send \"Screenshot saved\" \"$f\"";

      # Line surgery on the vendored config: every anchor below must match
      # exactly one line, asserted so upstream edits fail loudly instead of
      # shipping stale config. The whole bar table is swapped at once, which
      # also drops the kernel-version block living inside it.
      repoLines = lib.splitString "\n" (builtins.readFile "${repo}/config.lua");
      blocksStart = lib.lists.findFirstIndex (l: l == "local blocks = {") null repoLines;
      blocksEnd =
        let
          after = lib.sublist blocksStart (builtins.length repoLines - blocksStart) repoLines;
          relEnd = lib.lists.findFirstIndex (l: l == "};") null after;
        in
        assert blocksStart != null && relEnd != null;
        blocksStart + relEnd;
      swappedBar =
        lib.sublist 0 blocksStart repoLines
        ++ lib.splitString "\n" blocksLua
        ++ lib.sublist (blocksEnd + 1) (builtins.length repoLines - blocksEnd - 1) repoLines;

      repl =
        old: new: lines:
        assert builtins.length (builtins.filter (l: l == old) lines) == 1;
        map (l: if l == old then new else l) lines;

      patchedLines = lib.pipe swappedBar [
        (repl "oxwm.border.set_width(0)" "oxwm.border.set_width(2)")
        (repl "oxwm.bar.set_scheme_occupied(colors.blue, colors.bg, colors.cyan)" "oxwm.bar.set_scheme_occupied(colors.orange, colors.bg, colors.orange)")
        (repl "oxwm.border.set_focused_color(colors.purple)" ''
          local focus_colors = { tokyonight = colors.blue, gruvbox = colors.orange, catppuccin = colors.purple }
          oxwm.border.set_focused_color(focus_colors[theme] or colors.purple)'')
        (repl ''local bar_font = "JetBrainsMono Nerd Font Propo:style=Bold:size=12"'' ''local bar_font = "JetBrainsMono Nerd Font Propo:style=Bold:size=10"'')
        (repl ''oxwm.key.bind({ modkey }, "S", oxwm.spawn({ "sh", "-c", "maim -s | xclip -selection clipboard -t image/png" }))'' ''oxwm.key.bind({ modkey }, "S", oxwm.spawn({ "sh", "-c", [[${screenshotCmd}]] }))'')
        (repl ''oxwm.key.bind({ modkey }, "D", oxwm.spawn({ "sh", "-c", "rofi -show drun" }))'' ''
          oxwm.key.bind({ modkey }, "D", oxwm.spawn({ "sh", "-c", "dmenu_run -l 10" }))
          -- Launch browser
           ${firefoxBind}
          -- Apps (terminal)
          oxwm.key.bind({ modkey }, "E", oxwm.spawn({ "sh", "-c", "st -e yazi" }))
          oxwm.key.bind({ modkey }, "O", oxwm.spawn({ "sh", "-c", "ocr-copy" }))
          oxwm.key.bind({ modkey, "Shift" }, "O", oxwm.spawn({ "sh", "-c", "st -e opencode ~/Projects" }))
          oxwm.key.bind({ modkey }, "W", oxwm.spawn({ "sh", "-c", "st -e nmtui" }))
          oxwm.key.bind({ modkey }, "U", oxwm.spawn({ "sh", "-c", "st -e bluetui" }))
          oxwm.key.bind({ modkey }, "Y", oxwm.spawn({ "sh", "-c", "st -e ikhal" }))
          oxwm.key.bind({ modkey, "Shift" }, "B", oxwm.spawn({ "sh", "-c", "st -e btop" }))
          oxwm.key.bind({ modkey }, "V", oxwm.spawn({ "sh", "-c", [[CM_LAUNCHER=dmenu-themed CM_DIR=~/.cache/clipmenu clipmenu -l 10]] }))'')
        (repl ''local colors = require("colors.custom-colors");'' themeLoader)
        # Hardware keys have no mods; mic-mute is absent from oxwm's keysym
        # map, so that key stays unbound rather than silently dropping.
        (repl ''oxwm.key.bind({ modkey, "Shift" }, "Q", oxwm.quit())'' ''
                    oxwm.key.bind({ modkey, "Shift" }, "Q", oxwm.quit())
                    oxwm.key.bind({}, "XF86AudioRaiseVolume", oxwm.spawn({ "sh", "-c", [[wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -h string:x-dunst-stack-tag:osd "Volume" "$($HOME/.config/oxwm/volume-status.sh)"]] }))
                    oxwm.key.bind({}, "XF86AudioLowerVolume", oxwm.spawn({ "sh", "-c", [[wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -h string:x-dunst-stack-tag:osd "Volume" "$($HOME/.config/oxwm/volume-status.sh)"]] }))
                    oxwm.key.bind({}, "XF86AudioMute", oxwm.spawn({ "sh", "-c", [[wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send -h string:x-dunst-stack-tag:osd "Volume" "$($HOME/.config/oxwm/volume-status.sh)"]] }))
          oxwm.key.bind({}, "XF86MonBrightnessUp", oxwm.spawn({ "sh", "-c", [[brightnessctl set 5%+ && notify-send -h string:x-dunst-stack-tag:osd "Brightness" "$($HOME/.config/oxwm/brightness-status.sh)"]] }))
          oxwm.key.bind({}, "XF86MonBrightnessDown", oxwm.spawn({ "sh", "-c", [[brightnessctl set 5%- && notify-send -h string:x-dunst-stack-tag:osd "Brightness" "$($HOME/.config/oxwm/brightness-status.sh)"]] }))
          oxwm.key.bind({ modkey }, "M", oxwm.spawn({ "sh", "-c", [[wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && notify-send -h string:x-dunst-stack-tag:osd "Mic" "$($HOME/.config/oxwm/mic-status.sh)"]] }))
          oxwm.key.bind({ modkey, "Shift" }, "V", oxwm.spawn({ "sh", "-c", [[st -n wiremix -c wiremix -e wiremix]] }))
          oxwm.key.bind({ modkey, "Shift" }, "P", oxwm.spawn({ "sh", "-c", [[prof=$({ echo power-saver; echo balanced; echo performance; } | dmenu-themed -l 3) && [ -n "$prof" ] && powerprofilesctl set $prof && notify-send -h string:x-dunst-stack-tag:osd Power $prof]] }))
          oxwm.key.bind({ modkey }, "Escape", oxwm.spawn({ "sh", "-c", [[prof=$(printf 'Power off\nReboot\nSuspend\nLog out\n' | dmenu-themed -l 4) && case "$prof" in "Power off") systemctl poweroff ;; Reboot) systemctl reboot ;; Suspend) systemctl suspend ;; "Log out") pkill -x oxwm ;; esac]] }))'')
        (repl ''-- oxwm.autostart("xwallpaper --zoom ~/walls/dune.jpg")'' ''
                    -- oxwm.autostart("xwallpaper --zoom ~/walls/dune.jpg")
          ${wallpaperBlock}'')
        (repl ''-- oxwm.autostart("dunst")'' ''
          oxwm.autostart("dunst")
          -- clipmenud runs as a systemd user service below, so WM reloads
          -- can't orphan it the way autostart children get orphaned.'')
        (repl ''oxwm.rule.add({ instance = "gimp", floating = true })'' ''
          -- oxwm.rule.add({ instance = "gimp", floating = true })
          oxwm.rule.add({ instance = "wiremix", floating = true })'')
        (repl ''oxwm.rule.add({ instance = "brave-browser", tag = 2 })'' ''-- oxwm.rule.add({ instance = "brave-browser", tag = 2 })'')
        (repl ''oxwm.rule.add({ class = "firefox", tag = 3 })'' ''-- oxwm.rule.add({ class = "firefox", tag = 3 })'')
        (repl ''oxwm.rule.add({ instance = "slack", tag = 4 })'' ''-- oxwm.rule.add({ instance = "slack", tag = 4 })'')
        (repl ''oxwm.rule.add({ instance = "discord", tag = 5 })'' ''-- oxwm.rule.add({ instance = "discord", tag = 5 })'')
      ];

      # writeText (not toFile): the text references store paths (dmenu).
      finalConfig = pkgs.writeText "oxwm-config.lua" (lib.concatStringsSep "\n" patchedLines);

      # config.def.h order: default fg, default bg, cursor, reverse cursor,
      # then the 16 ANSI colors. Comment-anchored patterns sort before their
      # bare twins ("black" also names the default background), so order here
      # is load-bearing: each pattern must be unique when applied in sequence.
      # Replacements are complete C string tokens including quotes and comma.
      stPatterns = [
        ''"gray90", /\* default foreground colour \*/''
        ''"black", /\* default background colour \*/''
        ''"#cccccc",''
        ''"#555555",''
        ''"black",''
        ''"red3",''
        ''"green3",''
        ''"yellow3",''
        ''"blue2",''
        ''"magenta3",''
        ''"cyan3",''
        ''"gray90",''
        ''"gray50",''
        ''"red",''
        ''"green",''
        ''"yellow",''
        ''"#5c5cff",''
        ''"magenta",''
        ''"cyan",''
        ''"white",''
      ];

      stThemes = {
        tokyonight = {
          fg = "#c0caf5";
          bg = "#1a1b26";
          cursor = "#c0caf5";
          colors = [
            "#15161e"
            "#f7768e"
            "#9ece6a"
            "#e0af68"
            "#7aa2f7"
            "#bb9af7"
            "#7dcfff"
            "#a9b1d6"
            "#414868"
            "#f7768e"
            "#9ece6a"
            "#e0af68"
            "#7aa2f7"
            "#bb9af7"
            "#7dcfff"
            "#c0caf5"
          ];
        };
        gruvbox = {
          fg = "#ebdbb2";
          bg = "#282828";
          cursor = "#ebdbb2";
          colors = [
            "#282828"
            "#cc241d"
            "#98971a"
            "#d79921"
            "#458588"
            "#b16286"
            "#689d6a"
            "#a89984"
            "#928374"
            "#fb4934"
            "#b8bb26"
            "#fabd2f"
            "#83a598"
            "#d3869b"
            "#8ec07c"
            "#ebdbb2"
          ];
        };
        catppuccin = {
          fg = "#cdd6f4";
          bg = "#1e1e2e";
          cursor = "#f5e0dc";
          colors = [
            "#45475a"
            "#f38ba8"
            "#a6e3a1"
            "#f9e2af"
            "#89b4fa"
            "#cba6f7"
            "#94e2d5"
            "#bac2de"
            "#585b70"
            "#f38ba8"
            "#a6e3a1"
            "#f9e2af"
            "#89b4fa"
            "#cba6f7"
            "#94e2d5"
            "#a5adcb"
          ];
        };
      };

      mkThemedSt =
        name: t:
        pkgs.st.overrideAttrs (old: {
          pname = "st-${name}";
          postPatch = (old.postPatch or "") + ''
            sed -i ${
              lib.concatMapStringsSep " " (pair: "-e 's|${pair.fst}|\"${pair.snd}\",|'") (
                lib.zipLists stPatterns (
                  [
                    t.fg
                    t.bg
                    t.cursor
                    t.bg
                  ]
                  ++ t.colors
                )
              )
            } \
              -e 's|static char \*font = "Liberation Mono:pixelsize=12:antialias=true:autohint=true";|static char *font = "${constants.monoFont}:style=Regular:size=10:antialias=true:autohint=true";|' \
              config.def.h
          '';
          postFixup = (old.postFixup or "") + ''
            mv "$out/bin/st" "$out/bin/st-${name}"
          '';
        });

      # oxwm spawns "st" by bare name; this dispatches to the themed build
      # matching the active theme file, same source of truth as the palette.
      stLauncher = pkgs.writeShellScriptBin "st" ''
        theme=$(cat "$HOME/.config/oxwm/theme" 2>/dev/null || echo tokyonight)
        theme="''${theme//[[:space:]]/}"
        case "$theme" in
          gruvbox) exec st-gruvbox "$@" ;;
          catppuccin) exec st-catppuccin "$@" ;;
          *) exec st-tokyonight "$@" ;;
        esac
      '';

      # Same dispatch for notifications: one dunstrc per theme, picked by
      # the active theme file. dunst is autostarted by oxwm and re-reads
      # nothing on its own, so oxwm-theme restarts it on every switch.
      dunstCfg = p: ''
        [global]
            monitor = 0
            follow = mouse
              width = 320
              height = (0, 120)
              origin = top-right
              offset = (12, 44)
            font = ${constants.monoFont} 10
            background = "${p.bg}"
            foreground = "${p.fg}"
            frame_color = "${p.blue}"
            frame_width = 2
              corner_radius = 0
            gap_size = 8
            padding = 12
            markup = full
            format = "<b>%s</b>\n%b"
            alignment = left
            stack_duplicates = true
            show_age_threshold = 60
            idle_threshold = 120
        [urgency_low]
            background = "${p.bg}"
            foreground = "${p.grey}"
            timeout = 5
        [urgency_normal]
            background = "${p.bg}"
            foreground = "${p.fg}"
            timeout = 10
        [urgency_critical]
            background = "${p.red}"
            foreground = "${p.bg}"
            frame_color = "${p.red}"
            timeout = 0
      '';

      dunstLauncher = pkgs.writeShellScriptBin "dunst" ''
        theme=$(cat "$HOME/.config/oxwm/theme" 2>/dev/null || echo tokyonight)
        case "$theme" in
          gruvbox) exec ${pkgs.dunst}/bin/dunst -config "$HOME/.config/oxwm/dunstrc-gruvbox" ;;
          catppuccin) exec ${pkgs.dunst}/bin/dunst -config "$HOME/.config/oxwm/dunstrc-catppuccin" ;;
          *) exec ${pkgs.dunst}/bin/dunst -config "$HOME/.config/oxwm/dunstrc-tokyonight" ;;
        esac
      '';
      # Theme flags shared by both dmenu wrappers below.
      dmenuFlags =
        t:
        ''-nb "${t.bg}" -nf "${t.fg}" -sb "${t.blue}" -sf "${t.bg}" -fn "${constants.monoFont}:size=10"'';

      # Upstream binds Mod+D to `dmenu_run -l 10`; this wrapper only adds
      # theme colors (dmenu_run itself builds the executable list).
      dmenuRun = pkgs.writeShellScriptBin "dmenu_run" ''
        theme=$(cat "$HOME/.config/oxwm/theme" 2>/dev/null || echo tokyonight)
        case "$theme" in
          gruvbox) exec ${pkgs.dmenu}/bin/dmenu_run ${dmenuFlags palettes.gruvbox} "$@" ;;
          catppuccin) exec ${pkgs.dmenu}/bin/dmenu_run ${dmenuFlags palettes.catppuccin} "$@" ;;
          *) exec ${pkgs.dmenu}/bin/dmenu_run ${dmenuFlags palettes.tokyonight} "$@" ;;
        esac
      '';

      # Same theming for piped custom menus (power, session): plain dmenu
      # reads stdin, so unlike dmenu_run it shows exactly what it is given.
      dmenuThemed = pkgs.writeShellScriptBin "dmenu-themed" ''
        theme=$(cat "$HOME/.config/oxwm/theme" 2>/dev/null || echo tokyonight)
        case "$theme" in
          gruvbox) exec ${pkgs.dmenu}/bin/dmenu ${dmenuFlags palettes.gruvbox} "$@" ;;
          catppuccin) exec ${pkgs.dmenu}/bin/dmenu ${dmenuFlags palettes.catppuccin} "$@" ;;
          *) exec ${pkgs.dmenu}/bin/dmenu ${dmenuFlags palettes.tokyonight} "$@" ;;
        esac
      '';

      # matugen.lua, rendered from the active oxwm palette: base16 for nvim
      # plus the lualine theme the loader applies. `oxt` rewrites it on every
      # switch and SIGUSR1s nvim, which re-requires it live. nvim ships no
      # matugen.lua of its own; until the first switch the loader simply
      # keeps the upstream default theme. Accents come from `palettes`
      # (shared with bar/dunst); base01 from the st ANSI ramp.
      nvimBase16 =
        p: s:
        let
          c0 = builtins.elemAt s.colors 0;
          cur = s.cursor;
        in
        ''
          local M = {}
          function M.setup()
            require('base16-colorscheme').setup {
              base00 = '${p.bg}',
              base01 = '${c0}',
              base02 = '${p.sep}',
              base03 = '${p.grey}',
              base04 = '${p.lavender}',
              base05 = '${p.fg}',
              base06 = '${p.fg}',
              base07 = '${cur}',
              base08 = '${p.red}',
              base09 = '${p.orange}',
              base0A = '${p.yellow}',
              base0B = '${p.green}',
              base0C = '${p.cyan}',
              base0D = '${p.blue}',
              base0E = '${p.purple}',
              base0F = '${p.light_blue}',
            }
          end
          local signal = vim.uv.new_signal()
          signal:start(
            'sigusr1',
            vim.schedule_wrap(function()
              package.loaded['matugen'] = nil
              local fresh = require('matugen')
              fresh.setup()
              local ok, lualine = pcall(require, 'lualine')
              if ok and fresh.lualine then lualine.setup({ options = { theme = fresh.lualine } }) end
            end)
          )
          local function lualine_mode(accent)
            return {
              a = { bg = accent, fg = '${p.bg}', gui = 'bold' },
              b = { bg = '${p.sep}', fg = '${p.fg}' },
              c = { bg = '${c0}', fg = '${p.lavender}' },
            }
          end
          M.lualine = {
            normal = lualine_mode('${p.blue}'),
            insert = lualine_mode('${p.green}'),
            visual = lualine_mode('${p.purple}'),
            replace = lualine_mode('${p.red}'),
            command = lualine_mode('${p.light_blue}'),
            inactive = lualine_mode('${p.sep}'),
          }
          return M
        '';

      # Live per-app themes, all rendered by `oxt` from the active palette
      # into an "oxwm" slot each app selects statically. Single source of
      # truth stays `palettes`; these mappings are approximations.
      hexToDec =
        hex:
        let
          digits = {
            "0" = 0;
            "1" = 1;
            "2" = 2;
            "3" = 3;
            "4" = 4;
            "5" = 5;
            "6" = 6;
            "7" = 7;
            "8" = 8;
            "9" = 9;
            a = 10;
            b = 11;
            c = 12;
            d = 13;
            e = 14;
            f = 15;
          };
        in
        lib.foldl' (acc: c: acc * 16 + digits.${c}) 0 (
          lib.stringToCharacters (lib.toLower (lib.removePrefix "#" hex))
        );

      yaziFlavor = p: ''
        # Generated by oxt - do not edit. Follows the active oxwm palette.
        [mgr]
        cwd = { fg = '${p.fg}' }
        find_keyword = { fg = '${p.red}', bold = true, italic = true, underline = true }
        find_position = { fg = '${p.red}', bold = true, italic = true }
        marker_copied = { fg = '${p.bg}', bg = '${p.green}' }
        marker_cut = { fg = '${p.bg}', bg = '${p.yellow}' }
        marker_marked = { fg = '${p.bg}', bg = '${p.red}' }
        marker_selected = { fg = '${p.bg}', bg = '${p.blue}' }
        count_copied = { fg = '${p.fg}', bg = '${p.green}' }
        count_cut = { fg = '${p.fg}', bg = '${p.yellow}' }
        count_selected = { fg = '${p.bg}', bg = '${p.blue}' }
        border_style = { fg = '${p.orange}' }
        [status]
        overall = { fg = '${p.orange}' }
        sep_left = { open = "", close = "" }
        sep_right = { open = "", close = "" }
        progress_label = { bold = true }
        progress_normal = { fg = '${p.orange}', bg = '${p.bg}' }
        progress_error = { fg = '${p.red}', bg = '${p.bg}' }
        perm_type = { fg = '${p.green}' }
        perm_write = { fg = '${p.blue}' }
        perm_exec = { fg = '${p.red}' }
        perm_read = { fg = '${p.grey}' }
        perm_sep = { fg = '${p.orange}' }
        [mode]
        normal_main = { bg = '${p.orange}', fg = '${p.bg}', bold = true }
        normal_alt = { bg = '${p.sep}', fg = '${p.fg}' }
        select_main = { bg = '${p.green}', fg = '${p.bg}', bold = true }
        select_alt = { bg = '${p.sep}', fg = '${p.fg}' }
        unset_main = { bg = '${p.blue}', fg = '${p.bg}', bold = true }
        unset_alt = { bg = '${p.sep}', fg = '${p.fg}' }
        [input]
        border = { fg = '${p.orange}' }
        title = {}
        value = { fg = '${p.fg}' }
        selected = { reversed = true }
        [tabs]
        active = { fg = '${p.bg}', bold = true, bg = '${p.orange}' }
        inactive = { fg = '${p.green}', bg = '${p.bg}' }
        sep_inner = { open = "", close = "" }
        [cmp]
        border = { fg = '${p.orange}', bg = '${p.bg}' }
        [tasks]
        border = { fg = '${p.orange}' }
        title = {}
        hovered = { fg = '${p.blue}', underline = true }
        [which]
        cols = 3
        mask = { bg = '${p.bg}' }
        cand = { fg = '${p.orange}' }
        rest = { fg = '${p.bg}' }
        desc = { fg = '${p.fg}' }
        separator = " ▶ "
        separator_style = { fg = '${p.fg}' }
        [spot]
        border = { fg = '${p.orange}' }
        title = { fg = '${p.orange}' }
        tbl_col = { fg = '${p.fg}' }
        tbl_cell = { fg = '${p.fg}', bg = '${p.bg}' }
        [help]
        on = { fg = '${p.fg}' }
        run = { fg = '${p.fg}' }
        hovered = { reversed = true, bold = true }
        footer = { fg = '${p.bg}', bg = '${p.green}' }
        [notify]
        title_info = { fg = '${p.blue}' }
        title_warn = { fg = '${p.yellow}' }
        title_error = { fg = '${p.red}' }
        [filetype]
        rules = [
          { mime = "image/*", fg = '${p.orange}' },
          { mime = "{audio,video}/*", fg = '${p.light_blue}' },
          { mime = "application/{zip,rar,7z*,tar,gzip,xz,zstd,bzip*,lzma,compress,archive,cpio,arj,xar,ms-cab*}", fg = '${p.green}' },
          { mime = "application/{pdf,doc,rtf}", fg = '${p.blue}' },
          { mime = "*", is = "orphan", fg = '${p.bg}', bg = '${p.red}' },
          { mime = "application/*exec*", fg = '${p.red}' },
          { mime = "*/", fg = '${p.orange}' },
          { url = "*", fg = '${p.fg}' },
        ]
      '';

      btopTheme = p: ''
        # Generated by oxt - do not edit. Follows the active oxwm palette.
        theme[main_bg]="${p.bg}"
        theme[main_fg]="${p.fg}"
        theme[title]="${p.orange}"
        theme[hi_fg]="${p.orange}"
        theme[selected_bg]="${p.orange}"
        theme[selected_fg]="${p.bg}"
        theme[inactive_fg]="${p.grey}"
        theme[graph_text]="${p.grey}"
        theme[meter_bg]="${p.sep}"
        theme[cpu_box]="${p.green}"
        theme[mem_box]="${p.blue}"
        theme[net_box]="${p.purple}"
        theme[proc_box]="${p.yellow}"
        theme[div_line]="${p.sep}"
        theme[temp_start]="${p.green}"
        theme[temp_mid]="${p.yellow}"
        theme[temp_end]="${p.red}"
        theme[cpu_start]="${p.green}"
        theme[cpu_mid]="${p.yellow}"
        theme[cpu_end]="${p.red}"
        theme[free_start]="${p.green}"
        theme[free_mid]="${p.cyan}"
        theme[free_end]="${p.blue}"
        theme[cached_start]="${p.green}"
        theme[cached_mid]="${p.yellow}"
        theme[cached_end]="${p.orange}"
        theme[available_start]="${p.green}"
        theme[available_mid]="${p.cyan}"
        theme[available_end]="${p.blue}"
        theme[used_start]="${p.green}"
        theme[used_mid]="${p.yellow}"
        theme[used_end]="${p.red}"
        theme[download_start]="${p.green}"
        theme[download_mid]="${p.cyan}"
        theme[download_end]="${p.blue}"
        theme[upload_start]="${p.yellow}"
        theme[upload_mid]="${p.orange}"
        theme[upload_end]="${p.red}"
        theme[process_start]="${p.blue}"
        theme[process_mid]="${p.purple}"
        theme[process_end]="${p.lavender}"
      '';

      batTmTheme = p: ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!-- Generated by oxt - do not edit. Follows the active oxwm palette. -->
        <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>name</key><string>oxwm</string>
          <key>settings</key>
          <array>
            <dict><key>settings</key><dict>
              <key>background</key><string>${p.bg}</string>
              <key>foreground</key><string>${p.fg}</string>
              <key>caret</key><string>${p.orange}</string>
              <key>selection</key><string>${p.sep}</string>
              <key>lineHighlight</key><string>${p.sep}</string>
              <key>gutter</key><string>${p.grey}</string>
              <key>gutterForeground</key><string>${p.grey}</string>
            </dict></dict>
            <dict><key>name</key><string>Comment</string><key>scope</key><string>comment</string><key>settings</key><dict><key>foreground</key><string>${p.grey}</string><key>fontStyle</key><string>italic</string></dict></dict>
            <dict><key>name</key><string>Keyword</string><key>scope</key><string>keyword</string><key>settings</key><dict><key>foreground</key><string>${p.purple}</string></dict></dict>
            <dict><key>name</key><string>String</string><key>scope</key><string>string</string><key>settings</key><dict><key>foreground</key><string>${p.green}</string></dict></dict>
            <dict><key>name</key><string>Number</string><key>scope</key><string>constant.numeric</string><key>settings</key><dict><key>foreground</key><string>${p.orange}</string></dict></dict>
            <dict><key>name</key><string>Function</string><key>scope</key><string>entity.name.function</string><key>settings</key><dict><key>foreground</key><string>${p.blue}</string></dict></dict>
            <dict><key>name</key><string>Type</string><key>scope</key><string>entity.name.type, support.type</string><key>settings</key><dict><key>foreground</key><string>${p.yellow}</string></dict></dict>
            <dict><key>name</key><string>Variable</string><key>scope</key><string>variable</string><key>settings</key><dict><key>foreground</key><string>${p.fg}</string></dict></dict>
            <dict><key>name</key><string>Constant</string><key>scope</key><string>constant, support.constant</string><key>settings</key><dict><key>foreground</key><string>${p.cyan}</string></dict></dict>
            <dict><key>name</key><string>Tag</string><key>scope</key><string>entity.name.tag</string><key>settings</key><dict><key>foreground</key><string>${p.red}</string></dict></dict>
            <dict><key>name</key><string>Heading</string><key>scope</key><string>markup.heading</string><key>settings</key><dict><key>foreground</key><string>${p.orange}</string><key>fontStyle</key><string>bold</string></dict></dict>
            <dict><key>name</key><string>Punctuation</string><key>scope</key><string>punctuation</string><key>settings</key><dict><key>foreground</key><string>${p.grey}</string></dict></dict>
          </array>
        </dict>
        </plist>
      '';

      starshipToml =
        p: s:
        let
          c0 = builtins.elemAt s.colors 0;
        in
        ''
          # Generated by oxt - do not edit. Follows the active oxwm palette.
          palette = "oxwm"
          [palettes.oxwm]
          black = "${c0}"
          red = "${p.red}"
          green = "${p.green}"
          yellow = "${p.yellow}"
          blue = "${p.blue}"
          magenta = "${p.purple}"
          cyan = "${p.cyan}"
          white = "${p.fg}"
          rosewater = "${p.lavender}"
          flamingo = "${p.purple}"
          pink = "${p.lavender}"
          maroon = "${p.red}"
          peach = "${p.orange}"
          mauve = "${p.purple}"
          lavender = "${p.lavender}"
          sapphire = "${p.blue}"
          sky = "${p.light_blue}"
          teal = "${p.cyan}"
          text = "${p.fg}"
          subtext1 = "${p.lavender}"
          subtext0 = "${p.grey}"
          overlay2 = "${p.grey}"
          overlay1 = "${p.grey}"
          overlay0 = "${p.sep}"
          surface2 = "${p.sep}"
          surface1 = "${p.sep}"
          surface0 = "${c0}"
          base = "${p.bg}"
          mantle = "${c0}"
          crust = "${c0}"
          [directory]
          style = "mauve bold"
          [git_branch]
          style = "bold mauve"
        '';

      fzfFish = p: ''
        # Generated by oxt - do not edit. Sourced automatically from conf.d.
        set -gx FZF_DEFAULT_OPTS "--color=bg:${p.bg},fg:${p.fg},hl:${p.blue},fg+:${p.fg},bg+:${p.sep},hl+:${p.light_blue},info:${p.grey},prompt:${p.orange},pointer:${p.orange},marker:${p.green},spinner:${p.cyan},header:${p.grey}"
      '';

      obsTheme = p: ''
        /* Generated by oxt - do not edit. Yami variant following the active oxwm palette. */
        @OBSThemeMeta {
            name: 'oxwm';
            id: 'com.obsproject.oxwm';
            extends: 'com.obsproject.Yami';
            author: 'oxt';
            dark: 'true';
        }

        @OBSThemeVars {
            --grey1: ${p.grey};
            --grey2: ${p.grey};
            --grey3: ${p.sep};
            --grey4: ${p.sep};
            --grey5: ${p.sep};
            --grey6: ${p.bg};
            --grey7: ${p.bg};
            --grey8: ${p.bg};

            --primary: ${p.blue};
            --primary_light: ${p.light_blue};
            --primary_dark: ${p.blue};

            --border_color: var(--grey5);

            --input_bg: var(--grey5);
            --input_bg_hover: var(--grey7);
            --input_bg_focus: var(--grey7);

            --list_item_bg_selected: var(--primary);
            --list_item_bg_hover: var(--primary_light);

            --input_border: var(--grey1);
            --input_border_hover: var(--grey1);
            --input_border_focus: var(--primary);

            --button_bg: var(--primary);
            --button_bg_hover: var(--primary_light);
            --button_bg_down: var(--grey7);
            --button_bg_disabled: var(--grey6);

            --button_bg_red: ${p.red};
            --button_bg_red_hover: ${p.orange};
            --button_bg_red_down: ${p.red};

            --button_border: var(--primary);
            --button_border_hover: var(--button_bg_hover);
            --button_border_focus: var(--button_bg_hover);

            --tab_bg_down: var(--primary);

            --tab_border_hover: var(--primary_light);
            --tab_border_focus: var(--input_border_focus);
            --tab_border_selected: var(--primary);

            --scrollbar_handle: var(--grey5);
            --scrollbar_hover: var(--primary_light);
            --scrollbar_down: var(--grey5);
            --scrollbar_border: var(--grey5);

            --toolbutton_bg: var(--grey5);
            --toolbutton_bg_hover: var(--primary_light);
            --toolbutton_bg_down: var(--primary_dark);
        }

        QMenu::separator {
            background-color: var(--grey5);
        }

        QDockWidget::title {
            background-color: var(--grey6);
        }

        QDockWidget::close-button:hover,
        QDockWidget::float-button:hover {
            background: var(--grey3);
        }

        QScrollBar::handle:hover {
            border-color: var(--scrollbar_hover);
        }

        QScrollBar::handle:pressed {
            border-color: var(--scrollbar_down);
        }

        QToolButton,
        QPushButton[toolButton="true"] {
            background-color: var(--toolbutton_bg);
            border-color: var(--toolbutton_bg);
        }

        QToolButton:hover,
        QToolButton:focus {
            border-color: var(--primary_light);
            background-color: var(--primary_light);
        }

        QToolButton:pressed,
        QToolButton:pressed:hover {
            background-color: var(--toolbutton_bg_down);
            border-color: var(--toolbutton_bg_down);
        }

        QTabBar::tab {
            background-color: var(--grey5);
        }

        QTabBar QToolButton {
            background-color: var(--grey5);
        }

        #streamButton:!hover:!pressed.state-active,
        #recordButton:!hover:!pressed.state-active,
        #pauseRecordButton:!hover:!pressed.state-active,
        #replayBufferButton:!hover:!pressed.state-active,
        #virtualCamButton:!hover:!pressed.state-active,
        #modeSwitch:!hover:!pressed.state-active,
        #broadcastButton:!hover:!pressed.state-active {
            background: var(--button_bg_red);
            border-color: var(--button_bg_red);
        }

        #streamButton:hover:!pressed.state-active,
        #recordButton:hover:!pressed.state-active,
        #pauseRecordButton:hover:!pressed.state-active,
        #replayBufferButton:hover:!pressed.state-active,
        #virtualCamButton:hover:!pressed.state-active,
        #modeSwitch:hover:!pressed.state-active,
        #broadcastButton:hover:!pressed.state-active {
            background: var(--button_bg_red_hover);
        }

        #streamButton:pressed.state-active,
        #recordButton:pressed.state-active,
        #pauseRecordButton:pressed.state-active,
        #replayBufferButton:pressed.state-active,
        #virtualCamButton:pressed.state-active,
        #modeSwitch:pressed.state-active,
        #broadcastButton:pressed.state-active {
            background: var(--button_bg_red_down);
        }

        QPushButton:disabled {
            border-color: var(--grey5);
        }

        QHeaderView::section {
            background-color: var(--grey5);
        }

        OBSQTDisplay {
            qproperty-displayBackgroundColor: var(--grey5);
        }

        VolumeMeter {
            qproperty-foregroundNominalColor: ${p.green};
            qproperty-foregroundWarningColor: ${p.orange};
            qproperty-foregroundErrorColor: ${p.red};
        }
      '';

      # LibreOffice theme extension, same shape noctalia shipped: static
      # packaging files plus a generated color scheme. `oxt` installs the
      # .oxt with unopkg (constant extension id, so reinstalls overwrite),
      # then selects the scheme in the user registry.
      loDescription = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <description xmlns="http://openoffice.org/extensions/description/2006"
                     xmlns:d="http://openoffice.org/extensions/description/2006"
                     xmlns:xlink="http://www.w3.org/1999/xlink">
            <identifier value="dev.oxwm.libreoffice.theme" />
            <version value="1.0.0" />
            <display-name>
                <name lang="en">oxwm Theme</name>
            </display-name>
            <extension-description>
                <src xlink:href="pkg-description.en" lang="en" />
            </extension-description>
        </description>
      '';

      loManifest = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <manifest:manifest xmlns:manifest="http://openoffice.org/2001/manifest">
          <manifest:file-entry manifest:full-path="Theme_Colors.xcu" manifest:media-type="application/vnd.sun.star.configuration-data"/>
          <manifest:file-entry manifest:full-path="Paths.xcu" manifest:media-type="application/vnd.sun.star.configuration-data"/>
        </manifest:manifest>
      '';

      loPaths = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <oor:component-data xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" oor:name="Paths" oor:package="org.openoffice.Office">
          <node oor:name="Paths">
            <node oor:name="Palette">
              <node oor:name="InternalPaths">
                <node oor:name="%origin%/palettes" oor:op="fuse"/>
              </node>
            </node>
          </node>
        </oor:component-data>
      '';

      loPkgDesc = "oxwm application colors for LibreOffice, generated from the active oxwm palette.\n";

      loThemeColors =
        p:
        let
          d = hexToDec;
        in
        ''
          <?xml version="1.0" encoding="UTF-8"?>
          <oor:component-data xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" oor:name="UI" oor:package="org.openoffice.Office">
            <node oor:name="ColorScheme">
              <node oor:name="ColorSchemes">
                <node oor:name="oxwm" oor:op="fuse">
                  <node oor:name="AppBackground"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.bg)}</value></prop></node>
                  <node oor:name="DocColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.bg)}</value></prop></node>
                  <node oor:name="FontColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.fg)}</value></prop></node>
                  <node oor:name="DocBoundaries"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="WindowColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.bg)}</value></prop></node>
                  <node oor:name="WindowTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.fg)}</value></prop></node>
                  <node oor:name="BaseColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.bg)}</value></prop></node>
                  <node oor:name="ButtonColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="ButtonTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.fg)}</value></prop></node>
                  <node oor:name="AccentColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.orange)}</value></prop></node>
                  <node oor:name="DisabledColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="DisabledTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.grey)}</value></prop></node>
                  <node oor:name="ShadowColor"><prop oor:name="Color" oor:op="fuse"><value>0</value></prop></node>
                  <node oor:name="Shadow"><prop oor:name="Color" oor:op="fuse"><value xsi:nil="false" /></prop><prop oor:name="IsVisible" oor:op="fuse"><value>false</value></prop></node>
                  <node oor:name="SeparatorColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="FaceColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="ActiveColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.orange)}</value></prop></node>
                  <node oor:name="ActiveTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.bg)}</value></prop></node>
                  <node oor:name="ActiveBorderColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.orange)}</value></prop></node>
                  <node oor:name="FieldColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="MenuBarColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="MenuBarTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.fg)}</value></prop></node>
                  <node oor:name="MenuBarHighlightColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.orange)}</value></prop></node>
                  <node oor:name="MenuBarHighlightTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.bg)}</value></prop></node>
                  <node oor:name="MenuColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="MenuTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.fg)}</value></prop></node>
                  <node oor:name="MenuHighlightColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.orange)}</value></prop></node>
                  <node oor:name="MenuHighlightTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.bg)}</value></prop></node>
                  <node oor:name="MenuBorderColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="InactiveColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="InactiveTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.grey)}</value></prop></node>
                  <node oor:name="InactiveBorderColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                  <node oor:name="BASICEditor"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.bg)}</value></prop></node>
                  <node oor:name="BASICError"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.red)}</value></prop></node>
                  <node oor:name="BASICIdentifier"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.fg)}</value></prop></node>
                  <node oor:name="BASICKeyword"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.purple)}</value></prop></node>
                  <node oor:name="BASICNumber"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.orange)}</value></prop></node>
                  <node oor:name="BASICOperator"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.yellow)}</value></prop></node>
                  <node oor:name="BASICString"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.green)}</value></prop></node>
                  <node oor:name="BASICComment"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.grey)}</value></prop></node>
                  <node oor:name="WriterIdxShadings"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop><prop oor:name="IsVisible" oor:op="fuse"><value>true</value></prop></node>
                  <node oor:name="WriterFieldShadings"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop><prop oor:name="IsVisible" oor:op="fuse"><value>true</value></prop></node>
                  <node oor:name="CalcGrid"><prop oor:name="Color" oor:op="fuse"><value>${toString (d p.sep)}</value></prop></node>
                </node>
              </node>
            </node>
          </oor:component-data>
        '';

      loOxt =
        p:
        pkgs.runCommand "oxwm-libreoffice-theme.oxt" { nativeBuildInputs = [ pkgs.zip ]; } ''
          work=$(mktemp -d)
          mkdir -p "$work/oxwm/META-INF"
          printf '%s' ${lib.escapeShellArg loManifest} > "$work/oxwm/META-INF/manifest.xml"
          printf '%s' ${lib.escapeShellArg loDescription} > "$work/oxwm/description.xml"
          printf '%s' ${lib.escapeShellArg loPaths} > "$work/oxwm/Paths.xcu"
          printf '%s' ${lib.escapeShellArg loPkgDesc} > "$work/oxwm/pkg-description.en"
          printf '%s' ${lib.escapeShellArg (loThemeColors p)} > "$work/oxwm/Theme_Colors.xcu"
          ( cd "$work/oxwm" && zip -qr "$out" . )
        '';

      # One-word theme switching: writes the theme file, sets that theme's
      oxwmThemeCmd = pkgs.writeShellApplication {
        name = "oxt";
        runtimeInputs = [
          pkgs.bat
          pkgs.feh
          pkgs.libreoffice
          pkgs.xdotool
          pkgs.procps
          pkgs.python3
        ];
        text = ''
          case "''${1:-}" in
            tokyonight|tok|t) theme=tokyonight ;;
            gruvbox|gruv|g) theme=gruvbox ;;
            catppuccin|cat|c) theme=catppuccin ;;
            *)
              echo "pakai: oxt {tokyonight|gruvbox|catppuccin} (t|g|c)" >&2
              exit 2
              ;;
          esac
          echo "$theme" > "$HOME/.config/oxwm/theme"
          if ! feh --bg-fill "$HOME"/.config/oxwm/wallpapers/"$theme".* 2>/dev/null; then
            echo "wallpaper gagal dipasang (X tidak aktif?)" >&2
          fi
          # user-PATH dunst is the themed wrapper above, not the raw binary.
          # Match by config path: the daemon's comm is .dunst-wrapped (the
          # wrapped ELF), so `pkill -x dunst` never matches anything.
          # Brief pause so the old daemon releases the bus name first. Skip
          # the whole restart without a display: killing the daemon when the
          # replacement cannot start leaves notifications dead.
          if [ -n "''${DISPLAY:-}" ] && pkill -f "oxwm/dunstrc-" 2>/dev/null; then
            sleep 0.5
            (dunst >/dev/null 2>&1 &)
          fi
          case "$theme" in
            gruvbox) opencode_theme=gruvbox ;;
            catppuccin) opencode_theme=catppuccin ;;
            *) opencode_theme=tokyonight ;;
          esac
          tui_json="$HOME/.config/opencode/tui.json"
          if [ -f "$tui_json" ]; then
            python3 - "$tui_json" "$opencode_theme" <<'EOF' 2>/dev/null || true
          import json, sys
          path, theme = sys.argv[1], sys.argv[2]
          with open(path) as f:
              data = json.load(f)
          data["theme"] = theme
          with open(path, "w") as f:
              json.dump(data, f, indent=2)
          EOF
          fi
          # nvim follows the same switch: render base16 from this palette,
          # live-reload any running nvim via the loader's SIGUSR1 handler.
          case "$theme" in
            gruvbox) matugen=${lib.escapeShellArg (nvimBase16 palettes.gruvbox stThemes.gruvbox)} ;;
            catppuccin) matugen=${lib.escapeShellArg (nvimBase16 palettes.catppuccin stThemes.catppuccin)} ;;
            *) matugen=${lib.escapeShellArg (nvimBase16 palettes.tokyonight stThemes.tokyonight)} ;;
          esac
          mkdir -p "$HOME/.config/nvim/lua"
          printf '%s' "$matugen" > "$HOME/.config/nvim/lua/matugen.lua"
          pkill -SIGUSR1 nvim 2>/dev/null || true
          # yazi/btop/bat/starship/fzf follow into per-app "oxwm" slots.
          case "$theme" in
            gruvbox) pal=gruvbox ;;
            catppuccin) pal=catppuccin ;;
            *) pal=tokyonight ;;
          esac
          case "$pal" in
            gruvbox)
              yazi=${lib.escapeShellArg (yaziFlavor palettes.gruvbox)}
              btop=${lib.escapeShellArg (btopTheme palettes.gruvbox)}
              bat=${lib.escapeShellArg (batTmTheme palettes.gruvbox)}
              starship=${lib.escapeShellArg (starshipToml palettes.gruvbox stThemes.gruvbox)}
              fzf=${lib.escapeShellArg (fzfFish palettes.gruvbox)}
              ;;
            catppuccin)
              yazi=${lib.escapeShellArg (yaziFlavor palettes.catppuccin)}
              btop=${lib.escapeShellArg (btopTheme palettes.catppuccin)}
              bat=${lib.escapeShellArg (batTmTheme palettes.catppuccin)}
              starship=${lib.escapeShellArg (starshipToml palettes.catppuccin stThemes.catppuccin)}
              fzf=${lib.escapeShellArg (fzfFish palettes.catppuccin)}
              ;;
            *)
              yazi=${lib.escapeShellArg (yaziFlavor palettes.tokyonight)}
              btop=${lib.escapeShellArg (btopTheme palettes.tokyonight)}
              bat=${lib.escapeShellArg (batTmTheme palettes.tokyonight)}
              starship=${lib.escapeShellArg (starshipToml palettes.tokyonight stThemes.tokyonight)}
              fzf=${lib.escapeShellArg (fzfFish palettes.tokyonight)}
              ;;
          esac
          mkdir -p "$HOME/.config/yazi/flavors/oxwm.yazi" "$HOME/.config/btop/themes" "$HOME/.config/bat/themes"
          printf '%s' "$yazi" > "$HOME/.config/yazi/flavors/oxwm.yazi/flavor.toml"
          printf '[flavor]\ndark = "oxwm"\nlight = "oxwm"\n' > "$HOME/.config/yazi/theme.toml"
          printf '%s' "$btop" > "$HOME/.config/btop/themes/oxwm.theme"
          sed -i 's/^color_theme = .*/color_theme = "oxwm"/' "$HOME/.config/btop/btop.conf" 2>/dev/null || true
          printf '%s' "$bat" > "$HOME/.config/bat/themes/oxwm.tmTheme"
          bat cache --build >/dev/null 2>&1 || true
          printf '%s' "$starship" > "$HOME/.config/starship.toml"
          mkdir -p "$HOME/.config/fish/conf.d"
          printf '%s' "$fzf" > "$HOME/.config/fish/conf.d/oxwm-theme.fish"
          # OBS follows via a generated Yami variant; takes effect on restart.
          case "$pal" in
            gruvbox) obs=${lib.escapeShellArg (obsTheme palettes.gruvbox)} ;;
            catppuccin) obs=${lib.escapeShellArg (obsTheme palettes.catppuccin)} ;;
            *) obs=${lib.escapeShellArg (obsTheme palettes.tokyonight)} ;;
          esac
          mkdir -p "$HOME/.config/obs-studio/themes"
          printf '%s' "$obs" > "$HOME/.config/obs-studio/themes/oxwm.ovt"
          sed -i 's/^Theme=.*/Theme=com.obsproject.oxwm/' "$HOME/.config/obs-studio/user.ini" 2>/dev/null || true
          # LibreOffice follows via a generated theme extension plus scheme
          # selection. unopkg and the registry edit both require LO closed.
          if pgrep -x soffice.bin >/dev/null 2>&1; then
            echo "tutup LibreOffice dulu, lalu oxt $theme lagi untuk temanya" >&2
          else
            case "$pal" in
              gruvbox) looxt=${loOxt palettes.gruvbox} ;;
              catppuccin) looxt=${loOxt palettes.catppuccin} ;;
              *) looxt=${loOxt palettes.tokyonight} ;;
            esac
            unopkg remove dev.oxwm.libreoffice.theme >/dev/null 2>&1 || true
            if unopkg add "$looxt" >/dev/null 2>&1; then
              # Select the scheme by editing the user registry in place with
              # sed: an XML round-trip (e.g. python ElementTree) drops the
              # unused xmlns:xs declaration that oor:type attributes still
              # reference, which makes the file unloadable.
              reg="$HOME/.config/libreoffice/4/user/registrymodifications.xcu"
              if [ -f "$reg" ]; then
                grep -q 'xmlns:xs=' "$reg" || sed -i 's|<oor:items xmlns:oor=|<oor:items xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:oor=|' "$reg"
                if grep -q 'CurrentColorScheme' "$reg"; then
                  sed -i '/CurrentColorScheme/s|<value>[^<]*</value>|<value>oxwm</value>|' "$reg"
                else
                  sed -i 's|</oor:items>|<item oor:path="/org.openoffice.Office.UI/ColorScheme"><prop oor:name="CurrentColorScheme" oor:op="fuse"><value>oxwm</value></prop></item>\n</oor:items>|' "$reg"
                fi
              else
                mkdir -p "$(dirname "$reg")"
                printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema">' '<item oor:path="/org.openoffice.Office.UI/ColorScheme"><prop oor:name="CurrentColorScheme" oor:op="fuse"><value>oxwm</value></prop></item>' '</oor:items>' > "$reg"
              fi
            else
              echo "unopkg gagal; pasang skema LO manual" >&2
            fi
          fi
          if [ -n "''${DISPLAY:-}" ]; then
            xdotool key Super_L+Shift+r
          else
            echo "reload manual: Super+Shift+R" >&2
          fi
        '';
      };

      # Appointment reminders: khal has no daemon, so a timer polls for
      # events starting within 15 minutes and notifies once per event (state
      # files in the runtime dir vanish on reboot, re-arming everything).
      khalRemind = pkgs.writeShellApplication {
        name = "khal-remind";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.khal
          pkgs.libnotify
        ];
        text = ''
          state="''${XDG_RUNTIME_DIR:-/tmp}/khal-notified"
          mkdir -p "$state"
          now=$(date +%s)
          limit=$((now + 900))
          khal list --format "{start-time} | {title}" today --notstarted 2>/dev/null | while IFS= read -r line; do
            case "$line" in
              *"|"*) ;;
              *) continue ;;
            esac
            start="''${line%% | *}"
            title="''${line#* | }"
            epoch=$(date -d "$start" +%s 2>/dev/null) || continue
            [ "$epoch" -le "$limit" ] || continue
            [ "$epoch" -ge "$now" ] || continue
            id=$(printf '%s' "$line" | sha256sum | cut -d' ' -f1)
            [ -f "$state/$id" ] && continue
            notify-send "Calendar" "$title" || true
            touch "$state/$id"
          done || true
        '';
      };
    in
    {
      # Whole upstream repo is the config, keybinds included; st is its
      # `set_terminal` default. Entries are linked individually (never the
      # directory itself): a recursive parent silently wins over an explicit
      # child override. Subdirectories link recursively for the same reason:
      # files placed beneath a unit-symlinked dir resolve outside $HOME.
      xdg.configFile =
        lib.mapAttrs' (
          name: type:
          lib.nameValuePair "oxwm/${name}" (
            if type == "directory" then
              {
                source = "${repo}/${name}";
                recursive = true;
              }
            else
              {
                source = "${repo}/${name}";
              }
          )
        ) (lib.filterAttrs (name: _: name != "config.lua") (builtins.readDir repo))
        // {
          "oxwm/config.lua".source = finalConfig;

          # Static selector for the bat theme oxt renders (themes/oxwm.tmTheme).
          "bat/config".text = "--theme=\"oxwm\"\n";

          "oxwm/colors/tokyonight.lua".text = luaPalette palettes.tokyonight;
          "oxwm/colors/gruvbox.lua".text = luaPalette palettes.gruvbox;
          "oxwm/colors/catppuccin.lua".text = luaPalette palettes.catppuccin;

          "oxwm/dunstrc-tokyonight".text = dunstCfg palettes.tokyonight;
          "oxwm/dunstrc-gruvbox".text = dunstCfg palettes.gruvbox;
          "oxwm/dunstrc-catppuccin".text = dunstCfg palettes.catppuccin;

          "oxwm/wallpapers/tokyonight.jpg".source = "${wallpapers}/tokyonight/wallhaven-yqeoyx.jpg";
          "oxwm/wallpapers/gruvbox.png".source = "${wallpapers}/gruvbox/The_Backwater.png";
          "oxwm/wallpapers/catppuccin.jpg".source =
            "${wallpapers}/catppuccin/wallhaven-9o2g8k-catppuccin-mocha.jpg";

          "khal/config".text = ''
            [calendars]
                [[home]]
                    path = ~/.calendars/home
                    color = light blue
                [[google-personal]]
                    path = ~/.calendars/google-personal
                    color = light green
                [[google-family]]
                    path = ~/.calendars/google-family
                    color = yellow
                [[google-holidays]]
                    path = ~/.calendars/google-holidays
                    color = light magenta
                [[f1]]
                    path = ~/.calendars/f1
                    color = light cyan
                [[manutd]]
                    path = ~/.calendars/manutd
                    color = light red
            [default]
                default_calendar = home
                highlight_event_days = True
            [locale]
                timeformat = "%H:%M"
                dateformat = "%d/%m/%Y"
                longdateformat = "%d/%m/%Y"
                datetimeformat = "%d/%m/%Y %H:%M"
                longdatetimeformat = "%d/%m/%Y %H:%M"
            [highlight_days]
                default_color = yellow
          '';

          "oxwm/wifi-status.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              # Prints "Wifi: <SSID>" or "Wifi: off" for the oxwm bar.
              # NOTE: `nmcli dev wifi` triggers a radio rescan (up to seconds
              # of stall on oxwm's main loop); `device status` only reads
              # NetworkManager state, never touching the radio.
              ssid=$(nmcli -t -f TYPE,CONNECTION device status 2>/dev/null | sed -n 's/^wifi://p' | head -n 1)
              if [ -n "$ssid" ]; then
                printf 'Wifi: %s\n' "$ssid"
              else
                printf 'Wifi: off\n'
              fi
            '';
          };

          "oxwm/bluetooth-status.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              # Prints "BT: on" or "BT: off" for the oxwm bar.
              if bluetoothctl show 2>/dev/null | grep -qi 'Powered: yes'; then
                printf 'BT: on\n'
              else
                printf 'BT: off\n'
              fi
            '';
          };

          "oxwm/cpu-status.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              # Prints "Cpu: NN%" from /proc/stat jiffies vs the last run.
              # First run only stores a snapshot and prints nothing.
              state="''${XDG_RUNTIME_DIR:-/tmp}/cpu-jiffies"
              read -r _ u n s id io ir so _rest < /proc/stat
              total=$((u + n + s + id + io + ir + so))
              idle=$((id + io))
              if [ -f "$state" ]; then
                read -r pt pi < "$state"
                dt=$((total - pt))
                di=$((idle - pi))
                if [ "$dt" -gt 0 ]; then printf 'Cpu: %d%%\n' "$(( 100 * (dt - di) / dt ))"; fi
              fi
              printf '%s %s\n' "$total" "$idle" > "$state"
            '';
          };

          "oxwm/temp-status.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              # Prints the hottest thermal zone, e.g. "Temp: 52°C".
              # NOTE: shell builtins only (no `cat` fork per zone) — this runs
              # synchronously on oxwm's main loop, so every forked process
              # here is input latency for the whole session.
              best=0
              for f in /sys/class/thermal/thermal_zone*/temp; do
                [ -r "$f" ] || continue
                IFS= read -r t < "$f" || continue
                case "$t" in
                  *[!0-9]*|"") continue ;;
                esac
                [ "$t" -gt "$best" ] && best=$t
              done
              [ "$best" -gt 0 ] || exit 0
              printf 'Temp: %d°C\n' "$((best / 1000))"
            '';
          };

          "oxwm/volume-status.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              # Prints "Vol: NN%" or "MUTED" for the oxwm bar. oxwm draws each
              # block in one static color (no markup/ANSI), so the state shows
              # in the text itself.
              vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || exit 0
              case "$vol" in
                *MUTED*) printf 'MUTED\n' ;;
                Volume:*) printf 'Vol: %d%%\n' "$(printf '%s' "$vol" | awk '{printf "%d", $2 * 100}')" ;;
              esac
            '';
          };

          "oxwm/mic-status.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              # Prints "Mic: live" or "Mic: muted" for notifications.
              vol=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null) || exit 0
              case "$vol" in
                *MUTED*) printf 'Mic: muted\n' ;;
                Volume:*) printf 'Mic: live\n' ;;
              esac
            '';
          };

          "oxwm/brightness-status.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              # Prints "Bright: NN%" for notifications.
              for dev in /sys/class/backlight/*; do
                [ -r "$dev/brightness" ] && [ -r "$dev/max_brightness" ] || continue
                cur=$(cat "$dev/brightness")
                max=$(cat "$dev/max_brightness")
                [ "''${max:-0}" -gt 0 ] 2>/dev/null || continue
                printf 'Bright: %d%%\n' "$(( 100 * cur / max ))" && exit 0
              done
              exit 0
            '';
          };
        };

      home.file.".calendars/home/.keep".text = "";

      # Session bootstrap for startx: getty autologin on tty1 runs the login
      # shell, which execs startx, which runs this. HM-managed so layout and
      # WM stay in sync with the rest of the config.
      home.file.".xinitrc" = {
        executable = true;
        text = ''
          #!/bin/sh
          ${pkgs.xorg.setxkbmap}/bin/setxkbmap ${constants.layout} 2>/dev/null || true
          exec oxwm
        '';
      };

      # Seeded once; later edits survive switches because of the guard.
      home.activation.seedOxwmTheme = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        themeFile="$HOME/.config/oxwm/theme"
        if [ ! -f "$themeFile" ]; then
          echo "tokyonight" > "$themeFile"
        fi
      '';

      # vdirsyncer config is seeded once as a real file (never a store
      # symlink): OAuth identifiers must stay out of the Nix store, and
      # `discover` writes found collections back into it. Every content line
      # sits at column 0: vdirsyncer reads indented lines as continuations
      # of the previous value (config parse error).
      home.activation.seedVdirsyncer = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        cfgFile="$HOME/.config/vdirsyncer/config"
        if [ ! -f "$cfgFile" ]; then
          mkdir -p "$HOME/.config/vdirsyncer"
          # Strip indentation: vdirsyncer reads indented lines as
          # continuations, so the seed is whitespace-proof either way.
          sed 's/^ *//' > "$cfgFile" <<'EOF'
        [general]
        status_path = "~/.local/share/vdirsyncer/status/"

          [pair google_sync]
          a = "local"
          b = "remote"
          collections = ["from b"]

        [storage local]
        type = "filesystem"
        path = "~/.calendars/"
        fileext = ".ics"

        [storage remote]
        type = "google_calendar"
        client_id = ""
        client_secret = ""
        token_file = "~/.vdirsyncer-tokens"
        EOF
                fi
      '';

      # Appointment reminders poll via the timer below; see khalRemind above.
      systemd.user.services.khal-remind = {
        Unit.Description = "khal appointment reminders";
        Service = {
          Type = "oneshot";
          ExecStart = "${khalRemind}/bin/khal-remind";
        };
      };

      systemd.user.timers.khal-remind = {
        Unit.Description = "Check upcoming appointments every few minutes";
        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "5min";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      # Push/pull CalDAV both ways; failures (offline, unconfigured) just
      # retry next round, so an empty template config is harmless.
      systemd.user.services.vdirsyncer = {
        Unit.Description = "Sync calendars with CalDAV";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.vdirsyncer}/bin/vdirsyncer sync";
        };
      };

      systemd.user.timers.vdirsyncer = {
        Unit.Description = "Sync calendars every 10 minutes";
        Timer = {
          OnBootSec = "2min";
          OnUnitActiveSec = "10min";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      # Clipboard history collector. A user service rather than an oxwm
      # autostart child, so WM reloads can't kill it; Restart covers the
      # login race where X isn't up yet when the user manager starts it.
      systemd.user.services.clipmenud = {
        Unit.Description = "Clipboard history collector";
        Service = {
          ExecStart = "${pkgs.clipmenu}/bin/clipmenud";
          Environment = [
            "DISPLAY=:0"
            # Default CM_DIR is under /tmp (wiped on reboot); keep history
            # on disk so it survives. Must match the Mod+V binding below.
            "CM_DIR=%h/.cache/clipmenu"
          ];
          Restart = "on-failure";
          RestartSec = "3s";
        };
        Install.WantedBy = [ "default.target" ];
      };

      # oxwm spawns these by bare name. st/rofi resolve through the themed
      # dispatchers above; maim -s execs slop the same way, so the selector
      # has to be on PATH too, not just in maim's closure.
      home.packages = [
        (mkThemedSt "tokyonight" stThemes.tokyonight)
        (mkThemedSt "gruvbox" stThemes.gruvbox)
        (mkThemedSt "catppuccin" stThemes.catppuccin)
        stLauncher
        dmenuRun
        dmenuThemed
        dunstLauncher
        oxwmThemeCmd
        pkgs.bluetui
        pkgs.libnotify
      ]
      ++ (with pkgs; [
        brightnessctl
        khal
        clipmenu
        maim
        slop
        vdirsyncer
        wiremix
        xclip
        feh
      ]);
    };
}
