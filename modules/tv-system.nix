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

      # Optional apps a 10-foot appliance never opens. Kept anyway: the required
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

      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
      };

      services.orca.enable = lib.mkForce false;
      services.speechd.enable = lib.mkForce false;

      services.power-profiles-daemon.enable = false;
      powerManagement.cpuFreqGovernor = "performance";

      services.upower.enable = lib.mkForce false;
      services.fwupd.enable = lib.mkForce false;
      networking.wireless.enable = lib.mkForce false;
      systemd.services.ModemManager.enable = false;

      systemd.sleep.settings.Sleep = {
        AllowHibernation = "no";
        AllowHybridSleep = "no";
        AllowSuspend = "no";
        AllowSuspendThenHibernate = "no";
      };

      zramSwap = {
        enable = true;
        memoryPercent = 50;
      };
    };
}
