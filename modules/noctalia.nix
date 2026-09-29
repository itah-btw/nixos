{
  flake.homeManagerModules.noctalia = { constants, pkgs, ... }: {
    home.packages = with pkgs; [
      glib
      zenity
    ];

    programs.noctalia = {
      enable = true;
      systemd.enable = false;
      # Tripwire for the rule above, not a value.
      customPalettes = { };

      settings = {
        shell.font_family = constants.sansFont;
        brightness = {
          minimum_brightness = 0.01;
        };
        bar.main = {
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
