# Performance + power for this HP Intel laptop (nvme, Intel NPU).
{ ... }:
{
  flake.nixosModules.performance = {
    services.fstrim.enable = true;
    # Single OOM backstop: systemd-oomd (default on NixOS). earlyoom removed:
    # running both races on the same pressure signal.
    systemd.oomd.enable = true;
    # thermald removed: power-profiles-daemon (desktop/session.nix) owns
    # Intel P-state/platform_profile; running both thrashes frequency.

    # Modest zram (was 50% — too easy to exhaust into OOM) plus a small
    # 4G disk swapfile as a cushion for genuine memory spikes.
    zramSwap = {
      enable = true;
      memoryPercent = 30;
    };
    swapDevices = [
      {
        device = "/swapfile";
        size = 4096;
      }
    ];

    hardware.enableRedistributableFirmware = true;
  };
}
