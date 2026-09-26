# Umbriel compositor user config. System side lives in desktop/session.nix.
{ ... }:
{
  flake.homeManagerModules.umbriel =
    { pkgs, ... }:
    {
      # OCR helper: region-select, OCR (eng+ind), copy to clipboard.
      # Deps (grim/slurp/tesseract/wl-clipboard) live in home/apps.nix.
      home.packages = [
        (pkgs.writeShellScriptBin "ocr-copy" ''
          tmp=$(mktemp --suffix .png)
          trap 'rm -f "$tmp"' EXIT
          grim -g "$(slurp)" "$tmp" && tesseract "$tmp" - -l eng+ind 2>/dev/null | wl-copy
        '')
        # Noctalia's brightness step is a fixed 5% (kDefaultBrightnessStep),
        # which wrecks both ends of the range: down goes 5% -> 0% in one press,
        # and with the 1% floor from noctalia.nix, up from 1% lands on 6% and
        # the next press drops straight back to 1%. Snap onto a
        # 10/5/4/3/2/1 ladder instead, read from the panel. Every press is an
        # absolute brightness-set, which still fires the OSD.
        (pkgs.writeShellScriptBin "brightness-step" ''
          pct=""
          for dev in /sys/class/backlight/*; do
            if [ -r "$dev/brightness" ] && [ -r "$dev/max_brightness" ]; then
              pct=$(( 100 * $(cat "$dev/brightness") / $(cat "$dev/max_brightness") ))
              break
            fi
          done
          if [ "$1" = "up" ]; then
            [ -n "$pct" ] || exec noctalia msg brightness-up
            if [ "$pct" -lt 5 ]; then target=$(( pct + 1 )); else target=$(( pct + 5 )); fi
          else
            [ -n "$pct" ] || exec noctalia msg brightness-down
            if [ "$pct" -le 5 ]; then target=$(( pct - 1 )); else target=5; fi
            [ "$target" -lt 1 ] && target=1
          fi
          noctalia msg brightness-set "$target"
        '')
      ];
      programs.umbriel = {
        enable = true;
        settings = {
          # Noctalia->Umbriel template supplies [colors] via this include;
          # apply.sh cannot edit the read-only store symlink itself.
          include.optional.files = [ "noctalia.toml" ];
          general = {
            # Primary way Noctalia starts (NOT systemd; see noctalia.nix).
            # kdeconnect-indicator starts the KDE Connect daemon (system pkg).
            autostart = [
              "noctalia"
              "kdeconnect-indicator"
            ];
            xwayland = true;
            show_cheatsheet = false;
          };
          layout = {
            mode = "scrolling";
            gap = 8;
            scrolling = {
              center_underfull_strip = false;
              default_extent_fraction = 0.5;
            };
          };
          appearance = {
            # Let translucent fullscreen windows (e.g. kitty) keep their
            # opacity and blur the desktop instead of going opaque.
            opaque_fullscreen = false;
            # Master blur switch; surfaces opt in via window/layer rules.
            blur = {
              enabled = true;
              # One shared wallpaper blur per output (cheap). Layer rules
              # override this with blur_optimized = false so panels blur the
              # windows behind them, not the wallpaper.
              optimized = true;
              passes = 3;
              radius = 12;
              noise = 0.02;
              brightness = 0.95;
              contrast = 0.95;
              saturation = 1.1;
            };
          };
          # Later rules win per field. Blur only shows where a surface is
          # transparent. Kitty's own background_opacity stays 1.0
          # (home/apps.nix), so these are the effective alphas: focused 1.0,
          # unfocused 0.8, focused kitty 0.9.
          window_rule = [
            {
              blur = true;
            }
            {
              match.is_focused = false;
              opacity = 0.8;
            }
            {
              # Noctalia Settings draws its own translucent background, so the
              # 0.8 dim let too much of the bright wallpaper through. Keep it
              # at full alpha whether or not it has focus.
              match.app_id = "^dev[.]noctalia[.]Noctalia$";
              opacity = 1.0;
            }
            {
              match.app_id = "^kitty$";
              match.is_focused = true;
              opacity = 0.9;
            }
          ];
          # Noctalia layer surfaces (bar, panels, dock, toasts, OSD, switcher)
          # stay translucent so the compositor can blur what is behind them.
          # No `noctalia-wallpaper`/`-backdrop`: blurring those would blur
          # the wallpaper itself.
          layer_rule = [
            {
              match.namespace = "^noctalia-(bar-.+|panel|attached-panel|notification|osd|dock|window-switcher)$";
              blur = true;
              blur_popups = true;
              blur_ignore_alpha = 0.5;
              blur_optimized = false;
            }
          ];
          input.keyboard = {
            # Mirrors services.xserver.xkb.layout (core/locale.nix).
            layout = "us";
            repeat_rate = 40;
            repeat_delay = 200;
          };
          input.touchpad = {
            natural_scroll = true;
          };
          input.cursor = {
            theme = "Bibata-Modern-Ice";
            size = 24;
          };
          keybinds = {
            # --- Apps & session ---
            "Mod+Return" = "spawn:kitty";
            "Mod" = "spawn:noctalia msg panel-toggle launcher";
            "Mod+Q" = "window-close";
            "Mod+Shift+Q" = "session-quit";
            "Mod+Escape" = "spawn:noctalia msg panel-toggle session";
            "Mod+Shift+Escape" = {
              action = "shortcuts-inhibit-toggle";
              allow_when_inhibited = true;
              repeat = false;
            };
            "Mod+Slash" = "cheatsheet-toggle";

            # --- App launches ---
            "Mod+E" = "spawn:kitty yazi";
            "Mod+B" = "spawn:firefox";
            "Mod+Shift+F23" = "spawn:kitty opencode";
            "Mod+I" = "spawn:protonvpn-app";
            "Mod+Shift+E" = "spawn:noctalia msg panel-toggle launcher /emo";

            # --- Focus navigation (arrows + HJKL + F1 + wheel) ---
            "Mod+Left" = "window-focus-left";
            "Mod+Down" = "window-focus-down";
            "Mod+Up" = "window-focus-up";
            "Mod+Right" = "window-focus-right";
            "Mod+H" = "window-focus-left";
            "Mod+J" = "window-focus-down";
            "Mod+K" = "window-focus-up";
            "Mod+L" = "window-focus-right";
            "Mod+F1" = "window-focus-next";
            "Mod+Grave" = "window-focus-last";
            "Mod+WheelUp" = "window-focus-left";
            "Mod+WheelDown" = "window-focus-right";

            # --- Move / consume / sizing (scrolling-first) ---
            "Mod+Shift+Left" = "column-move-left";
            "Mod+Shift+Down" = "window-move-down";
            "Mod+Shift+Up" = "window-move-up";
            "Mod+Shift+Right" = "column-move-right";
            "Mod+Shift+H" = "column-move-left";
            "Mod+Shift+J" = "window-move-down";
            "Mod+Shift+K" = "window-move-up";
            "Mod+Shift+L" = "column-move-right";
            "Mod+Bracketleft" = "window-consume-or-expel-left";
            "Mod+Bracketright" = "window-consume-or-expel-right";
            "Mod+R" = "window-cycle-primary-extent";
            "Mod+Shift+R" = "window-cycle-primary-extent-back";
            "Mod+Alt+R" = "window-cycle-secondary-extent";
            "Mod+Alt+Shift+R" = "window-cycle-secondary-extent-back";
            "Mod+Minus" = "window-modify-primary-extent:-0.1";
            "Mod+Equal" = "window-modify-primary-extent:0.1";
            "Mod+Shift+Minus" = "window-modify-secondary-extent:-0.1";
            "Mod+Shift+Equal" = "window-modify-secondary-extent:0.1";
            "Mod+Ctrl+T" = "workspace-set-layout:toggle";

            # --- Window state ---
            "Mod+T" = "window-toggle-floating";
            "Mod+Shift+T" = "window-focus-switch-floating";
            "Mod+P" = "window-toggle-pinned";
            "Mod+M" = "window-toggle-maximize-to-edges";
            "Mod+F" = "window-toggle-maximize";
            "Mod+Shift+F" = "window-toggle-fullscreen";

            # --- Overview ---
            "Mod+O" = {
              action = "overview-toggle";
              repeat = false;
            };

            # --- Workspaces 1-9 (+ move) & prev/next ---
            "Mod+1" = "workspace-switch:1";
            "Mod+2" = "workspace-switch:2";
            "Mod+3" = "workspace-switch:3";
            "Mod+4" = "workspace-switch:4";
            "Mod+5" = "workspace-switch:5";
            "Mod+6" = "workspace-switch:6";
            "Mod+7" = "workspace-switch:7";
            "Mod+8" = "workspace-switch:8";
            "Mod+9" = "workspace-switch:9";
            "Mod+Shift+1" = "window-move-to-workspace:1";
            "Mod+Shift+2" = "window-move-to-workspace:2";
            "Mod+Shift+3" = "window-move-to-workspace:3";
            "Mod+Shift+4" = "window-move-to-workspace:4";
            "Mod+Shift+5" = "window-move-to-workspace:5";
            "Mod+Shift+6" = "window-move-to-workspace:6";
            "Mod+Shift+7" = "window-move-to-workspace:7";
            "Mod+Shift+8" = "window-move-to-workspace:8";
            "Mod+Shift+9" = "window-move-to-workspace:9";
            "Mod+Page_Up" = "workspace-previous";
            "Mod+Page_Down" = "workspace-next";

            # --- Power ---
            # No hardware key for this on this laptop: KEY_DISPLAY_OFF (253)
            # and KEY_SCREENSAVER (160) are not advertised by any of its input
            # devices, so those keysyms would never fire here. Any later
            # keypress or pointer motion wakes the panel again
            # (Server::wakeDpmsOutputs), and the wake runs *before* the
            # action, so this key cannot double as a toggle.
            "Mod+Shift+D" = "dpms-off";

            # --- Outputs (multi-monitor) ---
            "Mod+Ctrl+Left" = "output-focus-left";
            "Mod+Ctrl+Down" = "output-focus-down";
            "Mod+Ctrl+Up" = "output-focus-up";
            "Mod+Ctrl+Right" = "output-focus-right";
            "Mod+Ctrl+H" = "output-focus-left";
            "Mod+Ctrl+J" = "output-focus-down";
            "Mod+Ctrl+K" = "output-focus-up";
            "Mod+Ctrl+L" = "output-focus-right";
            "Mod+Ctrl+Tab" = "output-focus-next";
            "Mod+Ctrl+Shift+Left" = "window-move-to-output-left";
            "Mod+Ctrl+Shift+Down" = "window-move-to-output-down";
            "Mod+Ctrl+Shift+Up" = "window-move-to-output-up";
            "Mod+Ctrl+Shift+Right" = "window-move-to-output-right";
            "Mod+Ctrl+Shift+H" = "window-move-to-output-left";
            "Mod+Ctrl+Shift+J" = "window-move-to-output-down";
            "Mod+Ctrl+Shift+K" = "window-move-to-output-up";
            "Mod+Ctrl+Shift+L" = "window-move-to-output-right";
            "Mod+Ctrl+Shift+Tab" = "window-move-to-output-next";
            "Mod+Alt+Left" = "workspace-swap-active-output-left";
            "Mod+Alt+Down" = "workspace-swap-active-output-down";
            "Mod+Alt+Up" = "workspace-swap-active-output-up";
            "Mod+Alt+Right" = "workspace-swap-active-output-right";
            "Mod+Alt+H" = "workspace-swap-active-output-left";
            "Mod+Alt+J" = "workspace-swap-active-output-down";
            "Mod+Alt+K" = "workspace-swap-active-output-up";

            # --- Scratchpad ---
            "Mod+Space" = "scratchpad-toggle";
            "Mod+Shift+Space" = "window-move-to-scratchpad";
            "Mod+Ctrl+Space" = "window-restore-from-scratchpad";
            "Mod+Tab" = "scratchpad-focus-next";

            # --- Noctalia shell (IPC; screenshots on Print) ---
            "Mod+S" = "spawn:noctalia msg panel-toggle control-center";
            "Mod+Comma" = "spawn:noctalia msg settings-toggle";
            "Mod+V" = "spawn:noctalia msg panel-toggle clipboard";
            "Mod+W" = "spawn:noctalia msg panel-toggle wallpaper";
            "Mod+Ctrl+W" = "spawn:noctalia msg wallpaper-next";
            "Mod+Ctrl+Shift+W" = "spawn:noctalia msg wallpaper-previous";
            "Mod+Shift+W" = "spawn:noctalia msg wallpaper-random";
            "Mod+X" = "spawn:noctalia msg bar-toggle";
            "Alt+Tab" = {
              action = "spawn:noctalia msg window-switcher";
              repeat = false;
            };
            "Mod+Alt+L" = "spawn:noctalia msg session lock";
            "Mod+N" = "spawn:noctalia msg notification-dnd-toggle";
            "Mod+C" = "spawn:noctalia msg caffeine-toggle";
            "Print" = "spawn:noctalia msg screenshot-region";
            "Shift+Print" = "spawn:noctalia msg screenshot-fullscreen";
            "Mod+Shift+A" = "spawn:noctalia msg screenshot-annotate";
            "Mod+Ctrl+A" = "spawn:noctalia msg annotate";
            "Mod+Shift+O" = "spawn:ocr-copy";

            # --- Media / volume / brightness (via Noctalia so OSD shows) ---
            "XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up";
            "XF86AudioLowerVolume" = "spawn:noctalia msg volume-down";
            "XF86AudioMute" = "spawn:noctalia msg volume-mute";
            "XF86AudioMicMute" = "spawn:noctalia msg mic-mute";
            "XF86AudioPlay" = "spawn:noctalia msg media toggle";
            "XF86AudioNext" = "spawn:noctalia msg media next";
            "XF86AudioPrev" = "spawn:noctalia msg media previous";
            "XF86MonBrightnessUp" = {
              action = "spawn:brightness-step up";
              allow_when_locked = true;
            };
            "XF86MonBrightnessDown" = {
              action = "spawn:brightness-step down";
              allow_when_locked = true;
            };
          };
          # [colors] intentionally left to defaults: the Noctalia->Umbriel
          # template supplies them at runtime.
        };
      };
    };
}
