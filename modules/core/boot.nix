# Bootloader (systemd-boot EFI) + latest kernel.
{ ... }:
{
  flake.nixosModules.boot = { pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.loader.systemd-boot.enable = true;
    # Matches 14d GC window (core/nix.nix): older entries point at GC'd paths.
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
