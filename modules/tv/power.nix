# TV appliance power behavior: always-on, never suspend, no useless daemons.
_: {
  flake.nixosModules.tv-power =
    { lib, ... }:
    {
      # Plasma mkDefaults power-profiles-daemon on, and it would reset the
      # governor to its "balanced" (schedutil) profile on every boot.
      services.power-profiles-daemon.enable = false;
      powerManagement.cpuFreqGovernor = "performance";

      # Daemons this box cannot use: no battery (upower), no wireless hardware
      # (wpa_supplicant), no modem (ModemManager), no firmware fwupd manages.
      # Each costs RAM and CPU on a 2-core machine and widens the network
      # attack surface for nothing. The Plasma module mkDefaults the first two
      # back on, hence mkForce. ModemManager has no NixOS option of its own --
      # it arrives with NetworkManager -- so it is masked as a unit.
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

      # memoryPercent is a CEILING, not a reservation: zram only grows into RAM
      # as pages are stored. Measured idle here: 20 KB used against the 4.1 GB
      # ceiling, 6.2 Gi MemAvailable, zero swap I/O -- so 50% costs nothing
      # while unused, and hp's 30% would buy nothing either. The 8.8 GB swap
      # partition in hardware-configuration-tv.nix is likewise untouched and
      # not for hibernation (every sleep mode is off above). Do not "fix"
      # either number without measuring first.
      zramSwap = {
        enable = true;
        memoryPercent = 50;
      };
    };
}
