# Bootloader (systemd-boot) + latest kernel.
{
  flake.nixosModules.boot = { pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.loader.systemd-boot.enable = true;
    # Boot entries kept in systemd-boot, matching `nclean --keep 5`
    # (aliases.nix): the two were separate numbers once and drifted, which is
    # how the boot menu ended up offering more entries than there were
    # generations to roll back to.
    boot.loader.systemd-boot.configurationLimit = 5;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
