# Bootloader (systemd-boot) + latest kernel.
{
  flake.nixosModules.boot = { pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.loader.systemd-boot.enable = true;
    # Matches the 14d GC window in nix.nix.
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
