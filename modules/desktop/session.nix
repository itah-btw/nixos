# Desktop session: Umbriel compositor + Noctalia shell + Noctalia Greeter.
# User-side settings live in ../home/{umbriel,noctalia}.nix.
_: {
  flake.nixosModules.session = { config, pkgs, ... }: {
    programs.umbriel.enable = true;

    # Noctalia is autostarted by Umbriel, NOT via systemd.
    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd.enable = false;
    };

    # Login screen (project module enables greetd + polkit + accountsd).
    services.displayManager.noctalia-greeter = {
      enable = true;
      # Passwordless appearance sync (Settings -> Security -> Sync Now).
      passwordless-sync-users = [ "itah" ];
      # Greeter runs as its own user: home-only cursors are invisible, so
      # install the theme system-wide here (matches the user session).
      cursorTheme.package = pkgs.bibata-cursors;
      settings = {
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 24;
        };
        # Single source of truth: core/locale.nix.
        keyboard.layout = config.services.xserver.xkb.layout;
      };
    };

    # Bluetooth, UPower, power-profiles-daemon and NetworkManager come from
    # programs.noctalia.recommendedServices above; greetd, polkit and
    # accountsd from the greeter module. Only what they do not cover is here.
    services.fwupd.enable = true;
    # PipeWire is enabled via Noctalia recommendedServices, but realtime
    # scheduling needs rtkit explicitly (verified: rtkit was off).
    security.rtkit.enable = true;
    # HP laptop: CUPS printing (avahi mDNS lives in core/networking.nix).
    services.printing.enable = true;

    # Umbriel's module already enables the portal and installs
    # xdg-desktop-portal-umbriel; the gtk portal is added as the fallback for
    # file choosers.
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

    # System-installed so the greeter can see them (home-only fonts are not).
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

    # No text-to-speech.
    services.speechd.enable = false;
  };
}
