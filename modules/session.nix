# hp desktop session: Umbriel, Noctalia, Noctalia Greeter. User-side settings
# are in umbriel.nix and noctalia.nix.
{
  flake.nixosModules.session =
    {
      config,
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
        # System-installed: the greeter runs as its own user, so home-only
        # cursors are invisible to it.
        cursorTheme.package = pkgs.bibata-cursors;
        settings = {
          cursor = {
            theme = "Bibata-Modern-Ice";
            size = 24;
          };
          keyboard.layout = config.services.xserver.xkb.layout;
        };
      };

      # Bluetooth, UPower, power-profiles-daemon and NetworkManager all come from
      # programs.noctalia.recommendedServices above.
      services.fwupd.enable = true;
      # PipeWire comes from recommendedServices, but rtkit does not.
      security.rtkit.enable = true;
      services.printing.enable = true;

      # Umbriel's module already installs xdg-desktop-portal-umbriel; this is the
      # file-chooser fallback.
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
