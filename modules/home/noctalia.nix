# Noctalia shell user config (dotfile: ~/.config/noctalia/config.toml).
#
# Rule: NON-theming settings only. Theming keys are deliberately absent:
#   theme.*, wallpaper.*, backdrop, theme.templates, customPalettes
#
# Why: Noctalia merges ~/.config/noctalia/*.toml (declarative base) with
# ~/.local/state/noctalia/settings.toml (GUI/runtime overrides, wins).
# Wallpaper/palette changes are written to settings.toml at runtime. If we
# also pinned [theme]/[wallpaper]/templates declaratively, the base layer
# would fight the runtime layer and rotation/palette sync would appear
# "stuck". Set those once in the Noctalia Settings GUI (or via
# `noctalia msg`); they persist in settings.toml and are NOT clobbered by
# rebuilds.
{ ... }:
{
  flake.homeManagerModules.noctalia = {
    programs.noctalia = {
      enable = true;
      # No systemd user service: Umbriel autostarts `noctalia` (see
      # umbriel.nix). Set to true only if you stop using Umbriel autostart
      # and want graphical-session.target to launch it instead.
      systemd.enable = false;

      # Leave empty so ~/.config/noctalia/palettes/ stays unmanaged.
      customPalettes = { };

      settings = {
        # Encrypted-storage master key for clipboard history (+ calendar
        # event cache). Default secret-service needs the GNOME Keyring
        # provider (see ../desktop/keyring.nix); without it history stays
        # session-only and does not survive reboot. Explicit here so the
        # backend choice is visible; no key_file in this mode.
        storage = {
          key_source = "secret-service";
        };
        shell = {
          font_family = "JetBrainsMono Nerd Font";
          corner_radius_scale = 1.0;
          # Glass shell: translucent settings window. Panels below.
          settings_window_translucent = true;
          # No TTS in Noctalia; audio block only controls UI feedback sounds.
          # Clipboard history: encrypted at rest once the storage key above
          # is available; retention off = session-only by design.
          clipboard_enabled = true;
          clipboard_keep_from_closed_apps = true;
          clipboard_history_max_entries = 100;
        };
        # Glass shell: floating panels/cards use soft translucency (blurred
        # by the Umbriel layer rule in umbriel.nix). Not a theming key.
        shell.panel = {
          transparency_mode = "soft";
          shadow = true;
        };
        audio = {
          enable_sounds = false;
        };
        notification = {
          enable_daemon = true;
          # Glass notifications: translucent so the composite blurs the wallpaper.
          background_opacity = 0.85;
        };
        # Glass OSD popups (volume/brightness/etc.).
        osd.background_opacity = 0.85;
        # Bar/dock/launcher/control-center etc. are safe here (not theming).
        bar.main = {
          position = "top";
          # Glass bar: lower opacity so the blur layer rule shows the wallpaper.
          background_opacity = 0.85;
          start = [ "launcher" "wallpaper" "workspaces" ];
          center = [ "clock" ];
          end = [
            "media"
            "tray"
            "notifications"
            "network"
            "bluetooth"
            "volume"
            "battery"
            "control-center"
            "session"
          ];
        };
        dock = {
          enabled = false;
        };
        # Location is needed for theme `auto` mode + night-light schedule,
        # but is not itself a theme value, so it lives here.
        location = {
          auto_locate = false;
        };
        nightlight = {
          enabled = false;
        };
        idle.behavior.lock = {
          timeout = 600;
          action = "lock";
          enabled = false;
        };

        # === EXPLICITLY NOT MANAGED (runtime via GUI) ===
        # [theme]                -> Settings -> Theme (use source="wallpaper",
        #                             wallpaper_scheme="m3-content" for
        #                             wallpaper-derived palette)
        # [wallpaper] + [wallpaper.automation] -> Settings -> Wallpaper
        #   (set directory=~/Pictures/Wallpapers, enabled=true,
        #    interval_seconds=1800, order="random")
        # [backdrop]             -> Settings -> Backdrop
        # [theme.templates]      -> Settings -> Templates (enable Umbriel +
        #                             GTK/Qt templates so apps follow palette)
        # palettes/*.json        -> Settings -> custom palettes
      };
    };
  };
}
