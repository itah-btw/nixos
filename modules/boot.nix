{
  flake.nixosModules.boot = { constants, pkgs, ... }: {
    boot.kernelPackages = pkgs.linuxPackages_latest;
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.configurationLimit = constants.generationKeep;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
