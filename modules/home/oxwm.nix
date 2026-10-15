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

      # Single source of truth for themes: the palette every renderer uses,
      # the st ANSI ramp, the wallpaper link, and the oxt name aliases.
      # Adding a theme is one entry here; dispatch tables below generate
      # themselves from it (theme_names, wallpaper map, wrapper arms, oxt).
      themes = {
        tokyonight = {
          aliases = [
            "tok"
            "t"
          ];
          wallpaper = {
            file = "tokyonight.jpg";
            src = "tokyonight/wallhaven-yqeoyx.jpg";
          };
          palette = {
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
            accent = "#6dade3";
          };
          st = {
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
        };
        gruvbox = {
          aliases = [
            "gruv"
            "g"
          ];
          wallpaper = {
            file = "gruvbox.png";
            src = "gruvbox/The_Backwater.png";
          };
          palette = {
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
            accent = "#fe8019";
          };
          st = {
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
        };
        catppuccin = {
          aliases = [
            "cat"
            "c"
          ];
          wallpaper = {
            file = "catppuccin.jpg";
            src = "catppuccin/wallhaven-9o2g8k-catppuccin-mocha.jpg";
          };
          palette = {
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
            accent = "#cba6f7";
          };
          st = {
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
      };

      palettes = lib.mapAttrs (_: t: t.palette) themes;
      themeNames = builtins.attrNames themes;
      defaultTheme = "tokyonight";

      luaPalette =
        p:
        "return {\n"
        + lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "    ${k} = \"${v}\";") p)
        + "\n}\n";

      # Generated into the border's per-theme lookup, so each palette names its
      # accent once instead of in a hand-kept Lua table.
      paletteAccents = lib.concatStringsSep ", " (
        lib.mapAttrsToList (name: p: "${name} = \"${p.accent}\"") palettes
      );

      # oxwm only positions floating windows, never sizes them, so -g on the
      # spawned st is the only lever on how big a bar-click popup opens.
      popupGeom = "110x32";

      # The bar, generated so every block carries its own color, the clock
      # sits last (rightmost), and wifi/bluetooth open floating TUIs on click.
      blocksLua = ''
        local blocks = {
            oxwm.bar.block.ram({
                format = "Ram: {used}/{total} GB",
                interval = 5,
                color = colors.purple,
                underline = true,
                click = { command = "st -g ${popupGeom} -e btop", floating = true },
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
                click = { command = "st -g ${popupGeom} -e btop", floating = true },
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
                click = { command = "st -g ${popupGeom} -e btop", floating = true },
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
                click = { command = "st -g ${popupGeom} -e nmtui", floating = true },
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
                click = { command = "st -g ${popupGeom} -e bluetui", floating = true },
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
                click = { command = "st -g ${popupGeom} -e ikhal", floating = true },
            }),
        };
      '';

      themeLoader =
        let
          known = lib.concatStringsSep ", " (map (n: "${n} = true") themeNames);
        in
        ''
          local theme_names = { ${known} }
          local theme = "${defaultTheme}"
          local theme_file = io.open(os.getenv("HOME") .. "/.config/oxwm/theme", "r")
          if theme_file then
            local wanted = (theme_file:read("*l") or ""):match("^%s*(.-)%s*$")
            theme_file:close()
            if theme_names[wanted] then theme = wanted end
          end
          local colors = require("colors." .. theme);'';

      wallpaperBlock =
        let
          entries = lib.mapAttrsToList (
            n: t: ''${n} = os.getenv("HOME") .. "/.config/oxwm/wallpapers/${t.wallpaper.file}",''
          ) themes;
        in
        ''
          local hp_wallpapers = {
            ${lib.concatStringsSep "\n  " entries}
          }
          oxwm.autostart("feh --bg-fill " .. hp_wallpapers[theme])'';

      firefoxBind = ''oxwm.key.bind({ modkey }, "B", oxwm.spawn({ "sh", "-c", "firefox" }))'';

      # One shape for the three file captures: file + clipboard +
      # notification. The quick region shot skips the file.
      mkShot =
        suffix: capture:
        ''mkdir -p ~/Pictures/Screenshots && f=~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S)${suffix}.png && ${capture} "$f" && xclip -selection clipboard -t image/png < "$f" && notify-send "Screenshot saved" "$f"'';
      screenshotCmd = mkShot "" "maim -s";
      screenshotFullCmd = mkShot "-full" "maim";
      screenshotWindowCmd = mkShot "-window" "maim -i $(xdotool getactivewindow)";
      screenshotQuickCmd = "maim -s | xclip -selection clipboard -t image/png";

      dunstctl = "${pkgs.dunst}/bin/dunstctl";
      wifiToggle = ''st=$(nmcli -t -f WIFI g | grep -q enabled && echo off || echo on); nmcli radio wifi "$st"; notify-send -h string:x-dunst-stack-tag:osd "Wifi" "$st"'';
      btToggle = ''st=$(bluetoothctl show 2>/dev/null | grep -qi 'Powered: yes' && echo off || echo on); bluetoothctl power "$st"; notify-send -h string:x-dunst-stack-tag:osd "Bluetooth" "$st"'';
      dndToggle = ''if ${dunstctl} is-paused | grep -q true; then ${dunstctl} set-paused false; st=off; else ${dunstctl} set-paused true; st=on; fi; notify-send -h string:x-dunst-stack-tag:osd "DND" "$st"'';
      notifRecall = "${dunstctl} history-pop";

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
          local focus_colors = { ${paletteAccents} }
          oxwm.border.set_focused_color(focus_colors[theme] or colors.accent)'')
        (repl ''local bar_font = "JetBrainsMono Nerd Font Propo:style=Bold:size=12"'' ''local bar_font = "JetBrainsMono Nerd Font Propo:style=Bold:size=10"'')
        (repl ''oxwm.key.bind({ modkey }, "S", oxwm.spawn({ "sh", "-c", "maim -s | xclip -selection clipboard -t image/png" }))'' ''
          oxwm.key.bind({ modkey }, "S", oxwm.spawn({ "sh", "-c", [[${screenshotQuickCmd}]] }))
          -- Screenshots to file: region, active window, full screen
          oxwm.key.bind({}, "Print", oxwm.spawn({ "sh", "-c", [[${screenshotCmd}]] }))
          oxwm.key.bind({ "Shift" }, "Print", oxwm.spawn({ "sh", "-c", [[${screenshotWindowCmd}]] }))
          oxwm.key.bind({ "Control" }, "Print", oxwm.spawn({ "sh", "-c", [[${screenshotFullCmd}]] }))
          -- Radios and notifications
          oxwm.key.bind({ modkey, "Shift" }, "W", oxwm.spawn({ "sh", "-c", [[${wifiToggle}]] }))
          oxwm.key.bind({ modkey, "Shift" }, "U", oxwm.spawn({ "sh", "-c", [[${btToggle}]] }))
          oxwm.key.bind({ modkey, "Shift" }, "D", oxwm.spawn({ "sh", "-c", [[${dndToggle}]] }))
          oxwm.key.bind({ modkey, "Shift" }, "N", oxwm.spawn({ "sh", "-c", [[${notifRecall}]] }))'')
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

      # Recolor yazi's upstream default theme (theme-dark.toml) with the active
      # oxwm palette: map the 17 named ANSI colors to palette slots. `oxt`
      # writes this as ~/.config/yazi/theme.toml.
      yaziTheme =
        p:
        lib.replaceStrings
          [
            "\"lightred\""
            "\"lightgreen\""
            "\"lightyellow\""
            "\"lightcyan\""
            "\"lightblue\""
            "\"lightmagenta\""
            "\"darkgray\""
            "\"reset\""
            "\"black\""
            "\"white\""
            "\"red\""
            "\"green\""
            "\"yellow\""
            "\"blue\""
            "\"magenta\""
            "\"cyan\""
            "\"gray\""
          ]
          [
            "\"${p.red}\""
            "\"${p.green}\""
            "\"${p.yellow}\""
            "\"${p.cyan}\""
            "\"${p.light_blue}\""
            "\"${p.lavender}\""
            "\"${p.grey}\""
            "\"reset\""
            "\"${p.bg}\""
            "\"${p.fg}\""
            "\"${p.red}\""
            "\"${p.green}\""
            "\"${p.yellow}\""
            "\"${p.blue}\""
            "\"${p.purple}\""
            "\"${p.cyan}\""
            "\"${p.grey}\""
          ]
          (builtins.readFile ./yazi-theme-dark.toml);

      mkThemedSt =
        name: t:
        pkgs.st.overrideAttrs (old: {
          pname = "st-${name}";
          # Vanilla st has no scrollback buffer at all: any output longer
          # than the window is unrecoverable. Shift+PageUp/PageDown scroll.
          patches = (old.patches or [ ]) ++ [
            (pkgs.fetchpatch {
              url = "https://st.suckless.org/patches/scrollback/st-scrollback-0.9.2.diff";
              hash = "sha256-jbY7+D3wbLoSzbAuV4y0mvx4nHJrTIX2bpWzclYrrHo=";
            })
          ];
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

      dmenuFlags =
        t:
        ''-nb "${t.bg}" -nf "${t.fg}" -sb "${t.blue}" -sf "${t.bg}" -fn "${constants.monoFont}:size=10"'';

      # One dispatch shape for every bare-name wrapper oxwm spawns: read the
      # theme file, run that theme's command, fall back to the default.
      themeDispatch =
        name: forTheme:
        pkgs.writeShellScriptBin name ''
          theme=$(cat "$HOME/.config/oxwm/theme" 2>/dev/null || echo ${defaultTheme})
          theme="''${theme//[[:space:]]/}"
          case "$theme" in
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (n: _: "${n}) ${forTheme n} ;;") themes)}
            *) ${forTheme defaultTheme} ;;
          esac
        '';

      # oxwm spawns "st" by bare name; this dispatches to the themed build
      # matching the active theme file, same source of truth as the palette.
      stLauncher = themeDispatch "st" (t: ''exec st-${t} "$@"'');

      # Same dispatch for notifications: one dunstrc per theme. dunst is
      # autostarted by oxwm and re-reads nothing on its own, so oxt restarts
      # it on every switch.
      dunstLauncher = themeDispatch "dunst" (
        t: ''exec ${pkgs.dunst}/bin/dunst -config "$HOME/.config/oxwm/dunstrc-${t}"''
      );

      # Upstream binds Mod+D to `dmenu_run -l 10`; this wrapper only adds
      # theme colors (dmenu_run itself builds the executable list).
      # dmenu-themed is for piped custom menus (power, session): plain dmenu
      # reads stdin, so unlike dmenu_run it shows exactly what it is given.
      dmenuRun = themeDispatch "dmenu_run" (
        t: ''exec ${pkgs.dmenu}/bin/dmenu_run ${dmenuFlags palettes.${t}} "$@"''
      );
      dmenuThemed = themeDispatch "dmenu-themed" (
        t: ''exec ${pkgs.dmenu}/bin/dmenu ${dmenuFlags palettes.${t}} "$@"''
      );

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

      # LibreOffice theme extension: static packaging files plus a generated
      # color scheme. `oxt` installs the .oxt with unopkg (constant extension
      # id, so reinstalls overwrite), then selects the scheme in the user
      # registry.
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

      loPkgDesc = "oxwm application colors for LibreOffice, generated from the oxwm palettes.\n";

      loScheme =
        name: p:
        let
          dec = h: toString (lib.fromHexString (lib.removePrefix "#" h));
        in
        ''
          <node oor:name="${name}" oor:op="fuse">
                  <node oor:name="AppBackground"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.bg)}</value></prop></node>
                  <node oor:name="DocColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.bg)}</value></prop></node>
                  <node oor:name="FontColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.fg)}</value></prop></node>
                  <node oor:name="DocBoundaries"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="WindowColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.bg)}</value></prop></node>
                  <node oor:name="WindowTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.fg)}</value></prop></node>
                  <node oor:name="BaseColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.bg)}</value></prop></node>
                  <node oor:name="ButtonColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="ButtonTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.fg)}</value></prop></node>
                  <node oor:name="AccentColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.orange)}</value></prop></node>
                  <node oor:name="DisabledColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="DisabledTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.grey)}</value></prop></node>
                  <node oor:name="ShadowColor"><prop oor:name="Color" oor:op="fuse"><value>0</value></prop></node>
                  <node oor:name="Shadow"><prop oor:name="Color" oor:op="fuse"><value xsi:nil="false" /></prop><prop oor:name="IsVisible" oor:op="fuse"><value>false</value></prop></node>
                  <node oor:name="SeparatorColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="FaceColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="ActiveColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.orange)}</value></prop></node>
                  <node oor:name="ActiveTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.bg)}</value></prop></node>
                  <node oor:name="ActiveBorderColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.orange)}</value></prop></node>
                  <node oor:name="FieldColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="MenuBarColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="MenuBarTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.fg)}</value></prop></node>
                  <node oor:name="MenuBarHighlightColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.orange)}</value></prop></node>
                  <node oor:name="MenuBarHighlightTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.bg)}</value></prop></node>
                  <node oor:name="MenuColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="MenuTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.fg)}</value></prop></node>
                  <node oor:name="MenuHighlightColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.orange)}</value></prop></node>
                  <node oor:name="MenuHighlightTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.bg)}</value></prop></node>
                  <node oor:name="MenuBorderColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="InactiveColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="InactiveTextColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.grey)}</value></prop></node>
                  <node oor:name="InactiveBorderColor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  <node oor:name="BASICEditor"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.bg)}</value></prop></node>
                  <node oor:name="BASICError"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.red)}</value></prop></node>
                  <node oor:name="BASICIdentifier"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.fg)}</value></prop></node>
                  <node oor:name="BASICKeyword"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.purple)}</value></prop></node>
                  <node oor:name="BASICNumber"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.orange)}</value></prop></node>
                  <node oor:name="BASICOperator"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.yellow)}</value></prop></node>
                  <node oor:name="BASICString"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.green)}</value></prop></node>
                  <node oor:name="BASICComment"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.grey)}</value></prop></node>
                  <node oor:name="WriterIdxShadings"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop><prop oor:name="IsVisible" oor:op="fuse"><value>true</value></prop></node>
                  <node oor:name="WriterFieldShadings"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop><prop oor:name="IsVisible" oor:op="fuse"><value>true</value></prop></node>
                  <node oor:name="CalcGrid"><prop oor:name="Color" oor:op="fuse"><value>${toString (dec p.sep)}</value></prop></node>
                  </node>
        '';

      # One extension carries every palette so the LO Appearance list can offer
      # all three; `oxt` only changes which one is selected.
      loThemeColors = builtins.concatStringsSep "\n" [
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        "<oor:component-data xmlns:oor=\"http://openoffice.org/2001/registry\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" oor:name=\"UI\" oor:package=\"org.openoffice.Office\">"
        "<node oor:name=\"ColorScheme\">"
        "<node oor:name=\"ColorSchemes\">"
        (loScheme "tokyonight" palettes.tokyonight)
        (loScheme "gruvbox" palettes.gruvbox)
        (loScheme "catppuccin" palettes.catppuccin)
        "</node>"
        "</node>"
        "</oor:component-data>"
      ];

      loOxt = pkgs.runCommand "oxwm-libreoffice-theme.oxt" { nativeBuildInputs = [ pkgs.zip ]; } ''
        work=$(mktemp -d)
        mkdir -p "$work/oxwm/META-INF"
        printf '%s' ${lib.escapeShellArg loManifest} > "$work/oxwm/META-INF/manifest.xml"
        printf '%s' ${lib.escapeShellArg loDescription} > "$work/oxwm/description.xml"
        printf '%s' ${lib.escapeShellArg loPaths} > "$work/oxwm/Paths.xcu"
        printf '%s' ${lib.escapeShellArg loPkgDesc} > "$work/oxwm/pkg-description.en"
        printf '%s' ${lib.escapeShellArg loThemeColors} > "$work/oxwm/Theme_Colors.xcu"
        ( cd "$work/oxwm" && zip -qr "$out" . )
      '';

      # Every file `oxt` installs, rendered once per theme at build time.
      # Switching then copies files instead of re-rendering, so a broken
      # template fails the build rather than a live switch.
      themeFiles = lib.mapAttrs (
        name: t:
        pkgs.runCommand "oxwm-theme-${name}" { } ''
          mkdir -p $out
          printf '%s' ${lib.escapeShellArg (btopTheme t.palette)} > $out/btop.theme
          printf '%s' ${lib.escapeShellArg (batTmTheme t.palette)} > $out/bat.tmTheme
          printf '%s' ${lib.escapeShellArg (starshipToml t.palette t.st)} > $out/starship.toml
          printf '%s' ${lib.escapeShellArg (fzfFish t.palette)} > $out/oxwm-theme.fish
          printf '%s' ${lib.escapeShellArg (obsTheme t.palette)} > $out/obs.ovt
          printf '%s' ${lib.escapeShellArg (nvimBase16 t.palette t.st)} > $out/matugen.lua
          printf '%s' ${lib.escapeShellArg (yaziTheme t.palette)} > $out/theme.toml
        ''
      ) themes;

      # One-word theme switching: writes the theme file, then installs the
      # pre-rendered files for that theme (see themeFiles above).
      oxwmThemeCmd = pkgs.writeShellApplication {
        name = "oxt";
        runtimeInputs = [
          pkgs.bat
          pkgs.feh
          pkgs.jq
          pkgs.libreoffice
          pkgs.xdotool
          pkgs.procps
        ];
        text = ''
          case "''${1:-}" in
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (n: t: "${n}|${lib.concatStringsSep "|" t.aliases}) theme=${n} ;;") themes
          )}
            *)
              echo "pakai: oxt {${
                lib.concatStringsSep "|" (
                  lib.mapAttrsToList (n: t: "${n}(${lib.concatStringsSep "," t.aliases})") themes
                )
              }}" >&2
              exit 2
              ;;
          esac
          declare -A theme_dir=(
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (n: d: "[${n}]=${d}") themeFiles)}
          )
          src="''${theme_dir[$theme]}"
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
          tui_json="$HOME/.config/opencode/tui.json"
          if [ -f "$tui_json" ]; then
            jq --arg theme "$theme" '.theme = $theme' "$tui_json" > "$tui_json.tmp" \
              && mv "$tui_json.tmp" "$tui_json" || true
          fi
          mkdir -p "$HOME/.config/nvim/lua" "$HOME/.config/btop/themes" "$HOME/.config/bat/themes" \
            "$HOME/.config/fish/conf.d" "$HOME/.config/obs-studio/themes"
          # nvim follows the same switch; the loader's SIGUSR1 handler
          # re-requires matugen.lua live in any running nvim.
          cp "$src/matugen.lua" "$HOME/.config/nvim/lua/matugen.lua"
          pkill -SIGUSR1 nvim 2>/dev/null || true
          # yazi reads $src/theme.toml directly; wipe legacy flavor dirs.
          rm -rf "$HOME/.config/yazi/flavors"
          cp "$src/theme.toml" "$HOME/.config/yazi/theme.toml"
          cp "$src/btop.theme" "$HOME/.config/btop/themes/oxwm.theme"
          sed -i 's/^color_theme = .*/color_theme = "oxwm"/' "$HOME/.config/btop/btop.conf" 2>/dev/null || true
          cp "$src/bat.tmTheme" "$HOME/.config/bat/themes/oxwm.tmTheme"
          bat cache --build >/dev/null 2>&1 || true
          cp "$src/starship.toml" "$HOME/.config/starship.toml"
          cp "$src/oxwm-theme.fish" "$HOME/.config/fish/conf.d/oxwm-theme.fish"
          # OBS follows via a generated Yami variant; takes effect on restart.
          cp "$src/obs.ovt" "$HOME/.config/obs-studio/themes/oxwm.ovt"
          sed -i 's/^Theme=.*/Theme=com.obsproject.oxwm/' "$HOME/.config/obs-studio/user.ini" 2>/dev/null || true
          # LibreOffice follows via a generated theme extension plus scheme
          # selection. unopkg and the registry edit both require LO closed.
          if pgrep -x soffice.bin >/dev/null 2>&1; then
            echo "tutup LibreOffice dulu, lalu oxt $theme lagi untuk temanya" >&2
          else
            looxt=${loOxt}
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
                  sed -i "/CurrentColorScheme/s|<value>[^<]*</value>|<value>$theme</value>|" "$reg"
                else
                  sed -i "s|</oor:items>|<item oor:path=\"/org.openoffice.Office.UI/ColorScheme\"><prop oor:name=\"CurrentColorScheme\" oor:op=\"fuse\"><value>$theme</value></prop></item>\\n</oor:items>|" "$reg"
                fi
              else
                mkdir -p "$(dirname "$reg")"
                  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<oor:items xmlns:oor="http://openoffice.org/2001/registry" xmlns:xs="http://www.w3.org/2001/XMLSchema">' "<item oor:path=\"/org.openoffice.Office.UI/ColorScheme\"><prop oor:name=\"CurrentColorScheme\" oor:op=\"fuse\"><value>$theme</value></prop></item>" '</oor:items>' > "$reg"
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
        }
        // lib.listToAttrs (
          lib.mapAttrsToList (
            n: t: lib.nameValuePair "oxwm/colors/${n}.lua" { text = luaPalette t.palette; }
          ) themes
        )
        // lib.listToAttrs (
          lib.mapAttrsToList (
            n: t: lib.nameValuePair "oxwm/dunstrc-${n}" { text = dunstCfg t.palette; }
          ) themes
        )
        // lib.listToAttrs (
          lib.mapAttrsToList (
            _: t:
            lib.nameValuePair "oxwm/wallpapers/${t.wallpaper.file}" {
              source = ../../wallpapers + "/${t.wallpaper.src}";
            }
          ) themes
        )
        // {

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
          ${pkgs.setxkbmap}/bin/setxkbmap ${constants.layout} 2>/dev/null || true
          # startx provides no session bus or user-manager env of its own;
          # without these, D-Bus-activated apps and user services start blind.
          systemctl --user import-environment DISPLAY XAUTHORITY 2>/dev/null || true
          if command -v dbus-update-activation-environment >/dev/null 2>&1; then
            dbus-update-activation-environment DISPLAY XAUTHORITY 2>/dev/null || true
          fi
          exec oxwm
        '';
      };

      # Seeded once; later edits survive switches because of the guard.
      home.activation.seedThemes = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        themeFile="$HOME/.config/oxwm/theme"
        if [ ! -f "$themeFile" ]; then
          echo "${defaultTheme}" > "$themeFile"
        fi
        # Seed the default palette's recolored yazi theme.toml; edits survive
        # later switches.
        selector="$HOME/.config/yazi/theme.toml"
        if [ ! -f "$selector" ]; then
          mkdir -p "$HOME/.config/yazi"
          cp ${themeFiles.${defaultTheme}}/theme.toml "$selector"
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

      # Only artifacts built from module data live here (themed st builds
      # and dispatchers); every bare tool is in home/packages.nix.
      home.packages = lib.mapAttrsToList (n: t: mkThemedSt n t.st) themes ++ [
        stLauncher
        dmenuRun
        dmenuThemed
        dunstLauncher
        oxwmThemeCmd
      ];
    };
}
