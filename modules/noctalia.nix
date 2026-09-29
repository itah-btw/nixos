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
        # Surfaces are solid on purpose, so panel transparency mode, the settings
        # window and the bar's background opacity are all left at their opaque
        # defaults; umbriel.nix is opaque for the same reason.
        shell.font_family = "Inter";
        brightness = {
          # 0% on this panel is unusably black, and umbriel.nix's fallback can ask.
          minimum_brightness = 0.01;
        };
        bar.main = {
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
