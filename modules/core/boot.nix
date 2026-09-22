# Bootloader (systemd-boot EFI).
{ ... }:
{
  flake.nixosModules.boot = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = 20;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
