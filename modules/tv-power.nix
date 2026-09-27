# Appliance power: always-on, never suspend, no daemons this box cannot use.
# Plasma mkDefaults the first two back on, hence mkForce.
{
  flake.nixosModules.tv-power = { lib, ... }: {
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

    # memoryPercent is a ceiling, not a reservation: zram only grows into RAM as
    # pages are stored, so 50% costs nothing while idle. The 8.8 GB swap
    # partition in hardware-configuration-tv.nix is likewise untouched and not
    # for hibernation. Measure before "fixing" either number.
    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };
  };
}
