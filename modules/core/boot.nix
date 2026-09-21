# Bootloader + kernel.
{ ... }:
{
  flake.nixosModules.boot = { pkgs, ... }: {
    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    # Keep only the latest 20 generations in the boot menu.
    boot.loader.systemd-boot.configurationLimit = 20;
    boot.loader.efi.canTouchEfiVariables = true;

    # Use latest kernel.
    boot.kernelPackages = pkgs.linuxPackages_latest;
  };
}
