# Performance + power for this HP Intel laptop (nvme, Intel NPU).
#
# - fstrim: weekly SSD discard (nvme longevity + sustained write speed).
# - zram: compressed RAM swap (softens RAM pressure; no disk partition).
# - thermald: Intel thermal daemon (laptop fan/thermal headroom).
# - Redistributable firmware: actually enables the microcode/firmware blob
#   path hardware-configuration.nix reads via
#   `hardware.enableRedistributableFirmware` (plus fwupd updates in session.nix).
{ ... }:
{
  flake.nixosModules.performance = {
    services.fstrim.enable = true;

    zramSwap = {
      enable = true;
      memoryPercent = 50;
    };

    services.thermald.enable = true;

    hardware.enableRedistributableFirmware = true;
  };
}
