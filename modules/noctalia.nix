# Noctalia, non-theming settings only. theme, wallpaper, backdrop, templates and
# customPalettes stay runtime-managed so wallpaper-derived palettes and
# rotation keep working; the noctalia-theming-runtime guard fails otherwise.
{
  flake.homeManagerModules.noctalia = {
    programs.noctalia = {
      enable = true;
      # Umbriel autostarts it (umbriel.nix), not systemd.
      systemd.enable = false;
      # Tripwire for the rule above, not a value.
      customPalettes = { };

      settings = {
        shell = {
          font_family = "Inter";
          # Umbriel blurs these, so they must stay translucent.
          settings_window_translucent = true;
          panel.transparency_mode = "glass";
        };
        brightness = {
          # Floor clamp. The 1% step in umbriel.nix never asks for 0, but the
          # brightness-down fallback it uses without a sysfs backlight device
          # can, and 0% on this panel is unusably black.
          minimum_brightness = 0.01;
        };
        bar.main = {
          background_opacity = 0.75;
          # Default end row minus clipboard and brightness, which have keybinds
          # (Mod+V, XF86MonBrightness*) that toggle them instead.
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
