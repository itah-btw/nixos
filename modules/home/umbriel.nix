# Umbriel compositor user config (dotfile: ~/.config/umbriel/config.toml).
# System side (package, sessions) lives in ../desktop/session.nix.
{ ... }:
{
  flake.homeManagerModules.umbriel = {
    programs.umbriel = {
      enable = true;
      settings = {
        # Lets the Noctalia->Umbriel template supply [colors] at runtime.
        # noctalia.toml is written by Noctalia (Settings -> Templates) and
        # lives next to this file; HM leaves it alone. Without this include
        # the template output exists but is never loaded (apply.sh cannot
        # edit this read-only store symlink itself).
        include.optional.files = [ "noctalia.toml" ];
        # Glass/visual effects. Master switch explicit (default on), surfaces
        # still opt in via the window_rule/layer_rule lists below.
        appearance.blur = {
          enabled = true;
          optimized = true;
          radius = 5;
          passes = 3;
          noise = 0.02;
          brightness = 0.9;
          contrast = 0.9;
          saturation = 1.1;
        };
        general = {
          # Primary way Noctalia starts (NOT systemd; see noctalia.nix).
          autostart = [ "noctalia" ];
          xwayland = true;
          show_cheatsheet = true;
        };
        layout = {
          mode = "scrolling";
          gap = 8;
          scrolling = {
            center_underfull_strip = false;
            default_extent_fraction = 0.5;
          };
        };
        input.keyboard = {
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
          # Quit moved off Mod+Escape so Escape can open the session menu
          # (Noctalia docs pattern); confirm dialog stays on.
          "Mod+Shift+Q" = "session-quit";
          "Mod+Escape" = "spawn:noctalia msg panel-toggle session";
          "Mod+Shift+Escape" = {
            action = "shortcuts-inhibit-toggle";
            allow_when_inhibited = true;
            repeat = false;
          };
          "Mod+Slash" = "cheatsheet-toggle";

          # --- App launches ---
          "Mod+Y" = "spawn:kitty yazi";
          "Mod+E" = "spawn:kitty yazi";
          "Mod+B" = "spawn:firefox";
          "Mod+Shift+F23" = "spawn:kitty opencode";
          "Mod+I" = "spawn:protonvpn-app";
          # Emoji picker via the Noctalia launcher (upstream docs pattern).
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

          # --- Outputs (multi-monitor) ---
          # Directional focus/move plus wrapping -next forms, so one bind
          # each reaches the other screen of a two-monitor setup.
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
          # No Mod+Alt+L here: that chord is session lock (see above).
          "Mod+Alt+H" = "workspace-swap-active-output-left";
          "Mod+Alt+J" = "workspace-swap-active-output-down";
          "Mod+Alt+K" = "workspace-swap-active-output-up";

          # --- Scratchpad (implicit default) ---
          "Mod+Space" = "scratchpad-toggle";
          "Mod+Shift+Space" = "window-move-to-scratchpad";
          "Mod+Ctrl+Space" = "window-restore-from-scratchpad";
          "Mod+Tab" = "scratchpad-focus-next";

          # --- Noctalia shell (IPC; Mod+P stays pin, screenshots on Print) ---
          "Mod+S" = "spawn:noctalia msg panel-toggle control-center";
          "Mod+Comma" = "spawn:noctalia msg settings-toggle";
          "Mod+V" = "spawn:noctalia msg panel-toggle clipboard";
          "Mod+W" = "spawn:noctalia msg panel-toggle wallpaper";
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
          # OCR region: grim+slurp screenshot -> tesseract -> clipboard.
          # On cancel (Esc in slurp) grim fails so tesseract never runs and
          # the clipboard is left untouched. wl-copy is in the home profile.
          "Mod+Shift+O" =
            "spawn:tmp=$(mktemp --suffix .png); grim -g \"$(slurp)\" \"$tmp\" && tesseract \"$tmp\" - -l eng+ind 2>/dev/null | wl-copy; rm -f \"$tmp\"";

          # --- Media / volume / brightness (via Noctalia so OSD shows) ---
          "XF86AudioRaiseVolume" = "spawn:noctalia msg volume-up";
          "XF86AudioLowerVolume" = "spawn:noctalia msg volume-down";
          "XF86AudioMute" = "spawn:noctalia msg volume-mute";
          "XF86AudioMicMute" = "spawn:noctalia msg mic-mute";
          "XF86AudioPlay" = "spawn:noctalia msg media toggle";
          "XF86AudioNext" = "spawn:noctalia msg media next";
          "XF86AudioPrev" = "spawn:noctalia msg media previous";
          "XF86MonBrightnessUp" = {
            action = "spawn:noctalia msg brightness-up";
            allow_when_locked = true;
          };
          "XF86MonBrightnessDown" = {
            action = "spawn:noctalia msg brightness-down";
            allow_when_locked = true;
          };
        };
        # Glass effects, compositor side:
        # - Blur every window (frosted terminals/dialogs). Keep this
        #   selectorless rule first so later matching rules can override.
        # - Blur Noctalia's own layer surfaces (bar, launcher, dock,
        #   notifications, OSD, panels) behind their translucent backgrounds.
        window_rule = [
          {
            blur = true;
            blur_optimized = false;
          }
        ];
        layer_rule = [
          {
            match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$";
            blur = true;
            blur_ignore_alpha = 0.5;
            blur_popups = true;
            blur_optimized = false;
          }
        ];
        # NOTE: [colors] intentionally left to defaults so the official
        # Noctalia->Umbriel template can supply them at runtime.
        # Enable it in Noctalia Settings -> Templates (Umbriel template).
      };
    };
  };
}
