# Noctalia, non-theming settings only. theme/wallpaper/backdrop/templates and
# customPalettes stay runtime-managed, or noctalia-theming-runtime fails.
{
  flake.homeManagerModules.noctalia = { pkgs, ... }: {
    # Phone Connect's gdbus (no device list without it) and its file picker.
    home.packages = with pkgs; [
      glib
      zenity
    ];

    programs.noctalia = {
      enable = true;
      # Umbriel autostarts it (umbriel.nix), not systemd.
      systemd.enable = false;
      # Tripwire for the rule above, not a value.
      customPalettes = { };

      settings = {
        shell = {
          font_family = "Inter";
          # Umbriel blurs these.
          settings_window_translucent = true;
          panel.transparency_mode = "glass";
        };
        brightness = {
          # 0% on this panel is unusably black, and umbriel.nix's fallback can ask.
          minimum_brightness = 0.01;
        };
        bar.main = {
          background_opacity = 0.75;
          # Default end row minus the two that have keybinds: Mod+V, brightness.
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
      };
    };
  };
}
