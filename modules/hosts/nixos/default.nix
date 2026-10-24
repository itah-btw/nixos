{ config, lib, inputs, ... }:
let
  nixosModules = config.flake.modules.nixos;
in
{
  configurations.nixos.nixos = {
    module = { config, lib, modulesPath, ... }: {
      imports = with nixosModules; [
        boot
        networking
        locale
        user
        nix
        packages
        desktop
        firefox
        fprintd
        localsend
        ocr
        dev
        secrets
        homeManagerBase
        home
      ] ++ [ (modulesPath + "/installer/scan/not-detected.nix") ];

      boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      boot.initrd.kernelModules = [ ];
      boot.kernelModules = [ "kvm-intel" ];
      boot.extraModulePackages = [ ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/16757e43-8781-43ca-98d8-af261a8861eb";
        fsType = "ext4";
      };

      fileSystems."/boot" = {
        device = "/dev/disk/by-uuid/535B-B8AD";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

      swapDevices = [
        { device = "/dev/disk/by-uuid/5a411d76-555c-4399-9f41-e4f3939dd193"; }
      ];

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      hardware.cpu.intel.npu.enable = true;
      hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

      system.stateVersion = "26.11";
    };
  };
}
