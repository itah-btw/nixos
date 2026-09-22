# Performance + power for this HP Intel laptop (nvme, Intel NPU).
{ ... }:
{
  flake.nixosModules.performance = {
    services.fstrim.enable = true;
    services.thermald.enable = true;
    # earlyoom kills the biggest process before the kernel OOM-er does;
    # matters here because the only real backstop is zram (no big disk swap).
    services.earlyoom.enable = true;

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
