# Memory and swap for hp. systemd-oomd is the one OOM backstop and
# power-profiles-daemon (session.nix) owns the P-state, so earlyoom and
# thermald are deliberately absent.
{
  flake.nixosModules.performance = {
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
