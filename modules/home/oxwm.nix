{
  flake.homeManagerModules.oxwm =
    {
      config,
      inputs,
      pkgs,
      lib,
      constants,
      ...
    }:
    let
      repo = inputs."oxwm-config";

      themes = config.oxwm.themes;
      defaultTheme = config.oxwm.defaultTheme;
      themeNames = builtins.attrNames themes;

      # Generated into the border's per-theme lookup, so each palette names its
      # accent once instead of in a hand-kept Lua table.
      paletteAccents = lib.concatStringsSep ", " (
        lib.mapAttrsToList (name: t: "${name} = \"${t.palette.accent}\"") themes
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
            oxwm.bar.block.shell({
                format = "{}",
                command = "$HOME/.config/oxwm/bat-status.sh",
                interval = 10,
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

      # Shown by Mod+Shift+/ in a floating st pager. oxwm's built-in overlay
      # is compiled in (fixed 12-line priority-action list, one bind per
      # action), so the complete list lives in this file instead.
      keybindsDoc = ''
        oxwm keybindings                       (Super = mod key)

        Window management
          Super+Return          open terminal
          Super+Q               kill focused window
          Super+Shift+Q         quit oxwm
          Super+Shift+R         restart oxwm
          Super+Shift+Space     toggle floating
          Super+Shift+F         toggle fullscreen
          Super+A               toggle gaps

        Launch
          Super+D               app launcher (dmenu)
          Super+B               firefox
          Super+E               yazi (file manager)
          Super+V               clipboard history (clipmenu)
          Super+Shift+V         wiremix (audio mixer)
          Super+W               nmtui (network)
          Super+U               bluetui (bluetooth)
          Super+Y               ikhal (calendar)
          Super+Shift+B         btop (system monitor)
          Super+O               ocr-copy (screen text)
          Super+Shift+O         opencode

        Screenshots
          Super+S               region to clipboard
          Print                 region to file
          Shift+Print           active window to file
          Ctrl+Print            full screen to file

        Radios / notifications
          Super+Shift+W         toggle wifi
          Super+Shift+U         toggle bluetooth
          Super+Shift+D         toggle do-not-disturb
          Super+Shift+N         recall last notification

        Media / hardware keys
          Super+M               toggle mic mute
          Super+Shift+P         power profile (saver/balanced/performance)
          Super+Escape          power menu
          XF86 keys             volume and brightness (+/- 5%)

        Layout / focus
          Super+C               tiling layout
          Super+N               cycle layout
          Super+H / Super+L     master width -/+ 5
          Super+I / Super+P     more / fewer master windows
          Super+J / Super+K     focus next / previous window
          Super+Shift+J / K     move window next / previous

        Monitors
          Super+, / Super+.             focus monitor
          Super+Shift+, / Super+Shift+. move window to monitor

        Tags
          Super+1..9                    view tag
          Super+Shift+1..9              move window to tag
          Super+Ctrl+1..9               toggle tag view
          Super+Ctrl+Shift+1..9         toggle tag with window

        Keychords (press, release, then the second key)
          Super+Space then T            open terminal
          Super+F then B                bookmarks
          Super+F then F                repos
          Super+F then O                tmux sessions

          Super+Shift+/                 this list (less: q to close)
      '';

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
        (repl ''oxwm.key.bind({ modkey, "Shift" }, "Slash", oxwm.show_keybinds())'' ''oxwm.key.bind({ modkey, "Shift" }, "Slash", oxwm.spawn({ "sh", "-c", "st -n keybinds -c keybinds -g ${popupGeom} -e less $HOME/.config/oxwm/keybinds.txt" }))'')
        (repl ''-- oxwm.autostart("xwallpaper --zoom ~/walls/dune.jpg")'' ''
                    -- oxwm.autostart("xwallpaper --zoom ~/walls/dune.jpg")
          ${wallpaperBlock}'')
        (repl ''-- oxwm.autostart("dunst")'' ''
          oxwm.autostart("dunst")
          -- clipmenud runs as a systemd user service below, so WM reloads
          -- can't orphan it the way autostart children get orphaned.'')
        (repl ''oxwm.rule.add({ instance = "gimp", floating = true })'' ''
          -- oxwm.rule.add({ instance = "gimp", floating = true })
          oxwm.rule.add({ instance = "wiremix", floating = true })
          oxwm.rule.add({ instance = "keybinds", floating = true })'')
        (repl ''oxwm.rule.add({ instance = "brave-browser", tag = 2 })'' ''-- oxwm.rule.add({ instance = "brave-browser", tag = 2 })'')
        (repl ''oxwm.rule.add({ class = "firefox", tag = 3 })'' ''-- oxwm.rule.add({ class = "firefox", tag = 3 })'')
        (repl ''oxwm.rule.add({ instance = "slack", tag = 4 })'' ''-- oxwm.rule.add({ instance = "slack", tag = 4 })'')
        (repl ''oxwm.rule.add({ instance = "discord", tag = 5 })'' ''-- oxwm.rule.add({ instance = "discord", tag = 5 })'')
      ];

      # writeText (not toFile): the text references store paths (dmenu).
      finalConfig = pkgs.writeText "oxwm-config.lua" (lib.concatStringsSep "\n" patchedLines);
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
          "oxwm/keybinds.txt".text = keybindsDoc;
        }
        // {

          "oxwm/bat-status.sh" = {
            executable = true;
            text = ''
              #!/bin/sh
              # Prints "Bat: NN%" plus a profile marker when not balanced:
              # gauge = performance, leaf = power-saver. The bar draws each
              # block in one static color, so the marker has to live in the text.
              prof=$(powerprofilesctl get 2>/dev/null) || prof=balanced
              case "$prof" in
                performance) mark="" ;;
                power-saver) mark="" ;;
                *) mark="" ;;
              esac
              cap=""
              status=""
              for d in /sys/class/power_supply/BAT*; do
                [ -r "$d/capacity" ] || continue
                IFS= read -r cap < "$d/capacity"
                IFS= read -r status < "$d/status"
                break
              done
              [ -n "$cap" ] || exit 0
              case "$status" in
                Charging) label="Chg: $cap%" ;;
                Full) label="Full" ;;
                *) label="Bat: $cap%" ;;
              esac
              [ -n "$mark" ] && label="$label $mark"
              printf '%s\n' "$label"
            '';
          };

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
              if [ ! -f "$state" ]; then
                printf '%s %s\n' "$total" "$idle" > "$state"
                exit 0
              fi
              read -r pt pi < "$state"
              dt=$((total - pt))
              di=$((idle - pi))
              if [ "$dt" -gt 0 ]; then printf 'Cpu: %d%%\n' "$(( 100 * (dt - di) / dt ))"; fi
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

      # Session bootstrap for startx: getty autologin on tty1 runs the login
      # shell, which execs startx, which runs this. HM-managed so layout and
      # WM stay in sync with the rest of the config.
      home.file.".xinitrc" = {
        executable = true;
        text = ''
          #!/bin/sh
          ${pkgs.setxkbmap}/bin/setxkbmap ${constants.layout} 2>/dev/null || true
          # args are delay-ms then rate-hz, not the order users say them in.
          ${pkgs.xset}/bin/xset r rate 200 35 2>/dev/null || true
          # startx provides no session bus or user-manager env of its own;
          # without these, D-Bus-activated apps and user services start blind.
          systemctl --user import-environment DISPLAY XAUTHORITY 2>/dev/null || true
          if command -v dbus-update-activation-environment >/dev/null 2>&1; then
            dbus-update-activation-environment DISPLAY XAUTHORITY 2>/dev/null || true
          fi
          exec oxwm
        '';
      };

    };
}
