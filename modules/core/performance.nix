# Performance + power for this HP Intel laptop (nvme, Intel NPU).
# fstrim, systemd-oomd and redistributable firmware are all NixOS defaults and
# are not restated here.
_: {
  flake.nixosModules.performance = {
    # One OOM backstop only: systemd-oomd (default on). earlyoom removed --
    # running both races on the same pressure signal. thermald removed --
    # power-profiles-daemon (desktop/session.nix) owns Intel P-state and
    # platform_profile, and the two thrash frequency together.

    # Modest zram (was 50% -- too easy to exhaust into OOM) plus a small 4G
    # disk swapfile as a cushion for genuine memory spikes.
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
  };
}
