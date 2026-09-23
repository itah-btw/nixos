# PLACEHOLDER — replace on the TV box with:
#   sudo nixos-generate-config --show-hardware-config > /etc/nixos/hardware-configuration-tv.nix
# hp keeps using hardware-configuration.nix; each host owns its file so the
# shared repo clones cleanly onto both machines. Do NOT build tv from this stub.
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
