# Bootloader (systemd-boot) + latest kernel.
{
  flake.nixosModules.boot = { pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.loader.systemd-boot.enable = true;
    # Boot entries kept, matching `nclean --keep 5`; they drifted apart once and
    # the menu offered more entries than there were generations to roll back to.
    boot.loader.systemd-boot.configurationLimit = 5;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
