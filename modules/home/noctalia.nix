# Noctalia shell user config. Non-theming settings only -- theme, wallpaper,
# backdrop, templates and customPalettes stay runtime-managed so
# wallpaper-derived palettes + rotation keep working (see skill rule 3).
# Keys equal to Noctalia's own defaults are deliberately absent; what is left
# here is either a deviation from the default or the reason for it.
_: {
  flake.homeManagerModules.noctalia = {
    programs.noctalia = {
      enable = true;
      # Umbriel autostarts `noctalia` (umbriel.nix), not systemd.
      systemd.enable = false;
      # Tripwire for the theming rule above, not a value: the
      # <host>-noctalia-theming guard fails if this ever becomes non-empty.
      customPalettes = { };

      settings = {
        shell = {
          font_family = "Inter";
          # Translucent Settings window (Umbriel blurs what is behind it).
          settings_window_translucent = true;
          # "glass" = 0.55 panel background + translucent cards, so panels are
          # alpha-transparent and Umbriel's layer rule blurs what is behind.
          panel.transparency_mode = "glass";
        };
        brightness = {
          # Floor clamp: the darkest usable step is 1%. Needed because the
          # 1%-step ladder in umbriel.nix (brightness-step) bottoms out at 0%,
          # and 0% on this panel is unusably black.
          minimum_brightness = 0.01;
        };
        bar.main = {
          # Translucent bar so Umbriel blurs the desktop behind it.
          background_opacity = 0.75;
          # Default end row minus the clipboard and brightness widgets; both
          # have keybinds (Mod+V, XF86MonBrightness*) that toggle them instead.
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
