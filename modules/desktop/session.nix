# Desktop session: Umbriel compositor + Noctalia shell + Noctalia Greeter.
# User-side settings live in ../home/{umbriel,noctalia}.nix.
{ ... }:
{
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

    hardware.bluetooth.enable = true;
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    services.fwupd.enable = true;
    security.polkit.enable = true;
    services.accounts-daemon.enable = true;

    # umbriel module configures xdg-desktop-portal-umbriel as the backend;
    # gtk portal stays as fallback for file choosers.
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

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
