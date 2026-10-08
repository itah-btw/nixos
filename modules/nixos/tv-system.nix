# Appliance power: always-on, never suspend, no daemons this box cannot use.
{
  flake.nixosModules.tv-system =
    {
      constants,
      lib,
      pkgs,
      ...
    }:
    {
      services.displayManager = {
        defaultSession = "plasma-bigscreen-wayland";
        sessionPackages = [ pkgs.kdePackages.plasma-bigscreen ];
        sddm = {
          enable = true;
          settings.Autologin = {
            User = constants.username;
            Session = "plasma-bigscreen-wayland";
          };
        };
      };

      services.desktopManager.plasma6 = {
        enable = true;
        enableQt5Integration = false;
      };
      xdg.portal.configPackages = [ pkgs.kdePackages.plasma-bigscreen ];

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        kwin-x11
        kate
        khelpcenter
        krdp
        plasma-workspace-wallpapers
        union
      ];

      programs.kdeconnect.enable = true;

      hardware.graphics.extraPackages = [ pkgs.intel-vaapi-driver ];

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      # plasma6.nix and graphical-desktop.nix turn these on with `mkDefault
      # true` whenever the desktop is enabled, so plain `= false` overrides.
      services.orca.enable = false;
      services.speechd.enable = false;
      services.power-profiles-daemon.enable = false;
      services.fwupd.enable = false;

      powerManagement.cpuFreqGovernor = "performance";

      # plasma6 follows powerManagement at normal priority, so only mkForce
      # wins regardless of import order.
      services.upower.enable = lib.mkForce false;
      # NetworkManager pulls in a modem daemon this box cannot use.
      networking.modemmanager.enable = false;

      systemd.sleep.settings.Sleep = {
        AllowHibernation = "no";
        AllowHybridSleep = "no";
        AllowSuspend = "no";
        AllowSuspendThenHibernate = "no";
      };

      # ~100 MB of store a TV never reads.
      documentation.nixos.enable = false;
      documentation.man.enable = false;

      environment.systemPackages = with pkgs; [
        smartmontools
        libva-utils
        mpv
        yt-dlp
        librewolf
      ];
    };
}
