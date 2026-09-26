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
          # Translucent Settings window (Umbriel blurs what is behind it).
          settings_window_translucent = true;
          # "glass" = 0.55 panel background + translucent cards, so panels are
          # alpha-transparent and Umbriel's layer rule blurs what is behind.
          panel.transparency_mode = "glass";
          clipboard_enabled = true;
          clipboard_keep_from_closed_apps = true;
          clipboard_history_max_entries = 100;
        };
        brightness = {
          # Floor clamp: the darkest usable step is 1%. Needed because the
          # 1%-step ladder from umbriel.nix (brightness-step-down) bottoms
          # out at 0%, and 0% on this panel is unusably black.
          minimum_brightness = 0.01;
        };
        audio = {
          enable_sounds = false;
        };
        notification = {
          enable_daemon = true;
        };
        bar.main = {
          position = "top";
          # Translucent bar so Umbriel blurs the desktop behind it.
          background_opacity = 0.75;
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
