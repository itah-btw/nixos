# Desktop session: Umbriel compositor + Noctalia shell + Noctalia Greeter.
#
# Cross-cutting note: the matching user-side settings
# (programs.umbriel.settings / programs.noctalia.settings) live in
# ../home/umbriel.nix and ../home/noctalia.nix. Same feature, split by
# configuration class — the file path names the feature, the
# flake.{nixosModules,homeManagerModules} attribute names the class.
{ ... }:
{
  flake.nixosModules.session = { pkgs, ... }: {
    # Compositor (project flake module sets a default package).
    programs.umbriel.enable = true;

    # Shell (system-wide install + recommended integrations).
    # Noctalia itself is autostarted by Umbriel (see home-manager
    # `programs.umbriel.settings.general.autostart`), NOT via systemd,
    # so the systemd service stays off.
    programs.noctalia = {
      enable = true;
      recommendedServices.enable = true;
      systemd.enable = false;
    };

    # Login screen. Project flake module enables greetd, Polkit and
    # AccountsService and wires `noctalia-greeter-session`.
    # Disable any other display manager when this is on.
    services.displayManager.noctalia-greeter = {
      enable = true;
      # Users allowed passwordless appearance sync
      # (Settings -> Security -> Sync Now). Empty list = always prompt.
      # Requires greeter >= 1.5.0 (flake provides it).
      passwordless-sync-users = [ "itah" ];
      # Greeter runs as its own user — home-only cursors are invisible to
      # it, so the theme package is installed system-wide here and the
      # theme name is set explicitly (matches the user session).
      cursorTheme.package = pkgs.bibata-cursors;
      settings = {
        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 24;
        };
        keyboard.layout = "us";
        # session.default = "umbriel"; # uncomment to force default session
      };
    };
    # greetd is enabled + wired by the noctalia-greeter project module
    # above (noctalia-greeter-session); no separate displayManager block.

    # Services Noctalia integrations expect (recommendedServices covers
    # NetworkManager/Bluetooth/UPower/power-profiles, the rest is explicit).
    hardware.bluetooth.enable = true;
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;
    # Firmware updates via LVFS (`fwupdmgr get-devices` / `fwupdmgr update`).
    # Socket-activated, idle otherwise. Keep the charger plugged for BIOS updates.
    services.fwupd.enable = true;
    security.polkit.enable = true;
    services.accounts-daemon.enable = true;

    # Portals: umbriel module configures xdg-desktop-portal-umbriel as the
    # backend; keep gtk portal as fallback for file choosers etc.
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };

    # Fonts used by shell/greeter (system-installed so greeter can see them;
    # home-only fonts are invisible to the greeter account).
    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-color-emoji
      # Office metric-compat (docs don't reflow) + UI fallback.
      liberation_ttf
      inter
    ];

    # Inter is the default UI font. Monospace stays JetBrainsMono (kitty
    # sets it explicitly too, so terminals keep the nerd-font glyphs).
    fonts.fontconfig.defaultFonts = {
      sansSerif = [ "Inter" ];
      monospace = [ "JetBrainsMono Nerd Font" ];
    };

    # No text-to-speech: explicitly off, no speech dispatcher,
    # screen-reader/TTS daemons or engines pulled in by default.
    services.speechd.enable = false;
  };
}
