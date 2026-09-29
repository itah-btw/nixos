{
  flake.nixosModules.session =
    {
      constants,
      pkgs,
      ...
    }:
    {
      programs.umbriel.enable = true;

      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
        systemd.enable = false;
      };

      services.displayManager.noctalia-greeter = {
        enable = true;
        passwordless-sync-users = [ constants.username ];
        cursorTheme.package = pkgs.bibata-cursors;
        settings = {
          cursor = {
            theme = constants.cursorTheme;
            size = constants.cursorSize;
          };
          keyboard.layout = constants.layout;
        };
      };

      services.fwupd.enable = true;
      security.rtkit.enable = true;
      services.printing.enable = true;

      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
        liberation_ttf
        inter
      ];
      fonts.fontconfig.defaultFonts = {
        sansSerif = [ constants.sansFont ];
        monospace = [ constants.monoFont ];
      };

      services.speechd.enable = false;
    };
}
