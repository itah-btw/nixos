{ ... }:
{
  flake.modules.nixos.desktop = { lib, pkgs, ... }: {
    fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
    systemd.user.services.noctalia.enableDefaultPath = lib.mkForce true;
    programs.umbriel.enable = true;

    xdg.portal.extraPortals = lib.mkForce [ pkgs.xdg-desktop-portal-umbriel ];

    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      systemd.target = "graphical-session.target";
      recommendedServices.enable = true;
    };

    services.displayManager.noctalia-greeter = {
      enable = true;
      settings = {
        cursor = { theme = "Adwaita"; size = 24; };
        keyboard.layout = "us";
      };
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };

    services.speechd.enable = false;
  };
}
