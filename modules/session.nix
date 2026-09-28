# hp desktop session. User-side settings are in umbriel.nix and noctalia.nix.
{
  flake.nixosModules.session =
    {
      constants,
      pkgs,
      ...
    }:
    {
      programs.umbriel.enable = true;

      # Noctalia is autostarted by Umbriel, not systemd.
      programs.noctalia = {
        enable = true;
        recommendedServices.enable = true;
        systemd.enable = false;
      };

      # The greeter project module brings greetd, polkit and accountsd.
      services.displayManager.noctalia-greeter = {
        enable = true;
        passwordless-sync-users = [ constants.username ];
        # System-installed: the greeter runs as its own user.
        cursorTheme.package = pkgs.bibata-cursors;
        settings = {
          cursor = {
            theme = "Bibata-Modern-Ice";
            size = 24;
          };
          # The same scalar umbriel.nix hands the compositor.
          keyboard.layout = constants.layout;
        };
      };

      # All from programs.noctalia.recommendedServices above.
      services.fwupd.enable = true;
      # rtkit is the one thing recommendedServices does not bring.
      security.rtkit.enable = true;
      services.printing.enable = true;

      # File-chooser fallback; Umbriel's module already has the portal.
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

      # System-installed so the greeter can see them.
      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-color-emoji
        liberation_ttf
        inter
      ];
      fonts.fontconfig.defaultFonts = {
        sansSerif = [ "Inter" ];
        monospace = [ "JetBrainsMono Nerd Font" ];
      };

      services.speechd.enable = false;
    };
}
