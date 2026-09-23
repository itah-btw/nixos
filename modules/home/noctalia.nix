# Noctalia shell user config. NON-theming settings only — theme, wallpaper,
# backdrop, templates and customPalettes stay runtime-managed so
# wallpaper-derived palettes + rotation keep working (see skill rule 3).
{ ... }:
{
  flake.homeManagerModules.noctalia = {
    programs.noctalia = {
      enable = true;
      # Umbriel autostarts `noctalia` (umbriel.nix), not systemd.
      systemd.enable = false;
      customPalettes = { };

      settings = {
        storage = {
          key_source = "secret-service";
        };
        shell = {
          font_family = "Inter";
          corner_radius_scale = 1.0;
          clipboard_enabled = true;
          clipboard_keep_from_closed_apps = true;
          clipboard_history_max_entries = 100;
        };
        audio = {
          enable_sounds = false;
        };
        notification = {
          enable_daemon = true;
        };
        bar.main = {
          position = "top";
          start = [
            "launcher"
            "wallpaper"
            "workspaces"
          ];
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
      };
    };
  };
}
