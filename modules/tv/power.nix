# TV appliance power behavior: always-on, never suspend, no useless daemons.
# Ported verbatim from the box's configuration.nix.
{ ... }:
{
  flake.nixosModules.tv-power =
    { lib, ... }:
    {
      # Plasma mkDefaults power-profiles-daemon on, and it would reset the
      # governor to its "balanced" (schedutil) profile on every boot.
      services.power-profiles-daemon.enable = false;
      powerManagement.cpuFreqGovernor = "performance";

      # Daemons this box cannot possibly use: it has no battery (upower), no
      # wireless hardware (wpa_supplicant), no cellular modem (ModemManager)
      # and no firmware that fwupd manages. Each one costs RAM and CPU on a
      # 2-core machine that is already swapping, and each widens the network
      # attack surface for nothing. ModemManager has no NixOS option of its
      # own -- it arrives with NetworkManager -- so it is masked as a unit.
      #
      # The Plasma module mkDefaults all three of these back on, so each
      # needs mkForce to actually stick.
      services.upower.enable = lib.mkForce false;
      services.fwupd.enable = lib.mkForce false;
      # NetworkManager sets this to true, so it takes a forced override.
      networking.wireless.enable = lib.mkForce false;
      systemd.services.ModemManager.enable = false;

      systemd.sleep.settings.Sleep = {
        AllowHibernation = "no";
        AllowHybridSleep = "no";
        AllowSuspend = "no";
        AllowSuspendThenHibernate = "no";
      };

      # Deliberately 50%, not the 30% in core/performance.nix: 8 GB RAM on a
      # box that is already swapping, plus a real 8.8 GB swap partition from
      # hardware-configuration-tv.nix (so no /swapfile like hp has).
      zramSwap = {
        enable = true;
        memoryPercent = 50;
      };
    };
}
